import subprocess
import os
from datetime import datetime
from urllib.parse import urlparse
from sqlalchemy.orm import Session
from typing import Optional, List
from app.models.backup import BackupHistory
from app.models.user import User
from app.core.config import settings
from app.services.lock_service import LockService

class BackupService:
    def __init__(self, db: Session):
        self.db = db
        self.lock_service = LockService(db)
        
        # Ensure backup directory exists
        os.makedirs(settings.BACKUP_DIR, exist_ok=True)
    
    def create_backup(self, user_id: int, notes: Optional[str] = None) -> BackupHistory:
        """
        Creates a new database backup using pg_dump
        """
        # Check if backup operation is already running
        if not self.lock_service.acquire_lock('backup', user_id):
            raise Exception("A backup or restore operation is already in progress")
        
        try:
            # Generate unique filename with timestamp
            timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
            filename = f"backup_{timestamp}.sql"
            output_file = os.path.join(settings.BACKUP_DIR, filename)
            
            # Execute pg_dump
            success = self._execute_pg_dump(output_file)
            
            if not success:
                raise Exception("Backup creation failed")
            
            # Calculate file size
            file_size = os.path.getsize(output_file)
            
            # Get user info
            user = self.db.query(User).filter(User.id == user_id).first()
            
            # Create BackupHistory record
            backup_record = BackupHistory(
                filename=filename,
                file_path=output_file,
                file_size=file_size,
                backup_type='manual',
                created_by_id=user_id,
                status='completed',
                notes=notes
            )
            
            self.db.add(backup_record)
            self.db.commit()
            self.db.refresh(backup_record)
            
            # Cleanup old backups
            self.cleanup_old_backups()
            
            return backup_record
            
        except Exception as e:
            self.db.rollback()
            raise e
        finally:
            # Always release the lock
            self.lock_service.release_lock('backup')
    
    def _execute_pg_dump(self, output_file: str) -> bool:
        """Execute pg_dump command"""
        try:
            # Parse DATABASE_URL
            db_url = urlparse(settings.DATABASE_URL)
            
            # Set environment variable for password
            env = os.environ.copy()
            env['PGPASSWORD'] = db_url.password
            
            # Build pg_dump command
            cmd = [
                os.path.join(settings.POSTGRES_BIN_PATH, 'pg_dump'),
                '-h', db_url.hostname or 'localhost',
                '-p', str(db_url.port or 5432),
                '-U', db_url.username,
                '-d', db_url.path[1:],  # Remove leading /
                '-F', 'c',  # Custom format (compressed)
                '-f', output_file
            ]
            
            result = subprocess.run(cmd, env=env, capture_output=True, text=True)
            
            if result.returncode != 0:
                print(f"pg_dump error: {result.stderr}")
                return False
            
            return True
            
        except Exception as e:
            print(f"Error executing pg_dump: {e}")
            return False
    
    def list_backups(self, limit: int = 50, offset: int = 0) -> List[BackupHistory]:
        """List all backups with pagination"""
        backups = self.db.query(BackupHistory).order_by(
            BackupHistory.created_at.desc()
        ).offset(offset).limit(limit).all()
        
        return backups
    
    def get_backup_by_id(self, backup_id: int) -> Optional[BackupHistory]:
        """Get specific backup details"""
        return self.db.query(BackupHistory).filter(
            BackupHistory.id == backup_id
        ).first()
    
    def delete_backup(self, backup_id: int, user_id: int) -> bool:
        """Delete backup file and record"""
        backup = self.get_backup_by_id(backup_id)
        
        if not backup:
            return False
        
        try:
            # Delete physical file
            if os.path.exists(backup.file_path):
                os.remove(backup.file_path)
            
            # Delete database record
            self.db.delete(backup)
            self.db.commit()
            
            return True
            
        except Exception as e:
            self.db.rollback()
            print(f"Error deleting backup: {e}")
            return False
    
    def cleanup_old_backups(self) -> int:
        """Auto-cleanup old backups beyond MAX_BACKUPS_TO_KEEP"""
        backups = self.db.query(BackupHistory).order_by(
            BackupHistory.created_at.desc()
        ).all()
        
        if len(backups) <= settings.MAX_BACKUPS_TO_KEEP:
            return 0
        
        # Delete oldest backups
        backups_to_delete = backups[settings.MAX_BACKUPS_TO_KEEP:]
        deleted_count = 0
        
        for backup in backups_to_delete:
            try:
                if os.path.exists(backup.file_path):
                    os.remove(backup.file_path)
                
                self.db.delete(backup)
                deleted_count += 1
            except Exception as e:
                print(f"Error deleting old backup {backup.id}: {e}")
        
        self.db.commit()
        return deleted_count
