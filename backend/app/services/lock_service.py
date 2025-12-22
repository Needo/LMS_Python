from sqlalchemy.orm import Session
from app.models.backup import OperationLock
from typing import Optional
import datetime

class LockService:
    def __init__(self, db: Session):
        self.db = db
    
    def acquire_lock(self, operation_type: str, user_id: int) -> bool:
        """
        Try to acquire a lock for the operation
        Returns True if lock acquired, False if already locked
        """
        # Check if any lock exists
        existing_lock = self.db.query(OperationLock).filter(
            OperationLock.status == 'in_progress'
        ).first()
        
        if existing_lock:
            return False
        
        # Create new lock
        new_lock = OperationLock(
            operation_type=operation_type,
            locked_by_id=user_id,
            locked_at=datetime.datetime.utcnow(),
            status='in_progress'
        )
        
        self.db.add(new_lock)
        self.db.commit()
        return True
    
    def release_lock(self, operation_type: str) -> bool:
        """Release the operation lock"""
        lock = self.db.query(OperationLock).filter(
            OperationLock.operation_type == operation_type,
            OperationLock.status == 'in_progress'
        ).first()
        
        if lock:
            lock.status = 'completed'
            self.db.commit()
            return True
        
        return False
    
    def check_lock_status(self) -> Optional[OperationLock]:
        """Check current lock status"""
        return self.db.query(OperationLock).filter(
            OperationLock.status == 'in_progress'
        ).first()
    
    def force_release_lock(self, user_id: int) -> bool:
        """Force release lock (admin emergency use only)"""
        locks = self.db.query(OperationLock).filter(
            OperationLock.status == 'in_progress'
        ).all()
        
        for lock in locks:
            lock.status = 'force_released'
        
        self.db.commit()
        return True
