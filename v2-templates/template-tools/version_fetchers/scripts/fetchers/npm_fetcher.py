"""
npm Registry API fetcher for Node package metadata.

Features:
- No authentication required
- No official rate limits (be respectful)
- Version history with publish dates
- Package metadata
- Deprecated version detection
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


class NpmFetcher(BaseFetcher):
    """
    Fetch data from npm registry API.
    
    Endpoints:
    - GET https://registry.npmjs.org/{package} - Package metadata and all versions
    - GET https://registry.npmjs.org/{package}/{version} - Specific version
    
    Rate limits:
    - No official rate limit, but be respectful
    - Self-imposed limit: 100 requests/minute
    
    Example:
        >>> fetcher = NpmFetcher()
        >>> versions = fetcher.fetch_versions("express")
        >>> metadata = fetcher.fetch_metadata("express")
    """
    
    def __init__(self):
        """Initialize npm fetcher."""
        super().__init__(
            base_url='https://registry.npmjs.org',
            rate_limit=100,  # Self-imposed limit
            rate_period=60,  # 1 minute
            timeout=30
        )
        
        self.logger.info("Initialized npm fetcher (100 req/min self-imposed limit)")
    
    def fetch_package_data(self, package_name: str) -> Dict[str, Any]:
        """
        Fetch complete package data from npm registry.
        
        Args:
            package_name: Package name (case-sensitive for scoped packages)
        
        Returns:
            Complete package data including all versions
        
        Raises:
            FetcherError: If package not found or API error
        
        Example:
            >>> data = fetcher.fetch_package_data("express")
            >>> data = fetcher.fetch_package_data("@types/node")  # Scoped package
        """
        # npm registry uses package name directly in URL
        # Scoped packages like @types/node are URL-encoded
        endpoint = f'/{package_name}'
        
        try:
            response = self._get(endpoint)
            data = safe_json_parse(response, max_size_mb=10)
            
            self.logger.info(f"Fetched package data for {package_name}")
            return data
        
        except ParsingError as e:
            raise FetcherError(f"Failed to parse npm response: {e}")
        except APIError as e:
            if '404' in str(e):
                raise FetcherError(f"Package not found on npm: {package_name}")
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
                    'version': '4.18.2',
                    'publish_date': '2022-10-08T23:48:22.239Z',
                    'deprecated': False,
                    'deprecation_message': None
                },
                ...
            ]
        
        Example:
            >>> versions = fetcher.fetch_versions("express")
        """
        try:
            data = self.fetch_package_data(package_name)
        except FetcherError:
            self.logger.warning(f"Package not found on npm: {package_name}")
            return []
        
        # Extract version information
        versions = []
        time_data = data.get('time', {})
        versions_data = data.get('versions', {})
        
        for version, version_info in versions_data.items():
            # Get publish date from time object
            publish_date = time_data.get(version)
            
            # Check if deprecated
            deprecated = 'deprecated' in version_info
            deprecation_message = version_info.get('deprecated') if deprecated else None
            
            version_dict = {
                'version': version,
                'publish_date': publish_date,
                'deprecated': deprecated,
                'deprecation_message': deprecation_message,
            }
            versions.append(version_dict)
        
        # Sort by publish date (newest first)
        versions.sort(
            key=lambda x: x['publish_date'] or '',
            reverse=True
        )
        
        self.logger.info(
            f"Fetched {len(versions)} versions for {package_name} from npm"
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
                'name': 'express',
                'version': '4.18.2',  # Latest version
                'description': 'Fast, unopinionated, minimalist web framework',
                'homepage': 'http://expressjs.com/',
                'repository': {
                    'type': 'git',
                    'url': 'git+https://github.com/expressjs/express.git'
                },
                'author': {'name': 'TJ Holowaychuk', 'email': '...'},
                'license': 'MIT',
                'keywords': ['express', 'framework', 'web', ...],
                'maintainers': [{'name': '...', 'email': '...'}],
                'dist-tags': {'latest': '4.18.2', 'next': '5.0.0-beta.1'},
                'created': '2010-12-29T19:38:25.450Z',
                'modified': '2022-10-08T23:48:24.516Z'
            }
        
        Example:
            >>> metadata = fetcher.fetch_metadata("express")
        """
        try:
            data = self.fetch_package_data(package_name)
        except FetcherError:
            self.logger.warning(f"Package not found on npm: {package_name}")
            return {}
        
        # Get latest version info
        dist_tags = data.get('dist-tags', {})
        latest_version = dist_tags.get('latest')
        latest_info = data.get('versions', {}).get(latest_version, {})
        
        # Build metadata dictionary
        metadata = {
            'name': data.get('name'),
            'version': latest_version,
            'description': data.get('description') or latest_info.get('description'),
            'homepage': data.get('homepage') or latest_info.get('homepage'),
            'repository': data.get('repository') or latest_info.get('repository'),
            'author': data.get('author') or latest_info.get('author'),
            'license': data.get('license') or latest_info.get('license'),
            'keywords': data.get('keywords', []) or latest_info.get('keywords', []),
            'maintainers': data.get('maintainers', []),
            'dist_tags': dist_tags,
            'created': data.get('time', {}).get('created'),
            'modified': data.get('time', {}).get('modified'),
            'readme': data.get('readme'),
        }
        
        self.logger.info(f"Fetched metadata for {package_name} from npm")
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
            >>> metadata = fetcher.fetch_version_metadata("express", "4.18.2")
        """
        endpoint = f'/{package_name}/{version}'
        
        try:
            response = self._get(endpoint)
            data = response.json()
            
            # Get publish date from package data
            package_data = self.fetch_package_data(package_name)
            publish_date = package_data.get('time', {}).get(version)
            
            metadata = {
                'name': data.get('name'),
                'version': data.get('version'),
                'description': data.get('description'),
                'homepage': data.get('homepage'),
                'repository': data.get('repository'),
                'author': data.get('author'),
                'license': data.get('license'),
                'keywords': data.get('keywords', []),
                'dependencies': data.get('dependencies', {}),
                'devDependencies': data.get('devDependencies', {}),
                'peerDependencies': data.get('peerDependencies', {}),
                'engines': data.get('engines', {}),
                'publish_date': publish_date,
                'deprecated': 'deprecated' in data,
                'deprecation_message': data.get('deprecated'),
            }
            
            self.logger.info(
                f"Fetched metadata for {package_name} {version} from npm"
            )
            return metadata
        
        except APIError as e:
            if '404' in str(e):
                raise FetcherError(
                    f"Version not found on npm: {package_name} {version}"
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
            >>> version = fetcher.get_latest_version("express")
            >>> # Returns: "4.18.2"
        """
        try:
            data = self.fetch_package_data(package_name)
            return data.get('dist-tags', {}).get('latest')
        except FetcherError:
            return None
    
    def get_dist_tags(self, package_name: str) -> Dict[str, str]:
        """
        Get distribution tags for a package.
        
        Args:
            package_name: Package name
        
        Returns:
            Dictionary of tag names to versions
        
        Example:
            >>> tags = fetcher.get_dist_tags("express")
            >>> # Returns: {'latest': '4.18.2', 'next': '5.0.0-beta.1'}
        """
        try:
            data = self.fetch_package_data(package_name)
            return data.get('dist-tags', {})
        except FetcherError:
            return {}
    
    def search_packages(
        self,
        query: str,
        size: int = 20,
        from_: int = 0
    ) -> List[Dict[str, Any]]:
        """
        Search for packages on npm.
        
        Args:
            query: Search query
            size: Number of results to return (default: 20)
            from_: Offset for pagination (default: 0)
        
        Returns:
            List of package dictionaries
        
        Example:
            >>> results = fetcher.search_packages("express")
        """
        # Use npm search API
        endpoint = '/-/v1/search'
        params = {
            'text': query,
            'size': size,
            'from': from_
        }
        
        try:
            response = self._get(endpoint, params=params, full_url=False)
            data = response.json()
            
            packages = []
            for obj in data.get('objects', []):
                package = obj.get('package', {})
                packages.append({
                    'name': package.get('name'),
                    'version': package.get('version'),
                    'description': package.get('description'),
                    'keywords': package.get('keywords', []),
                    'author': package.get('author'),
                    'publisher': package.get('publisher'),
                    'maintainers': package.get('maintainers', []),
                    'links': package.get('links', {}),
                    'score': obj.get('score', {}),
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
    fetcher = NpmFetcher()
    
    # Example 1: Fetch versions
    print("\n=== Example 1: Fetch versions ===")
    versions = fetcher.fetch_versions("express")
    print(f"Found {len(versions)} versions")
    for v in versions[:5]:
        deprecated_str = " (DEPRECATED)" if v['deprecated'] else ""
        print(f"  {v['version']} - {v['publish_date']}{deprecated_str}")
    
    # Example 2: Fetch metadata
    print("\n=== Example 2: Fetch metadata ===")
    metadata = fetcher.fetch_metadata("express")
    print(f"  Name: {metadata.get('name')}")
    print(f"  Version: {metadata.get('version')}")
    print(f"  Description: {metadata.get('description')}")
    print(f"  License: {metadata.get('license')}")
    print(f"  Homepage: {metadata.get('homepage')}")
    
    # Example 3: Get latest version
    print("\n=== Example 3: Get latest version ===")
    latest = fetcher.get_latest_version("express")
    print(f"  Latest version: {latest}")
    
    # Example 4: Get dist tags
    print("\n=== Example 4: Get dist tags ===")
    tags = fetcher.get_dist_tags("express")
    for tag, version in tags.items():
        print(f"  {tag}: {version}")
    
    # Example 5: Search packages
    print("\n=== Example 5: Search packages ===")
    results = fetcher.search_packages("web framework", size=3)
    for pkg in results:
        print(f"  {pkg['name']} - {pkg['description'][:50]}...")
    
    # Show rate limit stats
    print("\n=== Rate limit stats ===")
    stats = fetcher.get_rate_limit_stats()
    print(f"  Available calls: {stats['available_calls']}/{stats['max_calls']}")
    print(f"  Utilization: {stats['utilization']:.1%}")
    
    fetcher.close()