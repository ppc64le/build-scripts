"""
Packagist API fetcher for PHP package metadata.

Features:
- No authentication required
- No official rate limits (be respectful)
- Version history with release dates
- Package metadata
- Composer package format (vendor/package)
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


class PackagistFetcher(BaseFetcher):
    """
    Fetch data from Packagist API.
    
    Endpoints:
    - GET https://repo.packagist.org/p2/{vendor}/{package}.json - Package metadata and all versions
    - GET https://packagist.org/packages/{vendor}/{package}.json - Alternative endpoint
    
    Rate limits:
    - No official rate limit, but be respectful
    - Self-imposed limit: 100 requests/minute
    
    Example:
        >>> fetcher = PackagistFetcher()
        >>> versions = fetcher.fetch_versions("symfony/console")
        >>> metadata = fetcher.fetch_metadata("symfony/console")
    """
    
    def __init__(self):
        """Initialize Packagist fetcher."""
        super().__init__(
            base_url='https://repo.packagist.org',
            rate_limit=100,  # Self-imposed limit
            rate_period=60,  # 1 minute
            timeout=30
        )
        
        self.logger.info("Initialized Packagist fetcher (100 req/min self-imposed limit)")
    
    def _normalize_package_name(self, package_name: str) -> str:
        """
        Normalize package name to vendor/package format.
        
        Args:
            package_name: Package name (may use __ or / as separator)
        
        Returns:
            Normalized package name with / separator
        
        Example:
            >>> _normalize_package_name("symfony__console")
            'symfony/console'
            >>> _normalize_package_name("symfony/console")
            'symfony/console'
        """
        # Replace double underscore with slash
        if '__' in package_name:
            package_name = package_name.replace('__', '/')
        
        return package_name.lower()
    
    def fetch_package_data(self, package_name: str) -> Dict[str, Any]:
        """
        Fetch complete package data from Packagist.
        
        Args:
            package_name: Package name in vendor/package or vendor__package format
        
        Returns:
            Complete package data including all versions
        
        Raises:
            FetcherError: If package not found or API error
        
        Example:
            >>> data = fetcher.fetch_package_data("symfony/console")
            >>> data = fetcher.fetch_package_data("symfony__console")  # Also works
        """
        # Normalize package name
        package_name = self._normalize_package_name(package_name)
        
        # Split into vendor and package
        if '/' not in package_name:
            raise FetcherError(f"Invalid package name format: {package_name}. Expected vendor/package")
        
        vendor, package = package_name.split('/', 1)
        
        # Use the p2 endpoint which provides all version data
        endpoint = f'/p2/{vendor}/{package}.json'
        
        try:
            response = self._get(endpoint)
            data = safe_json_parse(response, max_size_mb=10)
            
            self.logger.info(f"Fetched package data for {package_name}")
            return data
        
        except APIError as e:
            if '404' in str(e):
                raise FetcherError(f"Package not found on Packagist: {package_name}")
            raise
    
    def fetch_versions(self, package_name: str, **kwargs) -> List[Dict[str, Any]]:
        """
        Fetch all versions for a package.
        
        Args:
            package_name: Package name (vendor/package or vendor__package)
            **kwargs: Additional options (not used)
        
        Returns:
            List of version dictionaries:
            [
                {
                    'version': '6.3.0',
                    'release_date': '2023-05-29T14:27:40+00:00',
                    'type': 'library',
                    'license': ['MIT'],
                    'source': {'url': '...', 'type': 'git', 'reference': '...'}
                },
                ...
            ]
        
        Example:
            >>> versions = fetcher.fetch_versions("symfony/console")
        """
        try:
            data = self.fetch_package_data(package_name)
        except FetcherError:
            self.logger.warning(f"Package not found on Packagist: {package_name}")
            return []
        
        # Extract version information from packages
        versions = []
        packages = data.get('packages', {})
        
        # The package name in the response
        normalized_name = self._normalize_package_name(package_name)
        package_versions = packages.get(normalized_name, [])
        
        for version_data in package_versions:
            version_dict = {
                'version': version_data.get('version'),
                'version_normalized': version_data.get('version_normalized'),
                'release_date': version_data.get('time'),
                'type': version_data.get('type'),
                'license': version_data.get('license', []),
                'source': version_data.get('source', {}),
                'dist': version_data.get('dist', {}),
                'require': version_data.get('require', {}),
                'require_dev': version_data.get('require-dev', {}),
            }
            versions.append(version_dict)
        
        # Sort by release date (newest first)
        versions.sort(
            key=lambda x: x['release_date'] or '',
            reverse=True
        )
        
        self.logger.info(
            f"Fetched {len(versions)} versions for {package_name} from Packagist"
        )
        return versions
    
    def fetch_metadata(self, package_name: str, **kwargs) -> Dict[str, Any]:
        """
        Fetch package metadata.
        
        Args:
            package_name: Package name (vendor/package or vendor__package)
            **kwargs: Additional options (not used)
        
        Returns:
            Dictionary with package metadata:
            {
                'name': 'symfony/console',
                'description': 'Eases the creation of beautiful and testable command line interfaces',
                'type': 'library',
                'keywords': ['console', 'cli'],
                'homepage': 'https://symfony.com',
                'license': ['MIT'],
                'authors': [{'name': '...', 'email': '...'}],
                'support': {'source': '...', 'issues': '...'},
                'repository': 'https://github.com/symfony/console',
                'latest_version': '6.3.0',
                'versions_count': 150
            }
        
        Example:
            >>> metadata = fetcher.fetch_metadata("symfony/console")
        """
        try:
            data = self.fetch_package_data(package_name)
        except FetcherError:
            self.logger.warning(f"Package not found on Packagist: {package_name}")
            return {}
        
        # Get package versions
        normalized_name = self._normalize_package_name(package_name)
        packages = data.get('packages', {})
        package_versions = packages.get(normalized_name, [])
        
        if not package_versions:
            return {}
        
        # Get latest version (first in list after sorting)
        latest = package_versions[0]
        
        # Build metadata dictionary
        metadata = {
            'name': latest.get('name'),
            'description': latest.get('description'),
            'type': latest.get('type'),
            'keywords': latest.get('keywords', []),
            'homepage': latest.get('homepage'),
            'license': latest.get('license', []),
            'authors': latest.get('authors', []),
            'support': latest.get('support', {}),
            'funding': latest.get('funding', []),
            'source': latest.get('source', {}),
            'latest_version': latest.get('version'),
            'versions_count': len(package_versions),
            'require': latest.get('require', {}),
            'require_dev': latest.get('require-dev', {}),
            'suggest': latest.get('suggest', {}),
            'autoload': latest.get('autoload', {}),
        }
        
        # Extract repository URL from source
        source = latest.get('source', {})
        if source:
            metadata['repository'] = source.get('url')
        
        self.logger.info(f"Fetched metadata for {package_name} from Packagist")
        return metadata
    
    def get_latest_version(self, package_name: str) -> Optional[str]:
        """
        Get the latest version of a package.
        
        Args:
            package_name: Package name
        
        Returns:
            Latest version string or None if not found
        
        Example:
            >>> version = fetcher.get_latest_version("symfony/console")
            >>> # Returns: "6.3.0"
        """
        try:
            versions = self.fetch_versions(package_name)
            if versions:
                return versions[0]['version']
            return None
        except FetcherError:
            return None
    
    def search_packages(
        self,
        query: str,
        per_page: int = 15
    ) -> List[Dict[str, Any]]:
        """
        Search for packages on Packagist.
        
        Args:
            query: Search query
            per_page: Number of results per page (default: 15)
        
        Returns:
            List of package dictionaries
        
        Example:
            >>> results = fetcher.search_packages("symfony console")
        """
        # Use Packagist search API
        endpoint = 'https://packagist.org/search.json'
        params = {
            'q': query,
            'per_page': per_page
        }
        
        try:
            response = self._get(endpoint, params=params, full_url=True)
            data = safe_json_parse(response, max_size_mb=10)
            
            packages = []
            for result in data.get('results', []):
                packages.append({
                    'name': result.get('name'),
                    'description': result.get('description'),
                    'url': result.get('url'),
                    'repository': result.get('repository'),
                    'downloads': result.get('downloads'),
                    'favers': result.get('favers'),
                })
            
            self.logger.info(
                f"Found {len(packages)} packages for query: {query}"
            )
            return packages
        
        except APIError as e:
            self.logger.warning(f"Search failed: {e}")
            return []


# Example usage
if __name__ == '__main__':
    import logging
    logging.basicConfig(level=logging.INFO)
    
    # Initialize fetcher
    fetcher = PackagistFetcher()
    
    # Example 1: Fetch versions
    print("\n=== Example 1: Fetch versions ===")
    versions = fetcher.fetch_versions("symfony/console")
    print(f"Found {len(versions)} versions")
    for v in versions[:5]:
        print(f"  {v['version']} - {v['release_date']}")
    
    # Example 2: Fetch metadata
    print("\n=== Example 2: Fetch metadata ===")
    metadata = fetcher.fetch_metadata("symfony/console")
    print(f"  Name: {metadata.get('name')}")
    print(f"  Description: {metadata.get('description')}")
    print(f"  License: {metadata.get('license')}")
    print(f"  Homepage: {metadata.get('homepage')}")
    print(f"  Latest version: {metadata.get('latest_version')}")
    
    # Example 3: Get latest version
    print("\n=== Example 3: Get latest version ===")
    latest = fetcher.get_latest_version("symfony/console")
    print(f"  Latest version: {latest}")
    
    # Example 4: Search packages
    print("\n=== Example 4: Search packages ===")
    results = fetcher.search_packages("symfony", per_page=3)
    for pkg in results:
        print(f"  {pkg['name']} - {pkg['description'][:50]}...")
    
    # Example 5: Test with double underscore format
    print("\n=== Example 5: Double underscore format ===")
    versions = fetcher.fetch_versions("symfony__console")
    print(f"Found {len(versions)} versions for symfony__console")
    
    # Show rate limit stats
    print("\n=== Rate limit stats ===")
    stats = fetcher.get_rate_limit_stats()
    print(f"  Available calls: {stats['available_calls']}/{stats['max_calls']}")
    print(f"  Utilization: {stats['utilization']:.1%}")
    
    fetcher.close()