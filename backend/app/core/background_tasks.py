"""
Background task manager for long-running operations
"""
import threading
import time
from datetime import datetime, timedelta
from typing import Optional, Callable, Dict, Any
from enum import Enum
import signal
import sys

class TaskStatus(str, Enum):
    PENDING = "pending"
    RUNNING = "running"
    COMPLETED = "completed"
    FAILED = "failed"
    ABORTED = "aborted"

class BackgroundTask:
    """Represents a background task"""
    
    def __init__(
        self,
        task_id: str,
        task_type: str,
        task_func: Callable,
        task_args: tuple = (),
        task_kwargs: dict = None
    ):
        self.task_id = task_id
        self.task_type = task_type
        self.task_func = task_func
        self.task_args = task_args
        self.task_kwargs = task_kwargs or {}
        
        self.status = TaskStatus.PENDING
        self.started_at: Optional[datetime] = None
        self.completed_at: Optional[datetime] = None
        self.last_heartbeat: Optional[datetime] = None
        self.error: Optional[str] = None
        self.result: Optional[Any] = None
        self.progress: int = 0  # 0-100
        
        self.thread: Optional[threading.Thread] = None
        self.should_abort = False
    
    def update_heartbeat(self):
        """Update task heartbeat"""
        self.last_heartbeat = datetime.utcnow()
    
    def update_progress(self, progress: int):
        """Update task progress (0-100)"""
        self.progress = max(0, min(100, progress))
        self.update_heartbeat()
    
    def is_alive(self, timeout_seconds: int = 60) -> bool:
        """Check if task is still alive based on heartbeat"""
        if not self.last_heartbeat:
            return False
        
        timeout = timedelta(seconds=timeout_seconds)
        return datetime.utcnow() - self.last_heartbeat < timeout


class BackgroundTaskManager:
    """
    Manages background tasks with:
    - Thread-based execution
    - Heartbeat monitoring
    - Graceful shutdown
    - Safe abort
    """
    
    def __init__(self):
        self.tasks: Dict[str, BackgroundTask] = {}
        self.lock = threading.Lock()
        self.shutdown_event = threading.Event()
        self.monitor_thread: Optional[threading.Thread] = None
        
        # Register shutdown handlers
        signal.signal(signal.SIGINT, self._signal_handler)
        signal.signal(signal.SIGTERM, self._signal_handler)
        
        # Start monitor thread
        self._start_monitor()
    
    def _signal_handler(self, signum, frame):
        """Handle shutdown signals"""
        print(f"\nReceived signal {signum}. Initiating graceful shutdown...")
        self.shutdown()
    
    def _start_monitor(self):
        """Start monitoring thread for heartbeats"""
        def monitor():
            while not self.shutdown_event.is_set():
                self._check_heartbeats()
                time.sleep(10)  # Check every 10 seconds
        
        self.monitor_thread = threading.Thread(target=monitor, daemon=True)
        self.monitor_thread.start()
    
    def _check_heartbeats(self):
        """Check all running tasks for heartbeat timeout"""
        with self.lock:
            for task_id, task in list(self.tasks.items()):
                if task.status == TaskStatus.RUNNING:
                    if not task.is_alive(timeout_seconds=120):  # 2 minute timeout
                        print(f"Task {task_id} heartbeat timeout - marking as failed")
                        task.status = TaskStatus.FAILED
                        task.error = "Task heartbeat timeout"
                        task.completed_at = datetime.utcnow()
    
    def submit_task(
        self,
        task_id: str,
        task_type: str,
        task_func: Callable,
        task_args: tuple = (),
        task_kwargs: dict = None
    ) -> BackgroundTask:
        """
        Submit a new background task
        
        Returns: BackgroundTask
        Raises: ValueError if task with same ID already running
        """
        with self.lock:
            # Check for existing running task
            if task_id in self.tasks:
                existing = self.tasks[task_id]
                if existing.status == TaskStatus.RUNNING:
                    raise ValueError(f"Task {task_id} is already running")
            
            # Create task
            task = BackgroundTask(
                task_id=task_id,
                task_type=task_type,
                task_func=task_func,
                task_args=task_args,
                task_kwargs=task_kwargs
            )
            
            self.tasks[task_id] = task
            
            # Start task in background thread
            task.thread = threading.Thread(
                target=self._run_task,
                args=(task,),
                daemon=False  # Not daemon so we can wait on shutdown
            )
            task.thread.start()
            
            return task
    
    def _run_task(self, task: BackgroundTask):
        """Run task in background thread"""
        try:
            task.status = TaskStatus.RUNNING
            task.started_at = datetime.utcnow()
            task.update_heartbeat()
            
            print(f"Starting background task: {task.task_id}")
            
            # Execute task
            result = task.task_func(
                *task.task_args,
                **task.task_kwargs,
                _task=task  # Pass task object for progress updates
            )
            
            # Check if aborted
            if task.should_abort:
                task.status = TaskStatus.ABORTED
                task.error = "Task aborted"
                print(f"Task {task.task_id} aborted")
            else:
                task.status = TaskStatus.COMPLETED
                task.result = result
                print(f"Task {task.task_id} completed successfully")
            
        except Exception as e:
            task.status = TaskStatus.FAILED
            task.error = str(e)
            print(f"Task {task.task_id} failed: {e}")
        
        finally:
            task.completed_at = datetime.utcnow()
            task.update_heartbeat()
    
    def get_task(self, task_id: str) -> Optional[BackgroundTask]:
        """Get task by ID"""
        with self.lock:
            return self.tasks.get(task_id)
    
    def abort_task(self, task_id: str) -> bool:
        """Request task abort"""
        with self.lock:
            task = self.tasks.get(task_id)
            if task and task.status == TaskStatus.RUNNING:
                task.should_abort = True
                return True
            return False
    
    def wait_for_task(self, task_id: str, timeout: Optional[float] = None) -> bool:
        """
        Wait for task to complete
        
        Returns: True if completed, False if timeout
        """
        task = self.get_task(task_id)
        if not task or not task.thread:
            return False
        
        task.thread.join(timeout)
        return not task.thread.is_alive()
    
    def get_active_tasks(self) -> list[BackgroundTask]:
        """Get all active (running) tasks"""
        with self.lock:
            return [
                task for task in self.tasks.values()
                if task.status == TaskStatus.RUNNING
            ]
    
    def shutdown(self, timeout: int = 30):
        """
        Gracefully shutdown all tasks
        
        Args:
            timeout: Maximum seconds to wait for tasks
        """
        print("Shutting down background task manager...")
        self.shutdown_event.set()
        
        # Get active tasks
        active_tasks = self.get_active_tasks()
        
        if active_tasks:
            print(f"Waiting for {len(active_tasks)} active task(s) to complete...")
            
            # Request abort for all
            for task in active_tasks:
                task.should_abort = True
            
            # Wait for all to complete (with timeout)
            start_time = time.time()
            for task in active_tasks:
                remaining = timeout - (time.time() - start_time)
                if remaining <= 0:
                    print(f"Timeout waiting for task {task.task_id}")
                    break
                
                if task.thread:
                    task.thread.join(timeout=remaining)
                    if task.thread.is_alive():
                        print(f"Task {task.task_id} did not complete in time")
                    else:
                        print(f"Task {task.task_id} completed")
        
        # Stop monitor thread
        if self.monitor_thread:
            self.monitor_thread.join(timeout=5)
        
        print("Background task manager shutdown complete")
    
    def cleanup_old_tasks(self, max_age_hours: int = 24):
        """Remove completed/failed tasks older than max_age_hours"""
        with self.lock:
            cutoff = datetime.utcnow() - timedelta(hours=max_age_hours)
            
            to_remove = []
            for task_id, task in self.tasks.items():
                if task.completed_at and task.completed_at < cutoff:
                    if task.status in [TaskStatus.COMPLETED, TaskStatus.FAILED, TaskStatus.ABORTED]:
                        to_remove.append(task_id)
            
            for task_id in to_remove:
                del self.tasks[task_id]
            
            if to_remove:
                print(f"Cleaned up {len(to_remove)} old task(s)")


# Global task manager instance
task_manager = BackgroundTaskManager()
