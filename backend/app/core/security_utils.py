"""
Security utilities for file and path validation
"""
import os
import mimetypes
from pathlib import Path
from typing import Optional, Tuple
from app.core.config import settings

# MIME type mapping for allowed extensions
ALLOWED_MIME_TYPES = {
    '.pdf': 'application/pdf',
    '.mp4': 'video/mp4',
    '.mp3': 'audio/mpeg',
    '.txt': 'text/plain',
    '.docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    '.jpg': 'image/jpeg',
    '.jpeg': 'image/jpeg',
    '.png': 'image/png',
    '.epub': 'application/epub+zip',
    '.mkv': 'video/x-matroska',
    '.avi': 'video/x-msvideo',
    '.mov': 'video/quicktime',
    '.wav': 'audio/wav',
    '.flac': 'audio/flac',
    '.gif': 'image/gif',
    '.webp': 'image/webp',
}

class SecurityValidator:
    """
    Validates file paths and operations for security
    """
    
    @staticmethod
    def validate_path(file_path: str, root_path: str) -> Tuple[bool, Optional[str]]:
        """
        Validate file path for security issues
        
        Returns: (is_valid, error_message)
        """
        try:
            # Get absolute, normalized paths
            abs_file_path = os.path.abspath(os.path.realpath(file_path))
            abs_root_path = os.path.abspath(os.path.realpath(root_path))
            
            # Check 1: Path traversal protection
            if not abs_file_path.startswith(abs_root_path):
                return False, "Path traversal detected: file is outside root directory"
            
            # Check 2: Symlink detection
            if os.path.islink(file_path):
                # Resolve symlink and check if it points outside root
                real_path = os.path.realpath(file_path)
                if not real_path.startswith(abs_root_path):
                    return False, "Symlink points outside root directory"
            
            # Check 3: File exists
            if not os.path.exists(abs_file_path):
                return False, "File does not exist"
            
            # Check 4: Is a file (not directory)
            if not os.path.isfile(abs_file_path):
                return False, "Path is not a file"
            
            return True, None
            
        except Exception as e:
            return False, f"Path validation error: {str(e)}"
    
    @staticmethod
    def validate_extension(filename: str) -> Tuple[bool, Optional[str]]:
        """
        Validate file extension against allow-list
        
        Returns: (is_valid, error_message)
        """
        ext = os.path.splitext(filename)[1].lower()
        
        if not ext:
            return False, "File has no extension"
        
        allowed_extensions = settings.get_allowed_extensions_list()
        
        if ext not in allowed_extensions:
            return False, f"File extension '{ext}' is not allowed. Allowed: {', '.join(allowed_extensions)}"
        
        return True, None
    
    @staticmethod
    def validate_mime_type(file_path: str) -> Tuple[bool, Optional[str]]:
        """
        Validate MIME type matches file extension
        
        Returns: (is_valid, error_message)
        """
        ext = os.path.splitext(file_path)[1].lower()
        expected_mime = ALLOWED_MIME_TYPES.get(ext)
        
        if not expected_mime:
            return False, f"No MIME type mapping for extension '{ext}'"
        
        # Guess MIME type from file
        guessed_mime, _ = mimetypes.guess_type(file_path)
        
        # Some files might not have detectable MIME type (encrypted, etc)
        # We'll allow them if extension is in whitelist
        if guessed_mime and guessed_mime != expected_mime:
            # Allow some common variations
            mime_aliases = {
                'application/octet-stream': True,  # Generic binary
                'text/plain': True,  # Generic text
            }
            
            if guessed_mime not in mime_aliases:
                return False, f"MIME type mismatch: expected '{expected_mime}', got '{guessed_mime}'"
        
        return True, None
    
    @staticmethod
    def validate_file_size(file_path: str, max_size: Optional[int] = None) -> Tuple[bool, Optional[str]]:
        """
        Validate file size is within limits
        
        Returns: (is_valid, error_message)
        """
        if max_size is None:
            max_size = settings.MAX_FILE_SIZE
        
        try:
            file_size = os.path.getsize(file_path)
            
            if file_size > max_size:
                max_mb = max_size / (1024 * 1024)
                actual_mb = file_size / (1024 * 1024)
                return False, f"File size ({actual_mb:.2f} MB) exceeds limit ({max_mb:.2f} MB)"
            
            return True, None
            
        except Exception as e:
            return False, f"Error checking file size: {str(e)}"
    
    @staticmethod
    def sanitize_filename(filename: str) -> str:
        """
        Sanitize filename to prevent attacks
        """
        # Remove path separators
        filename = filename.replace('/', '_').replace('\\', '_')
        
        # Remove null bytes
        filename = filename.replace('\x00', '')
        
        # Remove leading/trailing dots and spaces
        filename = filename.strip('. ')
        
        # Limit length
        if len(filename) > 255:
            name, ext = os.path.splitext(filename)
            filename = name[:250] + ext
        
        return filename
    
    @staticmethod
    def validate_file(file_path: str, root_path: str) -> Tuple[bool, Optional[str]]:
        """
        Complete file validation
        
        Returns: (is_valid, error_message)
        """
        # 1. Path validation
        valid, error = SecurityValidator.validate_path(file_path, root_path)
        if not valid:
            return False, error
        
        # 2. Extension validation
        valid, error = SecurityValidator.validate_extension(file_path)
        if not valid:
            return False, error
        
        # 3. MIME type validation (optional - can be slow)
        # Disabled by default for performance
        # valid, error = SecurityValidator.validate_mime_type(file_path)
        # if not valid:
        #     return False, error
        
        # 4. File size validation
        valid, error = SecurityValidator.validate_file_size(file_path)
        if not valid:
            return False, error
        
        return True, None


def is_safe_path(path: str, root_path: str) -> bool:
    """
    Quick check if path is safe (within root, no traversal)
    """
    try:
        abs_path = os.path.abspath(os.path.realpath(path))
        abs_root = os.path.abspath(os.path.realpath(root_path))
        return abs_path.startswith(abs_root)
    except:
        return False
