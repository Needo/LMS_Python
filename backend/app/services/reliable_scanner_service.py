"""
Reliable scanner service with state machine and error tracking
"""
import os
from datetime import datetime
from typing import Optional, List, Tuple
from sqlalchemy.orm import Session
from sqlalchemy.exc import SQLAlchemyError
from app.models.scan_history import ScanHistory, ScanError, ScanLock, ScanStatus
from app.services.scanner_service import ScannerService
from app.schemas.scanner import ScanResult, ScanHistoryResponse, ScanStatusResponse
from app.core.security_utils import SecurityValidator

class ReliableScannerService:
    """
    Wrapper for ScannerService that adds:
    - State machine tracking
    - Concurrent scan prevention
    - Error logging
    - Transaction boundaries
    - Partial scan handling
    """
    
    def __init__(self, db: Session):
        self.db = db
        self.scanner = ScannerService(db)
        self.current_scan_id: Optional[int] = None
        self.error_count = 0
    
    def acquire_lock(self, user_id: int, scan_id: int) -> Tuple[bool, Optional[str]]:
        """
        Acquire scan lock to prevent concurrent scans
        Returns: (success, error_message)
        """
        try:
            lock = self.db.query(ScanLock).filter(ScanLock.id == 1).first()
            
            if not lock:
                # Create lock if doesn't exist
                lock = ScanLock(id=1, is_locked=False)
                self.db.add(lock)
                self.db.flush()
            
            if lock.is_locked:
                return False, f"Scan already in progress (started at {lock.locked_at})"
            
            # Acquire lock
            lock.is_locked = True
            lock.locked_by_id = user_id
            lock.locked_at = datetime.utcnow()
            lock.scan_id = scan_id
            self.db.commit()
            
            return True, None
            
        except Exception as e:
            self.db.rollback()
            return False, f"Error acquiring lock: {str(e)}"
    
    def release_lock(self):
        """Release scan lock"""
        try:
            lock = self.db.query(ScanLock).filter(ScanLock.id == 1).first()
            if lock:
                lock.is_locked = False
                lock.locked_by_id = None
                lock.locked_at = None
                lock.scan_id = None
                self.db.commit()
        except Exception as e:
            print(f"Error releasing lock: {e}")
            self.db.rollback()
    
    def create_scan_record(self, user_id: int, root_path: str) -> ScanHistory:
        """Create initial scan history record"""
        scan = ScanHistory(
            started_by_id=user_id,
            started_at=datetime.utcnow(),
            status=ScanStatus.PENDING,
            root_path=root_path
        )
        self.db.add(scan)
        self.db.flush()
        return scan
    
    def log_error(self, scan_id: int, file_path: str, error_type: str, error_message: str):
        """Log file-level scan error"""
        try:
            error = ScanError(
                scan_id=scan_id,
                file_path=file_path,
                error_type=error_type,
                error_message=error_message
            )
            self.db.add(error)
            self.error_count += 1
        except Exception as e:
            print(f"Error logging scan error: {e}")
    
    def scan_root_folder_reliable(self, root_path: str, user_id: int) -> ScanResult:
        """
        Scan with full state management and error tracking
        """
        scan = None
        
        try:
            # Step 1: Create scan record
            scan = self.create_scan_record(user_id, root_path)
            self.db.commit()
            self.current_scan_id = scan.id
            self.error_count = 0
            
            # Step 2: Acquire lock
            success, error_msg = self.acquire_lock(user_id, scan.id)
            if not success:
                scan.status = ScanStatus.FAILED
                scan.completed_at = datetime.utcnow()
                scan.error_message = error_msg
                self.db.commit()
                
                return ScanResult(
                    success=False,
                    message=error_msg,
                    scan_id=scan.id,
                    status=ScanStatus.FAILED
                )
            
            # Step 3: Update status to running
            scan.status = ScanStatus.RUNNING
            self.db.commit()
            
            # Step 4: Validate root path
            validation = settings.validate_root_path(root_path)
            if not validation['valid']:
                raise ValueError(f"Invalid root path: {validation['error']}")
            
            # Step 5: Execute scan with transaction
            result = self._execute_scan_with_tracking(scan, root_path)
            
            # Step 6: Update scan record with results
            scan.categories_found = result.categories_found
            scan.courses_found = result.courses_found
            scan.files_added = result.files_added
            scan.files_updated = result.files_updated
            scan.files_removed = result.files_removed
            scan.errors_count = self.error_count
            scan.completed_at = datetime.utcnow()
            scan.message = result.message
            
            # Determine final status
            if result.success:
                if self.error_count > 0:
                    scan.status = ScanStatus.PARTIAL
                    scan.message = f"Scan completed with {self.error_count} errors"
                else:
                    scan.status = ScanStatus.COMPLETED
            else:
                scan.status = ScanStatus.FAILED
                scan.error_message = result.message
            
            self.db.commit()
            
            # Add scan info to result
            result.scan_id = scan.id
            result.status = scan.status
            result.errors_count = self.error_count
            
            return result
            
        except Exception as e:
            self.db.rollback()
            
            # Update scan record if exists
            if scan:
                scan.status = ScanStatus.FAILED
                scan.completed_at = datetime.utcnow()
                scan.error_message = str(e)
                scan.errors_count = self.error_count
                try:
                    self.db.commit()
                except:
                    pass
            
            return ScanResult(
                success=False,
                message=f"Scan failed: {str(e)}",
                scan_id=scan.id if scan else None,
                status=ScanStatus.FAILED,
                errors_count=self.error_count
            )
            
        finally:
            # Always release lock
            self.release_lock()
    
    def _execute_scan_with_tracking(self, scan: ScanHistory, root_path: str) -> ScanResult:
        """
        Execute scan and track errors
        Wraps original scanner service
        """
        # Inject error tracking into scanner
        original_validate = SecurityValidator.validate_extension
        
        def tracked_validate(filename: str) -> Tuple[bool, Optional[str]]:
            is_valid, error = original_validate(filename)
            if not is_valid:
                self.log_error(
                    scan.id,
                    filename,
                    "invalid_extension",
                    error
                )
            return is_valid, error
        
        # Temporarily replace validator
        SecurityValidator.validate_extension = tracked_validate
        
        try:
            # Call original scanner
            result = self.scanner.scan_root_folder(root_path)
            return result
        finally:
            # Restore original validator
            SecurityValidator.validate_extension = original_validate
    
    def get_scan_status(self) -> ScanStatusResponse:
        """Get current scan status"""
        try:
            lock = self.db.query(ScanLock).filter(ScanLock.id == 1).first()
            
            is_scanning = lock.is_locked if lock else False
            current_scan_id = lock.scan_id if lock and lock.is_locked else None
            
            # Get current scan details if running
            current_scan = None
            if current_scan_id:
                current_scan = self.db.query(ScanHistory).filter(
                    ScanHistory.id == current_scan_id
                ).first()
            
            # Get last completed scan
            last_scan = self.db.query(ScanHistory).filter(
                ScanHistory.status.in_([ScanStatus.COMPLETED, ScanStatus.FAILED, ScanStatus.PARTIAL])
            ).order_by(ScanHistory.completed_at.desc()).first()
            
            return ScanStatusResponse(
                is_scanning=is_scanning,
                current_scan_id=current_scan_id,
                status=current_scan.status if current_scan else None,
                started_at=current_scan.started_at if current_scan else None,
                locked_by_id=lock.locked_by_id if lock and is_scanning else None,
                last_scan=ScanHistoryResponse.from_orm(last_scan) if last_scan else None
            )
            
        except Exception as e:
            print(f"Error getting scan status: {e}")
            return ScanStatusResponse(
                is_scanning=False,
                current_scan_id=None,
                status=None,
                started_at=None,
                locked_by_id=None,
                last_scan=None
            )
    
    def get_scan_history(self, limit: int = 10) -> List[ScanHistoryResponse]:
        """Get scan history"""
        try:
            scans = self.db.query(ScanHistory).order_by(
                ScanHistory.started_at.desc()
            ).limit(limit).all()
            
            return [ScanHistoryResponse.from_orm(scan) for scan in scans]
        except Exception as e:
            print(f"Error getting scan history: {e}")
            return []
    
    def get_scan_errors(self, scan_id: int) -> List[ScanError]:
        """Get errors for specific scan"""
        try:
            return self.db.query(ScanError).filter(
                ScanError.scan_id == scan_id
            ).all()
        except Exception as e:
            print(f"Error getting scan errors: {e}")
            return []


# Import settings for path validation
from app.core.config import settings
