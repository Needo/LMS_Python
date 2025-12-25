"""
Simple in-memory cache for read-heavy endpoints
"""
from typing import Any, Optional, Callable
from datetime import datetime, timedelta
from functools import wraps
import hashlib
import json

class SimpleCache:
    """
    Simple in-memory cache with TTL support
    Thread-safe for single-process deployments
    """
    
    def __init__(self):
        self._cache: dict[str, tuple[Any, datetime]] = {}
        self._enabled = True
    
    def get(self, key: str) -> Optional[Any]:
        """Get value from cache if not expired"""
        if not self._enabled:
            return None
            
        if key in self._cache:
            value, expires_at = self._cache[key]
            if datetime.utcnow() < expires_at:
                return value
            else:
                # Expired, remove it
                del self._cache[key]
        
        return None
    
    def set(self, key: str, value: Any, ttl_seconds: int = 300):
        """Set value in cache with TTL"""
        if not self._enabled:
            return
            
        expires_at = datetime.utcnow() + timedelta(seconds=ttl_seconds)
        self._cache[key] = (value, expires_at)
    
    def invalidate(self, key: str):
        """Remove specific key from cache"""
        if key in self._cache:
            del self._cache[key]
    
    def invalidate_pattern(self, pattern: str):
        """Remove all keys matching pattern"""
        keys_to_delete = [k for k in self._cache.keys() if pattern in k]
        for key in keys_to_delete:
            del self._cache[key]
    
    def clear(self):
        """Clear entire cache"""
        self._cache.clear()
    
    def enable(self):
        """Enable caching"""
        self._enabled = True
    
    def disable(self):
        """Disable caching"""
        self._enabled = False
        self.clear()

# Global cache instance
cache = SimpleCache()

def cached(ttl_seconds: int = 300, key_prefix: str = ""):
    """
    Decorator to cache function results
    
    Usage:
        @cached(ttl_seconds=600, key_prefix="categories")
        def get_categories(user_id: int):
            return db.query(Category).all()
    """
    def decorator(func: Callable):
        @wraps(func)
        def wrapper(*args, **kwargs):
            # Generate cache key from function name and arguments
            key_parts = [key_prefix or func.__name__]
            
            # Add positional args (skip 'self' and 'db')
            for arg in args:
                if hasattr(arg, '__class__'):
                    # Skip class instances (self, db)
                    if arg.__class__.__name__ in ('Session', 'AuthorizationService'):
                        continue
                key_parts.append(str(arg))
            
            # Add keyword args
            for k, v in sorted(kwargs.items()):
                key_parts.append(f"{k}={v}")
            
            cache_key = hashlib.md5(
                json.dumps(key_parts).encode()
            ).hexdigest()
            
            # Try to get from cache
            cached_value = cache.get(cache_key)
            if cached_value is not None:
                return cached_value
            
            # Call function and cache result
            result = func(*args, **kwargs)
            cache.set(cache_key, result, ttl_seconds)
            
            return result
        
        return wrapper
    return decorator

def invalidate_cache(pattern: str = ""):
    """
    Invalidate cache entries
    
    Usage:
        # After creating/updating/deleting data
        invalidate_cache("categories")
        invalidate_cache("courses")
    """
    if pattern:
        cache.invalidate_pattern(pattern)
    else:
        cache.clear()
