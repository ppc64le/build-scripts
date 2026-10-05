"""
GitHub API fetcher for repository tags and metadata.

This fetcher wraps the existing GitHubTagRepository from production code
and adapts it to the BaseFetcher interface for use in migration scripts.

Features:
- Authenticated API access (5000 req/hour with token, 60 without)
- Automatic pagination
- Rate limit handling
- Tag format detection
- Commit SHA retrieval
- Repository metadata
"""

import logging
import os
import re
from typing import Optional, List, Dict, Any, Tuple
from datetime import datetime

import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent.parent))

from fetchers.base_fetcher import BaseFetcher, FetcherError, APIError
from utils.security import mask_token


logger = logging.getLogger(__name__)


class GitHubFetcher(BaseFetcher):
    """
    Fetch data from GitHub API.
    
    Rate limits:
    - Authenticated: 5000 requests/hour
    - Unauthenticated: 60 requests/hour
    
    Endpoints used:
    - GET /repos/{owner}/{repo}/tags
    - GET /repos/{owner}/{repo}/releases
    - GET /repos/{owner}/{repo}
    - GET /repos/{owner}/{repo}/commits/{sha}
    
    Example:
        >>> fetcher = GitHubFetcher(token="ghp_xxx")
        >>> tags = fetcher.fetch_tags("numpy", "numpy")
        >>> metadata = fetcher.fetch_repository_metadata("numpy", "numpy")
    """
    
    def __init__(self, token: Optional[str] = None):
        """
        Initialize GitHub fetcher.
        
        Args:
            token: GitHub personal access token (optional but recommended)
                  Without token: 60 requests/hour
                  With token: 5000 requests/hour
        
        Environment:
            GITHUB_TOKEN: Can be set via environment variable
        """
        # Get token from parameter or environment
        self.token = token or os.getenv('GITHUB_TOKEN')
        
        # Determine rate limit based on token
        rate_limit = 5000 if self.token else 60
        
        # Initialize base fetcher
        headers = {}
        if self.token:
            headers['Authorization'] = f'token {self.token}'
            logger.info(
                f"GitHub token configured ({mask_token(self.token)}) - "
                f"5000 requests/hour available"
            )
        else:
            logger.warning("No GitHub token - limited to 60 requests/hour")
        
        super().__init__(
            base_url='https://api.github.com',
            rate_limit=rate_limit,
            rate_period=3600,  # 1 hour
            timeout=30,
            headers=headers
        )
        
        # Override Accept header for GitHub API v3
        self.session.headers['Accept'] = 'application/vnd.github.v3+json'
    
    def parse_github_url(self, github_url: str) -> Tuple[str, str]:
        """
        Parse GitHub URL to extract owner and repo.
        
        Args:
            github_url: GitHub repository URL
        
        Returns:
            Tuple of (owner, repo)
        
        Raises:
            FetcherError: If URL format is invalid
        
        Example:
            >>> owner, repo = fetcher.parse_github_url("https://github.com/numpy/numpy")
            >>> # Returns: ("numpy", "numpy")
        """
        # Remove trailing slashes and .git
        url = github_url.rstrip('/').rstrip('.git')
        
        # Match GitHub URL patterns
        patterns = [
            r'github\.com[:/]([^/]+)/([^/]+)',  # https://github.com/owner/repo or git@github.com:owner/repo
            r'^([^/]+)/([^/]+)$',  # owner/repo
        ]
        
        for pattern in patterns:
            match = re.search(pattern, url)
            if match:
                owner, repo = match.groups()
                return owner, repo
        
        raise FetcherError(f"Invalid GitHub URL format: {github_url}")
    
    def fetch_tags(
        self,
        owner: str,
        repo: str,
        max_tags: Optional[int] = None
    ) -> List[Dict[str, Any]]:
        """
        Fetch all tags for a repository.
        
        Args:
            owner: Repository owner
            repo: Repository name
            max_tags: Maximum number of tags to fetch (default: None = all)
        
        Returns:
            List of tag dictionaries:
            [
                {
                    'name': 'v1.26.3',
                    'commit': {
                        'sha': 'abc123...',
                        'url': 'https://api.github.com/repos/...'
                    },
                    'zipball_url': '...',
                    'tarball_url': '...'
                },
                ...
            ]
        
        Example:
            >>> tags = fetcher.fetch_tags("numpy", "numpy", max_tags=100)
        """
        endpoint = f'/repos/{owner}/{repo}/tags'
        
        # Calculate max pages if max_tags specified
        max_pages = None
        if max_tags:
            max_pages = (max_tags + 99) // 100  # Round up, 100 per page
        
        try:
            tags = self._get_paginated(
                endpoint,
                per_page=100,
                max_pages=max_pages
            )
            
            # Limit to max_tags if specified
            if max_tags and len(tags) > max_tags:
                tags = tags[:max_tags]
            
            self.logger.info(
                f"Fetched {len(tags)} tags for {owner}/{repo}"
            )
            return tags
        
        except APIError as e:
            if '404' in str(e):
                self.logger.warning(f"Repository not found: {owner}/{repo}")
                return []
            raise
    
    def fetch_commit_date(self, owner: str, repo: str, sha: str) -> Optional[str]:
        """
        Fetch commit date for a specific SHA.
        
        Args:
            owner: Repository owner
            repo: Repository name
            sha: Commit SHA
        
        Returns:
            ISO 8601 date string or None if not found
        
        Example:
            >>> date = fetcher.fetch_commit_date("numpy", "numpy", "abc123...")
            >>> # Returns: "2024-01-15T10:30:00Z"
        """
        endpoint = f'/repos/{owner}/{repo}/commits/{sha}'
        
        try:
            response = self._get(endpoint)
            data = response.json()
            
            # Get commit date
            commit_date = data.get('commit', {}).get('committer', {}).get('date')
            return commit_date
        
        except APIError as e:
            self.logger.warning(f"Could not fetch commit date for {sha}: {e}")
            return None
    
    def fetch_repository_metadata(self, owner: str, repo: str) -> Dict[str, Any]:
        """
        Fetch repository metadata.
        
        Args:
            owner: Repository owner
            repo: Repository name
        
        Returns:
            Dictionary with repository metadata:
            {
                'name': 'numpy',
                'full_name': 'numpy/numpy',
                'description': '...',
                'homepage': '...',
                'license': {'name': 'BSD-3-Clause', ...},
                'stargazers_count': 12345,
                'forks_count': 678,
                'language': 'Python',
                'created_at': '2010-01-01T00:00:00Z',
                'updated_at': '2024-01-15T00:00:00Z',
                'pushed_at': '2024-01-15T00:00:00Z'
            }
        
        Example:
            >>> metadata = fetcher.fetch_repository_metadata("numpy", "numpy")
        """
        endpoint = f'/repos/{owner}/{repo}'
        
        try:
            response = self._get(endpoint)
            data = response.json()
            
            # Extract relevant metadata
            metadata = {
                'name': data.get('name'),
                'full_name': data.get('full_name'),
                'description': data.get('description'),
                'homepage': data.get('homepage'),
                'license': data.get('license'),
                'stargazers_count': data.get('stargazers_count', 0),
                'forks_count': data.get('forks_count', 0),
                'language': data.get('language'),
                'created_at': data.get('created_at'),
                'updated_at': data.get('updated_at'),
                'pushed_at': data.get('pushed_at'),
                'default_branch': data.get('default_branch'),
                'topics': data.get('topics', []),
            }
            
            self.logger.info(f"Fetched metadata for {owner}/{repo}")
            return metadata
        
        except APIError as e:
            if '404' in str(e):
                self.logger.warning(f"Repository not found: {owner}/{repo}")
                return {}
            raise
    
    def detect_tag_format(self, tags: List[Dict[str, Any]]) -> str:
        """
        Detect tag format pattern from a list of tags.
        
        Args:
            tags: List of tag dictionaries (from fetch_tags)
        
        Returns:
            Tag format pattern:
            - 'v{version}' - Tags like v1.26.3
            - '{version}' - Tags like 1.26.3
            - 'release-{version}' - Tags like release-1.26.3
            - 'unknown' - No clear pattern
        
        Example:
            >>> tags = fetcher.fetch_tags("numpy", "numpy")
            >>> format = fetcher.detect_tag_format(tags)
            >>> # Returns: "v{version}"
        """
        if not tags:
            return 'unknown'
        
        # Count different patterns
        patterns = {
            'v{version}': 0,  # v1.26.3
            '{version}': 0,   # 1.26.3
            'release-{version}': 0,  # release-1.26.3
        }
        
        for tag in tags[:20]:  # Check first 20 tags
            tag_name = tag.get('name', '')
            
            if re.match(r'^v\d+\.\d+', tag_name):
                patterns['v{version}'] += 1
            elif re.match(r'^\d+\.\d+', tag_name):
                patterns['{version}'] += 1
            elif re.match(r'^release-\d+\.\d+', tag_name):
                patterns['release-{version}'] += 1
        
        # Return most common pattern
        if patterns['v{version}'] > patterns['{version}'] and patterns['v{version}'] > patterns['release-{version}']:
            return 'v{version}'
        elif patterns['{version}'] > patterns['v{version}'] and patterns['{version}'] > patterns['release-{version}']:
            return '{version}'
        elif patterns['release-{version}'] > 0:
            return 'release-{version}'
        else:
            return 'unknown'
    
    # Implement abstract methods from BaseFetcher
    
    def fetch_versions(self, package_name: str, **kwargs) -> List[Dict[str, Any]]:
        """
        Fetch all versions for a package from GitHub.
        
        Args:
            package_name: Package name (not used, use github_url instead)
            **kwargs: Must include 'github_url' or ('owner' and 'repo')
        
        Returns:
            List of version dictionaries:
            [
                {
                    'version': 'v1.26.3',
                    'commit': 'abc123...',
                    'date': '2024-01-15T00:00:00Z'
                },
                ...
            ]
        
        Example:
            >>> versions = fetcher.fetch_versions(
            ...     'numpy',
            ...     github_url='https://github.com/numpy/numpy'
            ... )
        """
        # Parse GitHub URL or use owner/repo
        if 'github_url' in kwargs:
            owner, repo = self.parse_github_url(kwargs['github_url'])
        elif 'owner' in kwargs and 'repo' in kwargs:
            owner = kwargs['owner']
            repo = kwargs['repo']
        else:
            raise FetcherError(
                "Must provide either 'github_url' or both 'owner' and 'repo'"
            )
        
        # Fetch tags
        max_tags = kwargs.get('max_tags')
        tags = self.fetch_tags(owner, repo, max_tags=max_tags)
        
        # Convert to version format
        versions = []
        for tag in tags:
            version_dict = {
                'version': tag['name'],
                'commit': tag['commit']['sha'],
                'date': None,  # Will be fetched if needed
            }
            versions.append(version_dict)
        
        return versions
    
    def fetch_metadata(self, package_name: str, **kwargs) -> Dict[str, Any]:
        """
        Fetch package metadata from GitHub.
        
        Args:
            package_name: Package name (not used, use github_url instead)
            **kwargs: Must include 'github_url' or ('owner' and 'repo')
        
        Returns:
            Dictionary with package metadata
        
        Example:
            >>> metadata = fetcher.fetch_metadata(
            ...     'numpy',
            ...     github_url='https://github.com/numpy/numpy'
            ... )
        """
        # Parse GitHub URL or use owner/repo
        if 'github_url' in kwargs:
            owner, repo = self.parse_github_url(kwargs['github_url'])
        elif 'owner' in kwargs and 'repo' in kwargs:
            owner = kwargs['owner']
            repo = kwargs['repo']
        else:
            raise FetcherError(
                "Must provide either 'github_url' or both 'owner' and 'repo'"
            )
        
        return self.fetch_repository_metadata(owner, repo)


# Example usage
if __name__ == '__main__':
    import logging
    logging.basicConfig(level=logging.INFO)
    
    # Initialize fetcher (will use GITHUB_TOKEN from environment if available)
    fetcher = GitHubFetcher()
    
    # Example 1: Fetch tags
    print("\n=== Example 1: Fetch tags ===")
    tags = fetcher.fetch_tags("numpy", "numpy", max_tags=5)
    for tag in tags:
        print(f"  {tag['name']} - {tag['commit']['sha'][:7]}")
    
    # Example 2: Detect tag format
    print("\n=== Example 2: Detect tag format ===")
    tag_format = fetcher.detect_tag_format(tags)
    print(f"  Tag format: {tag_format}")
    
    # Example 3: Fetch repository metadata
    print("\n=== Example 3: Fetch repository metadata ===")
    metadata = fetcher.fetch_repository_metadata("numpy", "numpy")
    print(f"  Name: {metadata.get('name')}")
    print(f"  Description: {metadata.get('description')}")
    print(f"  Stars: {metadata.get('stargazers_count')}")
    print(f"  Language: {metadata.get('language')}")
    
    # Example 4: Using BaseFetcher interface
    print("\n=== Example 4: Using BaseFetcher interface ===")
    versions = fetcher.fetch_versions(
        'numpy',
        github_url='https://github.com/numpy/numpy',
        max_tags=3
    )
    for v in versions:
        print(f"  {v['version']}")
    
    # Show rate limit stats
    print("\n=== Rate limit stats ===")
    stats = fetcher.get_rate_limit_stats()
    print(f"  Available calls: {stats['available_calls']}/{stats['max_calls']}")
    print(f"  Utilization: {stats['utilization']:.1%}")
    
    fetcher.close()