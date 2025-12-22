from pydantic_settings import BaseSettings
from pydantic import field_validator, ValidationError
from typing import List, Optional
import os
from pathlib import Path
import secrets

class Settings(BaseSettings):
    # Environment
    ENV: str = "development"
    DEBUG: bool = False
    LOG_LEVEL: str = "INFO"
    
    # Application
    PROJECT_NAME: str = "Learning Management System"
    API_V1_PREFIX: str = "/api"
    
    # Database
    DATABASE_URL: str
    
    # Security
    SECRET_KEY: str
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    
    # CORS
    BACKEND_CORS_ORIGINS: List[str] = ["http://localhost:4200"]
    
    # File Storage Configuration
    ROOT_FOLDER_PATH: Optional[str] = None
    MAX_FILE_SIZE: int = 104857600  # 100MB default
    ALLOWED_EXTENSIONS: str = ".pdf,.mp4,.mp3,.txt,.docx,.jpg,.png,.epub"
    SCAN_DEPTH: int = 10
    
    # Backup Configuration
    BACKUP_DIR: str = "./backups"
    MAX_BACKUP_SIZE: int = 1073741824  # 1GB
    MAX_BACKUPS_TO_KEEP: int = 10
    POSTGRES_BIN_PATH: str = "/usr/bin"
    
    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        case_sensitive = True
        extra = "ignore"
    
    @field_validator("SECRET_KEY")
    @classmethod
    def validate_secret_key(cls, v: str, info) -> str:
        """Validate SECRET_KEY is strong enough for production"""
        env = info.data.get("ENV", "development")
        
        if env == "production":
            weak_keys = [
                "my-secret-key",
                "change-this",
                "secret",
                "CHANGE-THIS",
                "dev-secret"
            ]
            if any(weak in v for weak in weak_keys) or len(v) < 32:
                raise ValueError(
                    "SECRET_KEY is too weak for production! "
                    "Use: python -c 'import secrets; print(secrets.token_urlsafe(32))'"
                )
        
        return v
    
    @field_validator("MAX_FILE_SIZE")
    @classmethod
    def validate_file_size(cls, v: int) -> int:
        """Validate file size is reasonable"""
        if v < 1024:  # 1KB minimum
            raise ValueError("MAX_FILE_SIZE must be at least 1KB")
        if v > 5368709120:  # 5GB maximum
            raise ValueError("MAX_FILE_SIZE cannot exceed 5GB")
        return v
    
    @field_validator("SCAN_DEPTH")
    @classmethod
    def validate_scan_depth(cls, v: int) -> int:
        """Validate scan depth is reasonable"""
        if v < 1:
            raise ValueError("SCAN_DEPTH must be at least 1")
        if v > 50:
            raise ValueError("SCAN_DEPTH cannot exceed 50 (performance risk)")
        return v
    
    def validate_root_path(self, path: str) -> dict:
        """
        Validate root folder path
        Returns: dict with validation results
        """
        result = {
            "valid": False,
            "exists": False,
            "readable": False,
            "canonical": False,
            "path": None,
            "error": None
        }
        
        try:
            # Check if path exists
            if not os.path.exists(path):
                result["error"] = f"Path does not exist: {path}"
                return result
            
            result["exists"] = True
            
            # Check if it's a directory
            if not os.path.isdir(path):
                result["error"] = "Path is not a directory"
                return result
            
            # Check read permissions
            if not os.access(path, os.R_OK):
                result["error"] = "No read permission for path"
                return result
            
            result["readable"] = True
            
            # Get canonical (absolute, normalized) path
            canonical_path = os.path.abspath(os.path.realpath(path))
            result["path"] = canonical_path
            result["canonical"] = True
            
            # Validate not a system directory (basic safety check)
            system_dirs = [
                "/", "/bin", "/boot", "/dev", "/etc", "/lib", "/proc", "/root", 
                "/sbin", "/sys", "/usr", "/var",
                "C:\\Windows", "C:\\Program Files", "C:\\Program Files (x86)"
            ]
            
            if canonical_path in system_dirs:
                result["error"] = "Cannot use system directory as root folder"
                result["canonical"] = False
                return result
            
            result["valid"] = True
            return result
            
        except Exception as e:
            result["error"] = f"Validation error: {str(e)}"
            return result
    
    def get_allowed_extensions_list(self) -> List[str]:
        """Get list of allowed extensions"""
        return [ext.strip() for ext in self.ALLOWED_EXTENSIONS.split(",")]
    
    def is_extension_allowed(self, filename: str) -> bool:
        """Check if file extension is allowed"""
        ext = os.path.splitext(filename)[1].lower()
        return ext in self.get_allowed_extensions_list()


def get_settings() -> Settings:
    """
    Load settings based on ENV variable
    Tries environment-specific file first, falls back to .env
    """
    env = os.getenv("ENV", "development")
    env_file = f".env.{env}"
    
    # Check if environment-specific file exists
    if os.path.exists(env_file):
        return Settings(_env_file=env_file)
    
    # Fall back to default .env
    return Settings()


# Global settings instance
settings = get_settings()
