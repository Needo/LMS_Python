"""
Structured logging configuration for the LMS
"""
import logging
import json
import sys
from datetime import datetime
from typing import Any, Dict
from pathlib import Path

class StructuredFormatter(logging.Formatter):
    """
    Custom formatter for structured JSON logging
    """
    
    def format(self, record: logging.LogRecord) -> str:
        """Format log record as JSON"""
        
        # Base log structure
        log_data = {
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "level": record.levelname,
            "logger": record.name,
            "message": record.getMessage(),
            "module": record.module,
            "function": record.funcName,
            "line": record.lineno,
        }
        
        # Add correlation ID if present
        if hasattr(record, 'correlation_id'):
            log_data['correlation_id'] = record.correlation_id
        
        # Add scan ID if present
        if hasattr(record, 'scan_id'):
            log_data['scan_id'] = record.scan_id
        
        # Add user ID if present
        if hasattr(record, 'user_id'):
            log_data['user_id'] = record.user_id
        
        # Add extra fields
        if hasattr(record, 'extra'):
            log_data.update(record.extra)
        
        # Add exception info if present
        if record.exc_info:
            log_data['exception'] = self.formatException(record.exc_info)
        
        return json.dumps(log_data)


class ColoredConsoleFormatter(logging.Formatter):
    """
    Colored formatter for console output (development)
    """
    
    COLORS = {
        'DEBUG': '\033[36m',      # Cyan
        'INFO': '\033[32m',       # Green
        'WARNING': '\033[33m',    # Yellow
        'ERROR': '\033[31m',      # Red
        'CRITICAL': '\033[35m',   # Magenta
        'RESET': '\033[0m'
    }
    
    def format(self, record: logging.LogRecord) -> str:
        """Format with colors"""
        color = self.COLORS.get(record.levelname, self.COLORS['RESET'])
        reset = self.COLORS['RESET']
        
        # Format message
        message = super().format(record)
        
        # Add correlation ID if present
        if hasattr(record, 'correlation_id'):
            message = f"[{record.correlation_id}] {message}"
        
        return f"{color}{message}{reset}"


def setup_logging(
    log_level: str = "INFO",
    log_file: str = None,
    structured: bool = False
):
    """
    Setup logging configuration
    
    Args:
        log_level: Logging level (DEBUG, INFO, WARNING, ERROR)
        log_file: Optional file path for logs
        structured: Use structured JSON logging
    """
    
    # Create logs directory if needed
    if log_file:
        log_path = Path(log_file)
        log_path.parent.mkdir(parents=True, exist_ok=True)
    
    # Root logger
    root_logger = logging.getLogger()
    root_logger.setLevel(getattr(logging, log_level.upper()))
    
    # Remove existing handlers
    root_logger.handlers = []
    
    # Console handler
    console_handler = logging.StreamHandler(sys.stdout)
    console_handler.setLevel(getattr(logging, log_level.upper()))
    
    if structured:
        console_handler.setFormatter(StructuredFormatter())
    else:
        console_formatter = ColoredConsoleFormatter(
            '%(asctime)s - %(name)s - %(levelname)s - %(message)s',
            datefmt='%Y-%m-%d %H:%M:%S'
        )
        console_handler.setFormatter(console_formatter)
    
    root_logger.addHandler(console_handler)
    
    # File handler (always structured)
    if log_file:
        file_handler = logging.FileHandler(log_file)
        file_handler.setLevel(logging.DEBUG)  # Log everything to file
        file_handler.setFormatter(StructuredFormatter())
        root_logger.addHandler(file_handler)
    
    # Set third-party loggers to WARNING
    logging.getLogger("uvicorn").setLevel(logging.WARNING)
    logging.getLogger("fastapi").setLevel(logging.WARNING)
    logging.getLogger("sqlalchemy").setLevel(logging.WARNING)
    
    logging.info(f"Logging configured: level={log_level}, structured={structured}")


class LoggerAdapter(logging.LoggerAdapter):
    """
    Logger adapter that adds context to log records
    """
    
    def process(self, msg, kwargs):
        """Add extra context to log records"""
        # Add correlation_id, scan_id, etc. to the record
        if 'extra' not in kwargs:
            kwargs['extra'] = {}
        
        kwargs['extra'].update(self.extra)
        return msg, kwargs


def get_logger(name: str, **context) -> logging.Logger:
    """
    Get logger with optional context
    
    Args:
        name: Logger name
        **context: Additional context (correlation_id, scan_id, user_id, etc.)
    
    Returns:
        Logger instance
    """
    logger = logging.getLogger(name)
    
    if context:
        return LoggerAdapter(logger, context)
    
    return logger
