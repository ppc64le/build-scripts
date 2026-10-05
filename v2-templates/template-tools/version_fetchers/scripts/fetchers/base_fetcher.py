"""
Base fetcher class for all external data sources.

Provides common functionality:
- HTTP session management
- Rate limiting
- Retry logic with exponential backoff
- Request/response logging
- Error handling
"""

import logging
import time
from typing import Optional, Dict, Any, List
from abc import ABC, abstractmethod
import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

import sys
from pathlib import Path
# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent))

from utils.rate_limiter import RateLimiter
from utils.retry import retry_with_backoff


logger = logging.getLogger(__name__)


class FetcherError(Exception):
    """Base exception for fetcher errors."""
    pass


class RateLimitError(FetcherError):
    """Raised when rate limit is exceeded."""
    pass


class APIError(FetcherError):
    """Raised when API returns an error."""
    pass


class BaseFetcher(ABC):
    """
    Abstract base class for all data fetchers.
    
    Provides common functionality for making HTTP requests with:
    - Automatic rate limiting
    - Retry logic with exponential backoff
    - Request/response logging
    - Session management
    
    Subclasses must implement:
    - fetch_versions(): Fetch all versions for a package
    - fetch_metadata(): Fetch package metadata
    
    Example:
        >>> class MyFetcher(BaseFetcher):
        ...     def __init__(self):
        ...         super().__init__(
        ...             base_url='https://api.example.com',
        ...             rate_limit=100,
        ...             rate_period=60
        ...         )
        ...     
        ...     def fetch_versions(self, package_name: str) -> List[dict]:
        ...         response = self._get(f'/packages/{package_name}/versions')
        ...         return response.json()
    """
    
    def __init__(
        self,
        base_url: str,
        rate_limit: int,
        rate_period: float,
        timeout: int = 30,
        max_retries: int = 3,
        headers: Optional[Dict[str, str]] = None,
    ):
        """
        Initialize base fetcher.
        
        Args:
            base_url: Base URL for API (e.g., 'https://api.github.com')
            rate_limit: Maximum requests allowed
            rate_period: Time period in seconds for rate limit
            timeout: Request timeout in seconds (default: 30)
            max_retries: Maximum retry attempts (default: 3)
            headers: Additional HTTP headers (default: None)
        """
        self.base_url = base_url.rstrip('/')
        self.timeout = timeout
        self.max_retries = max_retries
        
        # Initialize rate limiter
        self.rate_limiter = RateLimiter(
            max_calls=rate_limit,
            period=rate_period
        )
        
        # Initialize HTTP session with retry strategy
        self.session = requests.Session()
        
        # Configure retry strategy for transient errors
        retry_strategy = Retry(
            total=max_retries,
            backoff_factor=1,
            status_forcelist=[429, 500, 502, 503, 504],
            allowed_methods=["HEAD", "GET", "OPTIONS"]
        )
        # Configure connection pooling for better performance
        adapter = HTTPAdapter(
            max_retries=retry_strategy,
            pool_connections=10,  # Number of connection pools to cache
            pool_maxsize=20,      # Max connections per pool
            pool_block=False      # Don't block when pool is full
        )
        self.session.mount("http://", adapter)
        self.session.mount("https://", adapter)
        
        # Set default headers
        self.session.headers.update({
            'User-Agent': 'PowerCore-Database-Migration/1.0',
            'Accept': 'application/json',
        })
        
        # Add custom headers
        if headers:
            self.session.headers.update(headers)
        
        self.logger = logging.getLogger(f"{__name__}.{self.__class__.__name__}")
        self.logger.info(
            f"Initialized {self.__class__.__name__} "
            f"(rate limit: {rate_limit}/{rate_period}s, timeout: {timeout}s)"
        )
    
    def _get(
        self,
        endpoint: str,
        params: Optional[Dict[str, Any]] = None,
        headers: Optional[Dict[str, str]] = None,
        full_url: bool = False,
    ) -> requests.Response:
        """
        Make a GET request with rate limiting and retry logic.
        
        Args:
            endpoint: API endpoint (e.g., '/repos/owner/repo/tags')
            params: Query parameters (default: None)
            headers: Additional headers for this request (default: None)
            full_url: If True, endpoint is treated as full URL (default: False)
        
        Returns:
            Response object
        
        Raises:
            RateLimitError: If rate limit timeout exceeded
            APIError: If API returns error status
            FetcherError: For other errors
        """
        # Construct URL
        if full_url:
            url = endpoint
        else:
            url = f"{self.base_url}{endpoint}"
        
        # Acquire rate limit permission with 5-minute timeout to prevent infinite hangs
        if not self.rate_limiter.acquire(timeout=300):
            raise RateLimitError(
                f"Rate limit timeout exceeded after 5 minutes. "
                f"Consider increasing rate limits or using authentication."
            )
        
        try:
            # Log request
            self.logger.debug(f"GET {url} (params: {params})")
            
            # Make request
            response = self.session.get(
                url,
                params=params,
                headers=headers,
                timeout=self.timeout
            )
            
            # Log response
            self.logger.debug(
                f"Response: {response.status_code} "
                f"({len(response.content)} bytes)"
            )
            
            # Check for errors
            if response.status_code == 429:
                # Rate limit exceeded
                retry_after = response.headers.get('Retry-After', '60')
                raise RateLimitError(
                    f"Rate limit exceeded. Retry after {retry_after}s"
                )
            
            if response.status_code >= 400:
                raise APIError(
                    f"API error {response.status_code}: {response.text[:200]}"
                )
            
            response.raise_for_status()
            return response
        
        except requests.exceptions.Timeout:
            raise FetcherError(f"Request timeout after {self.timeout}s: {url}")
        
        except requests.exceptions.RequestException as e:
            raise FetcherError(f"Request failed: {e}")
        
        finally:
            # Release rate limit (no-op for our implementation)
            self.rate_limiter.release()
    
    def _get_paginated(
        self,
        endpoint: str,
        params: Optional[Dict[str, Any]] = None,
        max_pages: Optional[int] = None,
        page_param: str = 'page',
        per_page_param: str = 'per_page',
        per_page: int = 100,
    ) -> List[Dict[str, Any]]:
        """
        Fetch all pages of a paginated API endpoint.
        
        Args:
            endpoint: API endpoint
            params: Query parameters (default: None)
            max_pages: Maximum pages to fetch (default: None = all)
            page_param: Name of page parameter (default: 'page')
            per_page_param: Name of per_page parameter (default: 'per_page')
            per_page: Items per page (default: 100)
        
        Returns:
            List of all items from all pages
        
        Example:
            >>> items = self._get_paginated('/repos/owner/repo/tags', per_page=100)
        """
        all_items = []
        page = 1
        
        if params is None:
            params = {}
        
        params[per_page_param] = per_page
        
        while True:
            # Check max pages limit
            if max_pages and page > max_pages:
                self.logger.info(f"Reached max pages limit: {max_pages}")
                break
            
            # Fetch page
            params[page_param] = page
            response = self._get(endpoint, params=params)
            items = response.json()
            
            # Check if we got any items
            if not items:
                self.logger.debug(f"No more items at page {page}")
                break
            
            all_items.extend(items)
            self.logger.debug(
                f"Fetched page {page}: {len(items)} items "
                f"(total: {len(all_items)})"
            )
            
            # Check if there are more pages
            # Most APIs return fewer items than requested on last page
            if len(items) < per_page:
                self.logger.debug("Last page reached (fewer items than requested)")
                break
            
            page += 1
        
        self.logger.info(
            f"Fetched {len(all_items)} items across {page} pages from {endpoint}"
        )
        return all_items
    
    def get_rate_limit_stats(self) -> Dict[str, Any]:
        """
        Get current rate limit statistics.
        
        Returns:
            Dictionary with rate limit stats
        
        Example:
            >>> stats = fetcher.get_rate_limit_stats()
            >>> print(f"Available: {stats['available_calls']}")
        """
        return self.rate_limiter.get_stats()
    
    @abstractmethod
    def fetch_versions(self, package_name: str, **kwargs) -> List[Dict[str, Any]]:
        """
        Fetch all versions for a package.
        
        Must be implemented by subclasses.
        
        Args:
            package_name: Name of the package
            **kwargs: Additional fetcher-specific arguments
        
        Returns:
            List of version dictionaries
        
        Example:
            >>> versions = fetcher.fetch_versions('numpy')
            >>> # Returns: [{'version': '1.26.3', 'date': '2024-01-15'}, ...]
        """
        pass
    
    @abstractmethod
    def fetch_metadata(self, package_name: str, **kwargs) -> Dict[str, Any]:
        """
        Fetch package metadata.
        
        Must be implemented by subclasses.
        
        Args:
            package_name: Name of the package
            **kwargs: Additional fetcher-specific arguments
        
        Returns:
            Dictionary with package metadata
        
        Example:
            >>> metadata = fetcher.fetch_metadata('numpy')
            >>> # Returns: {'name': 'numpy', 'description': '...', ...}
        """
        pass
    
    def close(self):
        """Close the HTTP session."""
        self.session.close()
        self.logger.debug("Closed HTTP session")
    
    def __enter__(self):
        """Context manager entry."""
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        """Context manager exit."""
        self.close()
        return False


# Example usage
if __name__ == '__main__':
    # This is just for demonstration
    # Real fetchers will inherit from BaseFetcher
    
    class ExampleFetcher(BaseFetcher):
        """Example fetcher implementation."""
        
        def __init__(self):
            super().__init__(
                base_url='https://api.github.com',
                rate_limit=60,  # 60 requests per hour (unauthenticated)
                rate_period=3600
            )
        
        def fetch_versions(self, package_name: str, **kwargs) -> List[Dict[str, Any]]:
            """Fetch versions (example)."""
            # This would make actual API calls
            return [
                {'version': '1.0.0', 'date': '2024-01-01'},
                {'version': '1.0.1', 'date': '2024-01-15'},
            ]
        
        def fetch_metadata(self, package_name: str, **kwargs) -> Dict[str, Any]:
            """Fetch metadata (example)."""
            return {
                'name': package_name,
                'description': 'Example package',
            }
    
    # Test the example fetcher
    with ExampleFetcher() as fetcher:
        print("Rate limit stats:", fetcher.get_rate_limit_stats())
        versions = fetcher.fetch_versions('test-package')
        print("Versions:", versions)