"""
Rate limiting for API endpoints
"""
from fastapi import Request, HTTPException, status
from datetime import datetime, timedelta
from typing import Dict, Tuple
import threading

class RateLimiter:
    """
    Simple in-memory rate limiter
    """
    
    def __init__(self):
        self.requests: Dict[str, list] = {}
        self.lock = threading.Lock()
    
    def is_allowed(
        self, 
        key: str, 
        max_requests: int, 
        window_seconds: int
    ) -> Tuple[bool, int]:
        """
        Check if request is allowed
        
        Returns: (is_allowed, remaining_requests)
        """
        with self.lock:
            now = datetime.utcnow()
            window_start = now - timedelta(seconds=window_seconds)
            
            # Get or create request list for this key
            if key not in self.requests:
                self.requests[key] = []
            
            # Remove old requests outside window
            self.requests[key] = [
                req_time for req_time in self.requests[key]
                if req_time > window_start
            ]
            
            # Check if limit exceeded
            current_count = len(self.requests[key])
            
            if current_count >= max_requests:
                return False, 0
            
            # Add current request
            self.requests[key].append(now)
            
            remaining = max_requests - (current_count + 1)
            return True, remaining
    
    def cleanup_old_entries(self):
        """
        Clean up old entries (call periodically)
        """
        with self.lock:
            now = datetime.utcnow()
            # Remove entries older than 1 hour
            cutoff = now - timedelta(hours=1)
            
            keys_to_remove = []
            for key, requests in self.requests.items():
                # Filter out old requests
                self.requests[key] = [
                    req_time for req_time in requests
                    if req_time > cutoff
                ]
                
                # Mark empty entries for removal
                if not self.requests[key]:
                    keys_to_remove.append(key)
            
            # Remove empty entries
            for key in keys_to_remove:
                del self.requests[key]


# Global rate limiter instance
rate_limiter = RateLimiter()


def get_client_ip(request: Request) -> str:
    """
    Get client IP address from request
    """
    # Check for proxy headers first
    forwarded = request.headers.get("X-Forwarded-For")
    if forwarded:
        return forwarded.split(",")[0].strip()
    
    real_ip = request.headers.get("X-Real-IP")
    if real_ip:
        return real_ip
    
    # Fall back to direct client
    if request.client:
        return request.client.host
    
    return "unknown"


def check_rate_limit(
    request: Request,
    max_requests: int,
    window_seconds: int,
    key_prefix: str = ""
) -> None:
    """
    Check rate limit for request, raise HTTPException if exceeded
    """
    client_ip = get_client_ip(request)
    key = f"{key_prefix}:{client_ip}" if key_prefix else client_ip
    
    allowed, remaining = rate_limiter.is_allowed(key, max_requests, window_seconds)
    
    if not allowed:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail=f"Rate limit exceeded. Try again in {window_seconds} seconds.",
            headers={"Retry-After": str(window_seconds)}
        )
