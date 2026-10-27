"""
Go Module Proxy API fetcher for Go module metadata.

Features:
- No authentication required
- No rate limits
- Version list from proxy
- Module metadata
- go.mod file parsing
"""

import logging
from typing import List, Dict, Any, Optional
from datetime import datetime
import re

import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent.parent))

from fetchers.base_fetcher import BaseFetcher, FetcherError, APIError
from utils.parsing import safe_json_parse, ParsingError


logger = logging.getLogger(__name__)


class GoFetcher(BaseFetcher):
    """
    Fetch data from Go module proxy.
    
    Endpoints (using proxy.golang.org):
    - GET /{module}/@v/list - List of versions
    - GET /{module}/@v/{version}.info - Version metadata
    - GET /{module}/@v/{version}.mod - go.mod file
    - GET /{module}/@latest - Latest version info
    
    Rate limits:
    - No official rate limit
    - Self-imposed limit: 100 requests/minute
    
    Example:
        >>> fetcher = GoFetcher()
        >>> versions = fetcher.fetch_versions("github.com/gin-gonic/gin")
        >>> metadata = fetcher.fetch_metadata("github.com/gin-gonic/gin")
    """
    
    def __init__(self, proxy_url: str = "https://proxy.golang.org"):
        """
        Initialize Go module fetcher.
        
        Args:
            proxy_url: Go module proxy URL (default: proxy.golang.org)
        """
        super().__init__(
            base_url=proxy_url,
            rate_limit=100,  # Self-imposed limit
            rate_period=60,  # 1 minute
            timeout=30
        )
        
        self.logger.info(
            f"Initialized Go fetcher using proxy: {proxy_url} "
            f"(100 req/min self-imposed limit)"
        )
    
    def encode_module_path(self, module_path: str) -> str:
        """
        Encode module path for Go proxy API.
        
        Go proxy requires uppercase letters to be encoded as !lowercase.
        
        Args:
            module_path: Module path (e.g., "github.com/Gin-Gonic/gin")
        
        Returns:
            Encoded path (e.g., "github.com/!gin-!gonic/gin")
        
        Example:
            >>> encoded = fetcher.encode_module_path("github.com/Gin-Gonic/gin")
            >>> # Returns: "github.com/!gin-!gonic/gin"
        """
        # Replace uppercase letters with !lowercase
        encoded = ''
        for char in module_path:
            if char.isupper():
                encoded += '!' + char.lower()
            else:
                encoded += char
        return encoded
    
    def fetch_version_list(self, module_path: str) -> List[str]:
        """
        Fetch list of all versions for a module.
        
        Args:
            module_path: Module path (e.g., "github.com/gin-gonic/gin")
        
        Returns:
            List of version strings
        
        Raises:
            FetcherError: If module not found or API error
        
        Example:
            >>> versions = fetcher.fetch_version_list("github.com/gin-gonic/gin")
            >>> # Returns: ["v1.9.1", "v1.9.0", "v1.8.2", ...]
        """
        encoded_path = self.encode_module_path(module_path)
        endpoint = f'/{encoded_path}/@v/list'
        
        try:
            response = self._get(endpoint)
            # Response is plain text, one version per line
            versions_text = response.text.strip()
            
            if not versions_text:
                self.logger.warning(f"No versions found for module: {module_path}")
                return []
            
            versions = [v.strip() for v in versions_text.split('\n') if v.strip()]
            
            self.logger.info(
                f"Fetched {len(versions)} versions for {module_path}"
            )
            return versions
        
        except APIError as e:
            if '404' in str(e) or '410' in str(e):
                raise FetcherError(f"Module not found: {module_path}")
            raise
    
    def fetch_version_info(
        self,
        module_path: str,
        version: str
    ) -> Dict[str, Any]:
        """
        Fetch metadata for a specific version.
        
        Args:
            module_path: Module path
            version: Version string (e.g., "v1.9.1")
        
        Returns:
            Dictionary with version info:
            {
                'Version': 'v1.9.1',
                'Time': '2023-09-21T02:50:04Z'
            }
        
        Example:
            >>> info = fetcher.fetch_version_info(
            ...     "github.com/gin-gonic/gin",
            ...     "v1.9.1"
            ... )
        """
        encoded_path = self.encode_module_path(module_path)
        endpoint = f'/{encoded_path}/@v/{version}.info'
        
        try:
            response = self._get(endpoint)
            data = safe_json_parse(response, max_size_mb=10)
            
            self.logger.info(
                f"Fetched version info for {module_path} {version}"
            )
            return data
        
        except APIError as e:
            if '404' in str(e) or '410' in str(e):
                raise FetcherError(
                    f"Version not found: {module_path} {version}"
                )
            raise
    
    def fetch_go_mod(self, module_path: str, version: str) -> str:
        """
        Fetch go.mod file for a specific version.
        
        Args:
            module_path: Module path
            version: Version string
        
        Returns:
            Contents of go.mod file
        
        Example:
            >>> go_mod = fetcher.fetch_go_mod(
            ...     "github.com/gin-gonic/gin",
            ...     "v1.9.1"
            ... )
        """
        encoded_path = self.encode_module_path(module_path)
        endpoint = f'/{encoded_path}/@v/{version}.mod'
        
        try:
            response = self._get(endpoint)
            go_mod_content = response.text
            
            self.logger.info(
                f"Fetched go.mod for {module_path} {version}"
            )
            return go_mod_content
        
        except APIError as e:
            if '404' in str(e) or '410' in str(e):
                raise FetcherError(
                    f"go.mod not found: {module_path} {version}"
                )
            raise
    
    def fetch_latest_info(self, module_path: str) -> Dict[str, Any]:
        """
        Fetch info for the latest version.
        
        Args:
            module_path: Module path
        
        Returns:
            Dictionary with latest version info
        
        Example:
            >>> info = fetcher.fetch_latest_info("github.com/gin-gonic/gin")
        """
        encoded_path = self.encode_module_path(module_path)
        endpoint = f'/{encoded_path}/@latest'
        
        try:
            response = self._get(endpoint)
            data = safe_json_parse(response, max_size_mb=10)
            
            self.logger.info(f"Fetched latest info for {module_path}")
            return data
        
        except APIError as e:
            if '404' in str(e) or '410' in str(e):
                raise FetcherError(f"Module not found: {module_path}")
            raise
    
    def parse_go_mod(self, go_mod_content: str) -> Dict[str, Any]:
        """
        Parse go.mod file content.
        
        Args:
            go_mod_content: Contents of go.mod file
        
        Returns:
            Dictionary with parsed information:
            {
                'module': 'github.com/gin-gonic/gin',
                'go_version': '1.20',
                'require': [
                    {'path': 'github.com/...', 'version': 'v1.2.3'},
                    ...
                ],
                'replace': [...],
                'exclude': [...]
            }
        
        Example:
            >>> go_mod = fetcher.fetch_go_mod("github.com/gin-gonic/gin", "v1.9.1")
            >>> parsed = fetcher.parse_go_mod(go_mod)
        """
        parsed = {
            'module': None,
            'go_version': None,
            'require': [],
            'replace': [],
            'exclude': [],
        }
        
        # Parse module name
        module_match = re.search(r'module\s+(\S+)', go_mod_content)
        if module_match:
            parsed['module'] = module_match.group(1)
        
        # Parse Go version
        go_match = re.search(r'go\s+(\d+\.\d+)', go_mod_content)
        if go_match:
            parsed['go_version'] = go_match.group(1)
        
        # Parse require block
        require_block = re.search(
            r'require\s*\((.*?)\)',
            go_mod_content,
            re.DOTALL
        )
        if require_block:
            for line in require_block.group(1).split('\n'):
                line = line.strip()
                if line and not line.startswith('//'):
                    parts = line.split()
                    if len(parts) >= 2:
                        parsed['require'].append({
                            'path': parts[0],
                            'version': parts[1]
                        })
        
        return parsed
    
    # Implement abstract methods from BaseFetcher
    
    def fetch_versions(self, package_name: str, **kwargs) -> List[Dict[str, Any]]:
        """
        Fetch all versions for a Go module.
        
        Args:
            package_name: Module path (e.g., "github.com/gin-gonic/gin")
            **kwargs: Additional options (not used)
        
        Returns:
            List of version dictionaries:
            [
                {
                    'version': 'v1.9.1',
                    'time': '2023-09-21T02:50:04Z'
                },
                ...
            ]
        
        Example:
            >>> versions = fetcher.fetch_versions("github.com/gin-gonic/gin")
        """
        try:
            version_list = self.fetch_version_list(package_name)
        except FetcherError:
            self.logger.warning(f"Module not found: {package_name}")
            return []
        
        # Fetch info for each version
        versions = []
        for version_str in version_list:
            try:
                info = self.fetch_version_info(package_name, version_str)
                versions.append({
                    'version': info.get('Version', version_str),
                    'time': info.get('Time'),
                })
            except FetcherError as e:
                self.logger.warning(
                    f"Could not fetch info for {package_name} {version_str}: {e}"
                )
                # Add version without timestamp
                versions.append({
                    'version': version_str,
                    'time': None,
                })
        
        # Sort by time (newest first)
        versions.sort(
            key=lambda x: x['time'] or '',
            reverse=True
        )
        
        self.logger.info(
            f"Fetched {len(versions)} versions for {package_name}"
        )
        return versions
    
    def fetch_metadata(self, package_name: str, **kwargs) -> Dict[str, Any]:
        """
        Fetch module metadata.
        
        Args:
            package_name: Module path
            **kwargs: Additional options (not used)
        
        Returns:
            Dictionary with module metadata:
            {
                'module': 'github.com/gin-gonic/gin',
                'latest_version': 'v1.9.1',
                'latest_time': '2023-09-21T02:50:04Z',
                'go_version': '1.20',
                'dependencies': [...]
            }
        
        Example:
            >>> metadata = fetcher.fetch_metadata("github.com/gin-gonic/gin")
        """
        try:
            # Get latest version info
            latest_info = self.fetch_latest_info(package_name)
            latest_version = latest_info.get('Version')
            
            # Get go.mod for latest version
            go_mod = self.fetch_go_mod(package_name, latest_version)
            parsed_mod = self.parse_go_mod(go_mod)
            
            metadata = {
                'module': package_name,
                'latest_version': latest_version,
                'latest_time': latest_info.get('Time'),
                'go_version': parsed_mod.get('go_version'),
                'dependencies': parsed_mod.get('require', []),
                'replacements': parsed_mod.get('replace', []),
                'exclusions': parsed_mod.get('exclude', []),
            }
            
            self.logger.info(f"Fetched metadata for {package_name}")
            return metadata
        
        except FetcherError:
            self.logger.warning(f"Module not found: {package_name}")
            return {}
    
    def get_latest_version(self, module_path: str) -> Optional[str]:
        """
        Get the latest version of a module.
        
        Args:
            module_path: Module path
        
        Returns:
            Latest version string or None if not found
        
        Example:
            >>> version = fetcher.get_latest_version("github.com/gin-gonic/gin")
            >>> # Returns: "v1.9.1"
        """
        try:
            info = self.fetch_latest_info(module_path)
            return info.get('Version')
        except FetcherError:
            return None


# Example usage
if __name__ == '__main__':
    import logging
    logging.basicConfig(level=logging.INFO)
    
    # Initialize fetcher
    fetcher = GoFetcher()
    
    # Example module
    module = "github.com/gin-gonic/gin"
    
    # Example 1: Fetch versions
    print(f"\n=== Example 1: Fetch versions for {module} ===")
    versions = fetcher.fetch_versions(module)
    print(f"Found {len(versions)} versions")
    for v in versions[:5]:
        print(f"  {v['version']} - {v['time']}")
    
    # Example 2: Fetch metadata
    print(f"\n=== Example 2: Fetch metadata for {module} ===")
    metadata = fetcher.fetch_metadata(module)
    print(f"  Module: {metadata.get('module')}")
    print(f"  Latest: {metadata.get('latest_version')}")
    print(f"  Go version: {metadata.get('go_version')}")
    print(f"  Dependencies: {len(metadata.get('dependencies', []))}")
    
    # Example 3: Get latest version
    print(f"\n=== Example 3: Get latest version ===")
    latest = fetcher.get_latest_version(module)
    print(f"  Latest version: {latest}")
    
    # Example 4: Fetch go.mod
    print(f"\n=== Example 4: Fetch go.mod ===")
    if latest:
        go_mod = fetcher.fetch_go_mod(module, latest)
        print(f"  go.mod content ({len(go_mod)} bytes):")
        print("  " + "\n  ".join(go_mod.split('\n')[:10]))
        print("  ...")
    
    # Show rate limit stats
    print("\n=== Rate limit stats ===")
    stats = fetcher.get_rate_limit_stats()
    print(f"  Available calls: {stats['available_calls']}/{stats['max_calls']}")
    print(f"  Utilization: {stats['utilization']:.1%}")
    
    fetcher.close()