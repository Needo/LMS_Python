"""
Middleware for request correlation IDs
"""
import uuid
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from fastapi import Response
import logging
from contextvars import ContextVar

# Context variable for correlation ID
correlation_id_var: ContextVar[str] = ContextVar('correlation_id', default=None)

logger = logging.getLogger(__name__)

class CorrelationIdMiddleware(BaseHTTPMiddleware):
    """
    Middleware to generate and track correlation IDs
    """
    
    async def dispatch(self, request: Request, call_next):
        """Add correlation ID to request"""
        
        # Get or generate correlation ID
        correlation_id = request.headers.get('X-Correlation-ID')
        
        if not correlation_id:
            correlation_id = str(uuid.uuid4())
        
        # Store in context variable
        correlation_id_var.set(correlation_id)
        
        # Add to request state
        request.state.correlation_id = correlation_id
        
        # Log request
        logger.info(
            f"{request.method} {request.url.path}",
            extra={
                'correlation_id': correlation_id,
                'method': request.method,
                'path': request.url.path,
                'client': request.client.host if request.client else None
            }
        )
        
        # Process request
        response = await call_next(request)
        
        # Add correlation ID to response headers
        response.headers['X-Correlation-ID'] = correlation_id
        
        # Log response
        logger.info(
            f"{request.method} {request.url.path} - {response.status_code}",
            extra={
                'correlation_id': correlation_id,
                'status_code': response.status_code,
                'method': request.method,
                'path': request.url.path
            }
        )
        
        return response


def get_correlation_id() -> str:
    """Get current correlation ID"""
    return correlation_id_var.get()
