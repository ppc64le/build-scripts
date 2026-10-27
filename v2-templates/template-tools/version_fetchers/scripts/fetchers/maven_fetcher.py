"""
Maven Central API fetcher for Java artifact metadata.

Features:
- No authentication required
- No official rate limits (be respectful)
- Version history with release dates
- Artifact metadata from POM files
- Search functionality
"""

import logging
from typing import List, Dict, Any, Optional
from datetime import datetime
import xml.etree.ElementTree as ET

import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent.parent))

from fetchers.base_fetcher import BaseFetcher, FetcherError, APIError
from utils.parsing import safe_json_parse, ParsingError


logger = logging.getLogger(__name__)


class MavenFetcher(BaseFetcher):
    """
    Fetch data from Maven Central Repository.
    
    Endpoints:
    - GET https://search.maven.org/solrsearch/select - Search API
    - GET https://repo1.maven.org/maven2/{group}/{artifact}/maven-metadata.xml - Version list
    - GET https://repo1.maven.org/maven2/{group}/{artifact}/{version}/{artifact}-{version}.pom - POM file
    
    Rate limits:
    - No official rate limit, but be respectful
    - Self-imposed limit: 100 requests/minute
    
    Example:
        >>> fetcher = MavenFetcher()
        >>> versions = fetcher.fetch_versions("org.springframework.boot", "spring-boot-starter")
        >>> metadata = fetcher.fetch_metadata("org.springframework.boot", "spring-boot-starter")
    """
    
    def __init__(self):
        """Initialize Maven fetcher."""
        super().__init__(
            base_url='https://search.maven.org',
            rate_limit=100,  # Self-imposed limit
            rate_period=60,  # 1 minute
            timeout=30
        )
        
        # Maven repository base URL for direct artifact access
        self.repo_base_url = 'https://repo1.maven.org/maven2'
        
        self.logger.info(
            "Initialized Maven fetcher (100 req/min self-imposed limit)"
        )
    
    def group_to_path(self, group_id: str) -> str:
        """
        Convert Maven group ID to repository path.
        
        Args:
            group_id: Maven group ID (e.g., "org.springframework.boot")
        
        Returns:
            Repository path (e.g., "org/springframework/boot")
        
        Example:
            >>> path = fetcher.group_to_path("org.springframework.boot")
            >>> # Returns: "org/springframework/boot"
        """
        return group_id.replace('.', '/')
    
    def fetch_maven_metadata(
        self,
        group_id: str,
        artifact_id: str
    ) -> Dict[str, Any]:
        """
        Fetch maven-metadata.xml for an artifact.
        
        Args:
            group_id: Maven group ID
            artifact_id: Maven artifact ID
        
        Returns:
            Parsed metadata dictionary
        
        Raises:
            FetcherError: If artifact not found or API error
        
        Example:
            >>> metadata = fetcher.fetch_maven_metadata(
            ...     "org.springframework.boot",
            ...     "spring-boot-starter"
            ... )
        """
        group_path = self.group_to_path(group_id)
        url = f'{self.repo_base_url}/{group_path}/{artifact_id}/maven-metadata.xml'
        
        try:
            response = self._get(url, full_url=True)
            xml_content = response.text
            
            # Parse XML
            root = ET.fromstring(xml_content)
            
            metadata = {
                'groupId': root.findtext('groupId'),
                'artifactId': root.findtext('artifactId'),
                'latest': root.findtext('versioning/latest'),
                'release': root.findtext('versioning/release'),
                'versions': [],
                'lastUpdated': root.findtext('versioning/lastUpdated'),
            }
            
            # Extract versions
            versions_elem = root.find('versioning/versions')
            if versions_elem is not None:
                metadata['versions'] = [
                    v.text for v in versions_elem.findall('version')
                    if v.text
                ]
            
            self.logger.info(
                f"Fetched maven-metadata.xml for {group_id}:{artifact_id}"
            )
            return metadata
        
        except APIError as e:
            if '404' in str(e):
                raise FetcherError(
                    f"Artifact not found: {group_id}:{artifact_id}"
                )
            raise
        except ET.ParseError as e:
            raise FetcherError(f"Failed to parse maven-metadata.xml: {e}")
    
    def fetch_pom(
        self,
        group_id: str,
        artifact_id: str,
        version: str
    ) -> str:
        """
        Fetch POM file for a specific version.
        
        Args:
            group_id: Maven group ID
            artifact_id: Maven artifact ID
            version: Version string
        
        Returns:
            POM file content (XML)
        
        Example:
            >>> pom = fetcher.fetch_pom(
            ...     "org.springframework.boot",
            ...     "spring-boot-starter",
            ...     "3.2.0"
            ... )
        """
        group_path = self.group_to_path(group_id)
        url = (
            f'{self.repo_base_url}/{group_path}/{artifact_id}/'
            f'{version}/{artifact_id}-{version}.pom'
        )
        
        try:
            response = self._get(url, full_url=True)
            pom_content = response.text
            
            self.logger.info(
                f"Fetched POM for {group_id}:{artifact_id}:{version}"
            )
            return pom_content
        
        except APIError as e:
            if '404' in str(e):
                raise FetcherError(
                    f"POM not found: {group_id}:{artifact_id}:{version}"
                )
            raise
    
    def parse_pom(self, pom_content: str) -> Dict[str, Any]:
        """
        Parse POM file content.
        
        Args:
            pom_content: POM file content (XML)
        
        Returns:
            Dictionary with parsed information
        
        Example:
            >>> pom = fetcher.fetch_pom("org.springframework.boot", "spring-boot-starter", "3.2.0")
            >>> parsed = fetcher.parse_pom(pom)
        """
        try:
            root = ET.fromstring(pom_content)
            
            # Handle XML namespace
            ns = {'maven': 'http://maven.apache.org/POM/4.0.0'}
            
            # Helper to find text with or without namespace
            def find_text(path: str) -> Optional[str]:
                # Try with namespace
                elem = root.find(path, ns)
                if elem is not None and elem.text:
                    return elem.text
                # Try without namespace
                elem = root.find(path.replace('maven:', ''))
                if elem is not None and elem.text:
                    return elem.text
                return None
            
            parsed = {
                'groupId': find_text('maven:groupId') or find_text('maven:parent/maven:groupId'),
                'artifactId': find_text('maven:artifactId'),
                'version': find_text('maven:version') or find_text('maven:parent/maven:version'),
                'packaging': find_text('maven:packaging') or 'jar',
                'name': find_text('maven:name'),
                'description': find_text('maven:description'),
                'url': find_text('maven:url'),
                'licenses': [],
                'developers': [],
                'dependencies': [],
            }
            
            # Parse licenses
            licenses_elem = root.find('maven:licenses', ns) or root.find('licenses')
            if licenses_elem is not None:
                for license_elem in licenses_elem.findall('maven:license', ns) or licenses_elem.findall('license'):
                    parsed['licenses'].append({
                        'name': license_elem.findtext('maven:name', namespaces=ns) or license_elem.findtext('name'),
                        'url': license_elem.findtext('maven:url', namespaces=ns) or license_elem.findtext('url'),
                    })
            
            # Parse developers
            developers_elem = root.find('maven:developers', ns) or root.find('developers')
            if developers_elem is not None:
                for dev_elem in developers_elem.findall('maven:developer', ns) or developers_elem.findall('developer'):
                    parsed['developers'].append({
                        'name': dev_elem.findtext('maven:name', namespaces=ns) or dev_elem.findtext('name'),
                        'email': dev_elem.findtext('maven:email', namespaces=ns) or dev_elem.findtext('email'),
                    })
            
            # Parse dependencies
            deps_elem = root.find('maven:dependencies', ns) or root.find('dependencies')
            if deps_elem is not None:
                for dep_elem in deps_elem.findall('maven:dependency', ns) or deps_elem.findall('dependency'):
                    parsed['dependencies'].append({
                        'groupId': dep_elem.findtext('maven:groupId', namespaces=ns) or dep_elem.findtext('groupId'),
                        'artifactId': dep_elem.findtext('maven:artifactId', namespaces=ns) or dep_elem.findtext('artifactId'),
                        'version': dep_elem.findtext('maven:version', namespaces=ns) or dep_elem.findtext('version'),
                        'scope': dep_elem.findtext('maven:scope', namespaces=ns) or dep_elem.findtext('scope') or 'compile',
                    })
            
            return parsed
        
        except ET.ParseError as e:
            raise FetcherError(f"Failed to parse POM: {e}")
    
    def search_artifacts(
        self,
        query: str,
        rows: int = 20,
        start: int = 0
    ) -> List[Dict[str, Any]]:
        """
        Search for artifacts on Maven Central.
        
        Args:
            query: Search query (can be groupId, artifactId, or full coordinates)
            rows: Number of results to return (default: 20)
            start: Offset for pagination (default: 0)
        
        Returns:
            List of artifact dictionaries
        
        Example:
            >>> results = fetcher.search_artifacts("spring-boot")
        """
        endpoint = '/solrsearch/select'
        params = {
            'q': query,
            'rows': rows,
            'start': start,
            'wt': 'json',
        }
        
        try:
            response = self._get(endpoint, params=params)
            data = safe_json_parse(response, max_size_mb=10)
            
            artifacts = []
            for doc in data.get('response', {}).get('docs', []):
                artifacts.append({
                    'groupId': doc.get('g'),
                    'artifactId': doc.get('a'),
                    'latestVersion': doc.get('latestVersion'),
                    'repositoryId': doc.get('repositoryId'),
                    'packaging': doc.get('p'),
                    'timestamp': doc.get('timestamp'),
                    'versionCount': doc.get('versionCount'),
                })
            
            self.logger.info(
                f"Found {len(artifacts)} artifacts for query: {query}"
            )
            return artifacts
        
        except APIError as e:
            self.logger.warning(f"Search failed: {e}")
            return []
    
    # Implement abstract methods from BaseFetcher
    
    def fetch_versions(self, package_name: str, **kwargs) -> List[Dict[str, Any]]:
        """
        Fetch all versions for a Maven artifact.
        
        Args:
            package_name: Not used directly, use group_id and artifact_id from kwargs
            **kwargs: Must include 'group_id' and 'artifact_id'
        
        Returns:
            List of version dictionaries:
            [
                {
                    'version': '3.2.0',
                    'timestamp': None  # Maven metadata doesn't include timestamps
                },
                ...
            ]
        
        Example:
            >>> versions = fetcher.fetch_versions(
            ...     "spring-boot-starter",
            ...     group_id="org.springframework.boot",
            ...     artifact_id="spring-boot-starter"
            ... )
        """
        group_id = kwargs.get('group_id')
        artifact_id = kwargs.get('artifact_id')
        
        if not group_id or not artifact_id:
            raise FetcherError(
                "Must provide both 'group_id' and 'artifact_id'"
            )
        
        try:
            metadata = self.fetch_maven_metadata(group_id, artifact_id)
        except FetcherError:
            self.logger.warning(
                f"Artifact not found: {group_id}:{artifact_id}"
            )
            return []
        
        # Convert version list to standard format
        versions = []
        for version_str in metadata.get('versions', []):
            versions.append({
                'version': version_str,
                'timestamp': None,  # Not available in maven-metadata.xml
            })
        
        # Reverse to get newest first (Maven lists oldest first)
        versions.reverse()
        
        self.logger.info(
            f"Fetched {len(versions)} versions for {group_id}:{artifact_id}"
        )
        return versions
    
    def fetch_metadata(self, package_name: str, **kwargs) -> Dict[str, Any]:
        """
        Fetch artifact metadata.
        
        Args:
            package_name: Not used directly, use group_id and artifact_id from kwargs
            **kwargs: Must include 'group_id' and 'artifact_id'
        
        Returns:
            Dictionary with artifact metadata
        
        Example:
            >>> metadata = fetcher.fetch_metadata(
            ...     "spring-boot-starter",
            ...     group_id="org.springframework.boot",
            ...     artifact_id="spring-boot-starter"
            ... )
        """
        group_id = kwargs.get('group_id')
        artifact_id = kwargs.get('artifact_id')
        
        if not group_id or not artifact_id:
            raise FetcherError(
                "Must provide both 'group_id' and 'artifact_id'"
            )
        
        try:
            # Get maven metadata
            maven_metadata = self.fetch_maven_metadata(group_id, artifact_id)
            
            # Get POM for latest version
            latest_version = maven_metadata.get('latest') or maven_metadata.get('release')
            if latest_version:
                pom_content = self.fetch_pom(group_id, artifact_id, latest_version)
                pom_data = self.parse_pom(pom_content)
            else:
                pom_data = {}
            
            # Combine metadata
            metadata = {
                'groupId': group_id,
                'artifactId': artifact_id,
                'latest_version': latest_version,
                'name': pom_data.get('name'),
                'description': pom_data.get('description'),
                'url': pom_data.get('url'),
                'packaging': pom_data.get('packaging'),
                'licenses': pom_data.get('licenses', []),
                'developers': pom_data.get('developers', []),
                'dependencies': pom_data.get('dependencies', []),
                'version_count': len(maven_metadata.get('versions', [])),
            }
            
            self.logger.info(
                f"Fetched metadata for {group_id}:{artifact_id}"
            )
            return metadata
        
        except FetcherError:
            self.logger.warning(
                f"Artifact not found: {group_id}:{artifact_id}"
            )
            return {}
    
    def get_latest_version(
        self,
        group_id: str,
        artifact_id: str
    ) -> Optional[str]:
        """
        Get the latest version of an artifact.
        
        Args:
            group_id: Maven group ID
            artifact_id: Maven artifact ID
        
        Returns:
            Latest version string or None if not found
        
        Example:
            >>> version = fetcher.get_latest_version(
            ...     "org.springframework.boot",
            ...     "spring-boot-starter"
            ... )
        """
        try:
            metadata = self.fetch_maven_metadata(group_id, artifact_id)
            return metadata.get('latest') or metadata.get('release')
        except FetcherError:
            return None


# Example usage
if __name__ == '__main__':
    import logging
    logging.basicConfig(level=logging.INFO)
    
    # Initialize fetcher
    fetcher = MavenFetcher()
    
    # Example artifact
    group_id = "org.springframework.boot"
    artifact_id = "spring-boot-starter"
    
    # Example 1: Fetch versions
    print(f"\n=== Example 1: Fetch versions for {group_id}:{artifact_id} ===")
    versions = fetcher.fetch_versions(
        artifact_id,
        group_id=group_id,
        artifact_id=artifact_id
    )
    print(f"Found {len(versions)} versions")
    for v in versions[:5]:
        print(f"  {v['version']}")
    
    # Example 2: Fetch metadata
    print(f"\n=== Example 2: Fetch metadata ===")
    metadata = fetcher.fetch_metadata(
        artifact_id,
        group_id=group_id,
        artifact_id=artifact_id
    )
    print(f"  Group: {metadata.get('groupId')}")
    print(f"  Artifact: {metadata.get('artifactId')}")
    print(f"  Latest: {metadata.get('latest_version')}")
    print(f"  Name: {metadata.get('name')}")
    print(f"  Description: {metadata.get('description', '')[:80]}...")
    
    # Example 3: Get latest version
    print(f"\n=== Example 3: Get latest version ===")
    latest = fetcher.get_latest_version(group_id, artifact_id)
    print(f"  Latest version: {latest}")
    
    # Example 4: Search artifacts
    print(f"\n=== Example 4: Search artifacts ===")
    results = fetcher.search_artifacts("spring-boot-starter", rows=3)
    for artifact in results:
        print(f"  {artifact['groupId']}:{artifact['artifactId']} - {artifact['latestVersion']}")
    
    # Show rate limit stats
    print("\n=== Rate limit stats ===")
    stats = fetcher.get_rate_limit_stats()
    print(f"  Available calls: {stats['available_calls']}/{stats['max_calls']}")
    print(f"  Utilization: {stats['utilization']:.1%}")
    
    fetcher.close()