"""
Retry logic with exponential backoff.

Provides decorators and utilities for retrying failed operations with
configurable backoff strategies.
"""

import time
import logging
from typing import Callable, Any, Optional, Type, Tuple
from functools import wraps


logger = logging.getLogger(__name__)


def retry_with_backoff(
    max_retries: int = 3,
    initial_delay: float = 1.0,
    max_delay: float = 60.0,
    exponential_base: float = 2.0,
    exceptions: Tuple[Type[Exception], ...] = (Exception,),
    on_retry: Optional[Callable[[Exception, int], None]] = None,
):
    """
    Decorator for retrying function calls with exponential backoff.
    
    Args:
        max_retries: Maximum number of retry attempts (default: 3)
        initial_delay: Initial delay in seconds (default: 1.0)
        max_delay: Maximum delay in seconds (default: 60.0)
        exponential_base: Base for exponential backoff (default: 2.0)
        exceptions: Tuple of exceptions to catch (default: all exceptions)
        on_retry: Optional callback function(exception, attempt) called on each retry
    
    Returns:
        Decorated function
    
    Example:
        >>> @retry_with_backoff(max_retries=3, initial_delay=1.0)
        ... def fetch_data(url):
        ...     return requests.get(url)
        
        >>> @retry_with_backoff(
        ...     max_retries=5,
        ...     exceptions=(requests.RequestException,),
        ...     on_retry=lambda e, attempt: print(f"Retry {attempt}: {e}")
        ... )
        ... def api_call():
        ...     return requests.get("https://api.example.com")
    """
    def decorator(func: Callable) -> Callable:
        @wraps(func)
        def wrapper(*args, **kwargs) -> Any:
            last_exception = None
            
            for attempt in range(max_retries + 1):
                try:
                    return func(*args, **kwargs)
                
                except exceptions as e:
                    last_exception = e
                    
                    # Don't retry on last attempt
                    if attempt == max_retries:
                        logger.error(
                            f"Function {func.__name__} failed after {max_retries} retries: {e}"
                        )
                        raise
                    
                    # Calculate delay with exponential backoff
                    delay = min(
                        initial_delay * (exponential_base ** attempt),
                        max_delay
                    )
                    
                    logger.warning(
                        f"Function {func.__name__} failed (attempt {attempt + 1}/{max_retries + 1}): {e}. "
                        f"Retrying in {delay:.2f}s..."
                    )
                    
                    # Call retry callback if provided
                    if on_retry:
                        try:
                            on_retry(e, attempt + 1)
                        except Exception as callback_error:
                            logger.error(f"Error in retry callback: {callback_error}")
                    
                    # Wait before retrying
                    time.sleep(delay)
            
            # Should never reach here, but just in case
            if last_exception:
                raise last_exception
        
        return wrapper
    
    return decorator


class RetryContext:
    """
    Context manager for retry logic with exponential backoff.
    
    Useful when you need more control over the retry logic than a decorator provides.
    
    Example:
        >>> retry = RetryContext(max_retries=3, initial_delay=1.0)
        >>> for attempt in retry:
        ...     try:
        ...         result = api_call()
        ...         break  # Success, exit retry loop
        ...     except Exception as e:
        ...         if not retry.should_retry(e):
        ...             raise
        ...         # Will automatically wait before next iteration
    """
    
    def __init__(
        self,
        max_retries: int = 3,
        initial_delay: float = 1.0,
        max_delay: float = 60.0,
        exponential_base: float = 2.0,
        exceptions: Tuple[Type[Exception], ...] = (Exception,),
    ):
        """
        Initialize retry context.
        
        Args:
            max_retries: Maximum number of retry attempts
            initial_delay: Initial delay in seconds
            max_delay: Maximum delay in seconds
            exponential_base: Base for exponential backoff
            exceptions: Tuple of exceptions to catch
        """
        self.max_retries = max_retries
        self.initial_delay = initial_delay
        self.max_delay = max_delay
        self.exponential_base = exponential_base
        self.exceptions = exceptions
        
        self.attempt = 0
        self.last_exception = None
    
    def __iter__(self):
        """Return iterator for retry loop."""
        return self
    
    def __next__(self) -> int:
        """
        Get next retry attempt.
        
        Returns:
            Current attempt number (0-indexed)
        
        Raises:
            StopIteration: When max retries exceeded
        """
        if self.attempt > self.max_retries:
            raise StopIteration
        
        # Wait before retry (except first attempt)
        if self.attempt > 0:
            delay = min(
                self.initial_delay * (self.exponential_base ** (self.attempt - 1)),
                self.max_delay
            )
            logger.debug(f"Waiting {delay:.2f}s before retry {self.attempt + 1}")
            time.sleep(delay)
        
        current_attempt = self.attempt
        self.attempt += 1
        return current_attempt
    
    def should_retry(self, exception: Exception) -> bool:
        """
        Check if exception should trigger a retry.
        
        Args:
            exception: Exception that occurred
        
        Returns:
            True if should retry, False otherwise
        """
        self.last_exception = exception
        
        # Check if exception type is retryable
        if not isinstance(exception, self.exceptions):
            logger.debug(f"Exception {type(exception).__name__} not in retry list")
            return False
        
        # Check if we have retries left
        if self.attempt > self.max_retries:
            logger.debug(f"Max retries ({self.max_retries}) exceeded")
            return False
        
        logger.warning(
            f"Retry {self.attempt}/{self.max_retries} for exception: {exception}"
        )
        return True


# Example usage
if __name__ == '__main__':
    import requests
    
    # Setup logging
    logging.basicConfig(level=logging.DEBUG)
    
    # Example 1: Decorator usage
    print("Example 1: Decorator with retry")
    
    @retry_with_backoff(max_retries=3, initial_delay=0.5)
    def flaky_function(fail_count: int = 2):
        """Function that fails a few times before succeeding."""
        if not hasattr(flaky_function, 'attempts'):
            flaky_function.attempts = 0
        
        flaky_function.attempts += 1
        print(f"  Attempt {flaky_function.attempts}")
        
        if flaky_function.attempts <= fail_count:
            raise ValueError(f"Simulated failure {flaky_function.attempts}")
        
        return "Success!"
    
    try:
        result = flaky_function(fail_count=2)
        print(f"Result: {result}")
    except Exception as e:
        print(f"Failed: {e}")
    
    # Example 2: Context manager usage
    print("\nExample 2: Context manager with retry")
    
    retry = RetryContext(max_retries=3, initial_delay=0.5)
    for attempt in retry:
        try:
            print(f"  Attempt {attempt + 1}")
            if attempt < 2:
                raise ValueError(f"Simulated failure {attempt + 1}")
            print("  Success!")
            break
        except Exception as e:
            if not retry.should_retry(e):
                print(f"  Failed permanently: {e}")
                raise