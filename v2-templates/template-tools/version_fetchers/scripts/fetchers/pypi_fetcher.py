"""
PyPI API fetcher for Python package metadata.

Features:
- No authentication required
- No official rate limits (be respectful)
- Version history with upload dates
- Package metadata
- Yanked version detection
"""

import logging
from typing import List, Dict, Any, Optional
from datetime import datetime

import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent.parent))

from fetchers.base_fetcher import BaseFetcher, FetcherError, APIError
from utils.parsing import safe_json_parse, ParsingError


logger = logging.getLogger(__name__)


class PyPIFetcher(BaseFetcher):
    """
    Fetch data from PyPI (Python Package Index) API.
    
    Endpoints:
    - GET https://pypi.org/pypi/{package}/json - Package metadata and all versions
    - GET https://pypi.org/pypi/{package}/{version}/json - Specific version
    
    Rate limits:
    - No official rate limit, but be respectful
    - Self-imposed limit: 100 requests/minute
    
    Example:
        >>> fetcher = PyPIFetcher()
        >>> versions = fetcher.fetch_versions("numpy")
        >>> metadata = fetcher.fetch_metadata("numpy")
    """
    
    def __init__(self):
        """Initialize PyPI fetcher."""
        super().__init__(
            base_url='https://pypi.org',
            rate_limit=100,  # Self-imposed limit
            rate_period=60,  # 1 minute
            timeout=30
        )
        
        self.logger.info("Initialized PyPI fetcher (100 req/min self-imposed limit)")
    
    def fetch_package_data(self, package_name: str) -> Dict[str, Any]:
        """
        Fetch complete package data from PyPI.
        
        Args:
            package_name: Package name (case-insensitive)
        
        Returns:
            Complete package data including all versions
        
        Raises:
            FetcherError: If package not found or API error
        
        Example:
            >>> data = fetcher.fetch_package_data("numpy")
        """
        endpoint = f'/pypi/{package_name}/json'
        
        try:
            response = self._get(endpoint)
            data = safe_json_parse(response, max_size_mb=10)
            
            self.logger.info(f"Fetched package data for {package_name}")
            return data
        
        except ParsingError as e:
            raise FetcherError(f"Failed to parse PyPI response: {e}")
        except APIError as e:
            if '404' in str(e):
                raise FetcherError(f"Package not found on PyPI: {package_name}")
            raise
    
    def fetch_versions(self, package_name: str, **kwargs) -> List[Dict[str, Any]]:
        """
        Fetch all versions for a package.
        
        Args:
            package_name: Package name
            **kwargs: Additional options (not used)
        
        Returns:
            List of version dictionaries:
            [
                {
                    'version': '1.26.3',
                    'upload_date': '2024-01-15T02:30:00Z',
                    'yanked': False,
                    'yanked_reason': None
                },
                ...
            ]
        
        Example:
            >>> versions = fetcher.fetch_versions("numpy")
        """
        try:
            data = self.fetch_package_data(package_name)
        except FetcherError:
            self.logger.warning(f"Package not found on PyPI: {package_name}")
            return []
        
        # Extract version information
        versions = []
        releases = data.get('releases', {})
        
        for version, release_files in releases.items():
            if not release_files:
                # Skip versions with no files
                continue
            
            # Get upload date from first file
            first_file = release_files[0]
            upload_date = first_file.get('upload_time_iso_8601')
            
            # Check if yanked
            yanked = first_file.get('yanked', False)
            yanked_reason = first_file.get('yanked_reason')
            
            version_dict = {
                'version': version,
                'upload_date': upload_date,
                'yanked': yanked,
                'yanked_reason': yanked_reason,
            }
            versions.append(version_dict)
        
        # Sort by upload date (newest first)
        versions.sort(
            key=lambda x: x['upload_date'] or '',
            reverse=True
        )
        
        self.logger.info(
            f"Fetched {len(versions)} versions for {package_name} from PyPI"
        )
        return versions
    
    def fetch_metadata(self, package_name: str, **kwargs) -> Dict[str, Any]:
        """
        Fetch package metadata.
        
        Args:
            package_name: Package name
            **kwargs: Additional options (not used)
        
        Returns:
            Dictionary with package metadata:
            {
                'name': 'numpy',
                'version': '1.26.3',  # Latest version
                'summary': 'Fundamental package for array computing in Python',
                'description': '...',
                'home_page': 'https://numpy.org',
                'project_url': 'https://pypi.org/project/numpy/',
                'package_url': 'https://pypi.org/pypi/numpy/json',
                'author': 'Travis E. Oliphant et al.',
                'author_email': '...',
                'license': 'BSD-3-Clause',
                'keywords': ['array', 'scientific', 'computing'],
                'classifiers': ['Development Status :: 5 - Production/Stable', ...],
                'requires_python': '>=3.9',
                'project_urls': {
                    'Homepage': 'https://numpy.org',
                    'Source': 'https://github.com/numpy/numpy',
                    'Bug Tracker': 'https://github.com/numpy/numpy/issues'
                }
            }
        
        Example:
            >>> metadata = fetcher.fetch_metadata("numpy")
        """
        try:
            data = self.fetch_package_data(package_name)
        except FetcherError:
            self.logger.warning(f"Package not found on PyPI: {package_name}")
            return {}
        
        # Extract info section
        info = data.get('info', {})
        
        # Build metadata dictionary
        metadata = {
            'name': info.get('name'),
            'version': info.get('version'),
            'summary': info.get('summary'),
            'description': info.get('description'),
            'home_page': info.get('home_page'),
            'project_url': info.get('project_url'),
            'package_url': info.get('package_url'),
            'author': info.get('author'),
            'author_email': info.get('author_email'),
            'maintainer': info.get('maintainer'),
            'maintainer_email': info.get('maintainer_email'),
            'license': info.get('license'),
            'keywords': info.get('keywords', '').split(',') if info.get('keywords') else [],
            'classifiers': info.get('classifiers', []),
            'requires_python': info.get('requires_python'),
            'requires_dist': info.get('requires_dist', []),
            'project_urls': info.get('project_urls', {}),
            'download_url': info.get('download_url'),
            'downloads': info.get('downloads', {}),
        }
        
        self.logger.info(f"Fetched metadata for {package_name} from PyPI")
        return metadata
    
    def fetch_version_metadata(
        self,
        package_name: str,
        version: str
    ) -> Dict[str, Any]:
        """
        Fetch metadata for a specific version.
        
        Args:
            package_name: Package name
            version: Version string
        
        Returns:
            Dictionary with version-specific metadata
        
        Example:
            >>> metadata = fetcher.fetch_version_metadata("numpy", "1.26.3")
        """
        endpoint = f'/pypi/{package_name}/{version}/json'
        
        try:
            response = self._get(endpoint)
            data = response.json()
            
            info = data.get('info', {})
            
            metadata = {
                'name': info.get('name'),
                'version': info.get('version'),
                'summary': info.get('summary'),
                'license': info.get('license'),
                'requires_python': info.get('requires_python'),
                'upload_date': None,  # Will be in urls section
                'yanked': False,
                'yanked_reason': None,
            }
            
            # Get upload date and yanked status from first file
            urls = data.get('urls', [])
            if urls:
                first_file = urls[0]
                metadata['upload_date'] = first_file.get('upload_time_iso_8601')
                metadata['yanked'] = first_file.get('yanked', False)
                metadata['yanked_reason'] = first_file.get('yanked_reason')
            
            self.logger.info(
                f"Fetched metadata for {package_name} {version} from PyPI"
            )
            return metadata
        
        except APIError as e:
            if '404' in str(e):
                raise FetcherError(
                    f"Version not found on PyPI: {package_name} {version}"
                )
            raise
    
    def get_latest_version(self, package_name: str) -> Optional[str]:
        """
        Get the latest version of a package.
        
        Args:
            package_name: Package name
        
        Returns:
            Latest version string or None if not found
        
        Example:
            >>> version = fetcher.get_latest_version("numpy")
            >>> # Returns: "1.26.3"
        """
        try:
            data = self.fetch_package_data(package_name)
            return data.get('info', {}).get('version')
        except FetcherError:
            return None
    
    def search_packages(self, query: str, max_results: int = 20) -> List[Dict[str, Any]]:
        """
        Search for packages on PyPI.
        
        Note: PyPI's search API is limited and may not return all results.
        
        Args:
            query: Search query
            max_results: Maximum number of results (default: 20)
        
        Returns:
            List of package dictionaries
        
        Example:
            >>> results = fetcher.search_packages("numpy")
        """
        # Note: PyPI's XML-RPC search API is deprecated
        # This is a placeholder for potential future implementation
        # using alternative search methods
        
        self.logger.warning(
            "PyPI search API is deprecated. "
            "Use direct package name lookup instead."
        )
        return []


# Example usage
if __name__ == '__main__':
    import logging
    logging.basicConfig(level=logging.INFO)
    
    # Initialize fetcher
    fetcher = PyPIFetcher()
    
    # Example 1: Fetch versions
    print("\n=== Example 1: Fetch versions ===")
    versions = fetcher.fetch_versions("numpy")
    print(f"Found {len(versions)} versions")
    for v in versions[:5]:
        yanked_str = " (YANKED)" if v['yanked'] else ""
        print(f"  {v['version']} - {v['upload_date']}{yanked_str}")
    
    # Example 2: Fetch metadata
    print("\n=== Example 2: Fetch metadata ===")
    metadata = fetcher.fetch_metadata("numpy")
    print(f"  Name: {metadata.get('name')}")
    print(f"  Version: {metadata.get('version')}")
    print(f"  Summary: {metadata.get('summary')}")
    print(f"  License: {metadata.get('license')}")
    print(f"  Requires Python: {metadata.get('requires_python')}")
    
    # Example 3: Get latest version
    print("\n=== Example 3: Get latest version ===")
    latest = fetcher.get_latest_version("numpy")
    print(f"  Latest version: {latest}")
    
    # Example 4: Fetch specific version metadata
    print("\n=== Example 4: Fetch specific version metadata ===")
    version_meta = fetcher.fetch_version_metadata("numpy", latest)
    print(f"  Version: {version_meta.get('version')}")
    print(f"  Upload date: {version_meta.get('upload_date')}")
    print(f"  Yanked: {version_meta.get('yanked')}")
    
    # Show rate limit stats
    print("\n=== Rate limit stats ===")
    stats = fetcher.get_rate_limit_stats()
    print(f"  Available calls: {stats['available_calls']}/{stats['max_calls']}")
    print(f"  Utilization: {stats['utilization']:.1%}")
    
    fetcher.close()