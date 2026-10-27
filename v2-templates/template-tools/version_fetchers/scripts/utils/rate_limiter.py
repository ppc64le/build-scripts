"""
Rate limiting utilities for API calls.

Provides thread-safe rate limiting for external API calls to prevent
exceeding rate limits.
"""

import time
import threading
from typing import Callable, Any, Optional
from functools import wraps
from collections import deque
import logging


logger = logging.getLogger(__name__)


class RateLimiter:
    """
    Thread-safe rate limiter using sliding window algorithm.
    
    Tracks request timestamps and enforces rate limits per time period.
    
    Example:
        >>> limiter = RateLimiter(max_calls=5000, period=3600)  # 5000/hour
        >>> limiter.acquire()  # Blocks if rate limit exceeded
        >>> # Make API call
        >>> limiter.release()
    """
    
    def __init__(self, max_calls: int, period: float):
        """
        Initialize rate limiter.
        
        Args:
            max_calls: Maximum number of calls allowed
            period: Time period in seconds
        
        Example:
            >>> limiter = RateLimiter(5000, 3600)  # 5000 calls per hour
            >>> limiter = RateLimiter(100, 60)     # 100 calls per minute
        """
        self.max_calls = max_calls
        self.period = period
        self.calls = deque()
        self.lock = threading.Lock()
        
        logger.debug(
            f"Initialized RateLimiter: {max_calls} calls per {period}s "
            f"({max_calls / period:.2f} calls/sec)"
        )
    
    def acquire(self, timeout: Optional[float] = None) -> bool:
        """
        Acquire permission to make a call.
        
        Blocks until a call slot is available or timeout is reached.
        
        Args:
            timeout: Maximum time to wait in seconds (None = wait forever)
        
        Returns:
            True if acquired, False if timeout
        
        Example:
            >>> if limiter.acquire(timeout=10):
            ...     # Make API call
            ...     limiter.release()
        """
        start_time = time.time()
        
        while True:
            with self.lock:
                now = time.time()
                
                # Remove old calls outside the window
                while self.calls and self.calls[0] <= now - self.period:
                    self.calls.popleft()
                
                # Check if we can make a call
                if len(self.calls) < self.max_calls:
                    self.calls.append(now)
                    return True
                
                # Calculate wait time
                if self.calls:
                    oldest_call = self.calls[0]
                    wait_time = (oldest_call + self.period) - now
                else:
                    wait_time = 0
            
            # Check timeout
            if timeout is not None:
                elapsed = time.time() - start_time
                if elapsed >= timeout:
                    logger.warning(
                        f"Rate limiter timeout after {elapsed:.2f}s "
                        f"(limit: {self.max_calls}/{self.period}s)"
                    )
                    return False
                
                # Don't wait longer than remaining timeout
                wait_time = min(wait_time, timeout - elapsed)
            
            # Wait before retrying
            if wait_time > 0:
                # Only log if wait is significant (> 1 second)
                if wait_time > 1.0:
                    logger.info(f"Rate limit reached, waiting {wait_time:.1f}s")
                # Sleep exact amount needed (no busy-waiting)
                time.sleep(wait_time)
            else:
                # Minimal sleep to prevent CPU spinning
                time.sleep(0.01)
    
    def release(self):
        """
        Release is a no-op for this implementation.
        
        Calls are automatically removed from the window after the period.
        This method exists for API compatibility.
        """
        pass
    
    def get_stats(self) -> dict:
        """
        Get current rate limiter statistics.
        
        Returns:
            Dictionary with current stats
        
        Example:
            >>> stats = limiter.get_stats()
            >>> print(f"Calls in window: {stats['calls_in_window']}")
        """
        with self.lock:
            now = time.time()
            
            # Remove old calls
            while self.calls and self.calls[0] <= now - self.period:
                self.calls.popleft()
            
            calls_in_window = len(self.calls)
            available_calls = self.max_calls - calls_in_window
            
            return {
                'max_calls': self.max_calls,
                'period': self.period,
                'calls_in_window': calls_in_window,
                'available_calls': available_calls,
                'utilization': calls_in_window / self.max_calls,
            }


def rate_limit(max_calls: int, period: float):
    """
    Decorator for rate limiting function calls.
    
    Args:
        max_calls: Maximum number of calls allowed
        period: Time period in seconds
    
    Returns:
        Decorated function
    
    Example:
        >>> @rate_limit(max_calls=100, period=60)
        ... def fetch_data(url):
        ...     return requests.get(url)
    """
    limiter = RateLimiter(max_calls, period)
    
    def decorator(func: Callable) -> Callable:
        @wraps(func)
        def wrapper(*args, **kwargs) -> Any:
            limiter.acquire()
            try:
                return func(*args, **kwargs)
            finally:
                limiter.release()
        
        # Attach limiter to function for inspection
        wrapper.rate_limiter = limiter
        
        return wrapper
    
    return decorator


# Example usage
if __name__ == '__main__':
    import requests
    
    # Setup logging
    logging.basicConfig(level=logging.DEBUG)
    
    # Example 1: Direct usage
    print("Example 1: Direct RateLimiter usage")
    limiter = RateLimiter(max_calls=5, period=10)  # 5 calls per 10 seconds
    
    for i in range(7):
        print(f"Call {i + 1}...")
        limiter.acquire()
        print(f"  Acquired! Stats: {limiter.get_stats()}")
        time.sleep(1)
    
    # Example 2: Decorator usage
    print("\nExample 2: Decorator usage")
    
    @rate_limit(max_calls=3, period=5)
    def fetch_url(url: str) -> str:
        print(f"  Fetching: {url}")
        return f"Response from {url}"
    
    for i in range(5):
        print(f"Request {i + 1}...")
        result = fetch_url(f"https://api.example.com/data/{i}")
        print(f"  {result}")