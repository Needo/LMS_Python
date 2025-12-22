from pydantic_settings import BaseSettings
from typing import List
import os

class Settings(BaseSettings):
    PROJECT_NAME: str = "Learning Management System"
    API_V1_PREFIX: str = "/api"
    
    DATABASE_URL: str
    
    SECRET_KEY: str
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    
    BACKEND_CORS_ORIGINS: List[str] = ["http://localhost:4200"]
    
    # Backup Configuration
    BACKUP_DIR: str = "./backups"
    MAX_BACKUP_SIZE: int = 1073741824  # 1GB max backup size
    MAX_BACKUPS_TO_KEEP: int = 10  # Auto-cleanup old backups
    POSTGRES_BIN_PATH: str = "/usr/bin"  # Path to pg_dump/pg_restore (Linux)
    # For Windows, use: "C:\\Program Files\\PostgreSQL\\16\\bin"
    
    class Config:
        env_file = ".env"
        case_sensitive = True

settings = Settings()
