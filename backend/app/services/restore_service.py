import subprocess
import os
from urllib.parse import urlparse
from sqlalchemy.orm import Session
from app.models.backup import BackupHistory
from app.core.config import settings
from app.services.lock_service import LockService

class RestoreService:
    def __init__(self, db: Session):
        self.db = db
        self.lock_service = LockService(db)
    
    def restore_backup(self, backup_id: int, user_id: int) -> bool:
        """
        Restore database from backup
        WARNING: This is a DESTRUCTIVE operation!
        """
        # Check if any operation is running
        if not self.lock_service.acquire_lock('restore', user_id):
            raise Exception("A backup or restore operation is already in progress")
        
        try:
            # Get backup record
            backup = self.db.query(BackupHistory).filter(
                BackupHistory.id == backup_id
            ).first()
            
            if not backup:
                raise Exception("Backup not found")
            
            # Validate backup file exists
            if not os.path.exists(backup.file_path):
                raise Exception("Backup file not found on disk")
            
            # Execute pg_restore
            success = self._execute_pg_restore(backup.file_path)
            
            if not success:
                raise Exception("Restore failed")
            
            # Verify database integrity
            if not self._verify_database_integrity():
                raise Exception("Database integrity check failed after restore")
            
            return True
            
        except Exception as e:
            raise e
        finally:
            # Always release the lock
            self.lock_service.release_lock('restore')
    
    def _execute_pg_restore(self, backup_file: str) -> bool:
        """Execute pg_restore command"""
        try:
            # Parse DATABASE_URL
            db_url = urlparse(settings.DATABASE_URL)
            
            # Set environment variable for password
            env = os.environ.copy()
            env['PGPASSWORD'] = db_url.password
            
            # Build pg_restore command
            cmd = [
                os.path.join(settings.POSTGRES_BIN_PATH, 'pg_restore'),
                '-h', db_url.hostname or 'localhost',
                '-p', str(db_url.port or 5432),
                '-U', db_url.username,
                '-d', db_url.path[1:],  # Remove leading /
                '--clean',  # Drop objects before recreating
                '--if-exists',  # Don't error if objects don't exist
                backup_file
            ]
            
            result = subprocess.run(cmd, env=env, capture_output=True, text=True)
            
            # pg_restore may return non-zero even on success due to warnings
            # Check if critical errors occurred
            if "FATAL" in result.stderr or "ERROR" in result.stderr:
                print(f"pg_restore error: {result.stderr}")
                return False
            
            return True
            
        except Exception as e:
            print(f"Error executing pg_restore: {e}")
            return False
    
    def _verify_database_integrity(self) -> bool:
        """Run basic integrity checks after restore"""
        try:
            # Simple check: Can we query the database?
            from app.models.user import User
            user_count = self.db.query(User).count()
            return True
        except Exception as e:
            print(f"Integrity check failed: {e}")
            return False
