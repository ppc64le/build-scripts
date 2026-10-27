"""
External data fetchers for database migration.

Provides clients for fetching package metadata from various sources:
- GitHub: Repository tags, releases, metadata
- PyPI: Python package versions and metadata
- npm: Node package versions and metadata
- Go: Go module versions and metadata
- Maven: Java artifact versions and metadata

All fetchers inherit from BaseFetcher and include:
- Rate limiting
- Retry logic with exponential backoff
- Request/response logging
- Error handling
"""

from .base_fetcher import BaseFetcher, FetcherError
from .github_fetcher import GitHubFetcher
from .pypi_fetcher import PyPIFetcher
from .npm_fetcher import NpmFetcher
from .go_fetcher import GoFetcher
from .maven_fetcher import MavenFetcher

__all__ = [
    'BaseFetcher',
    'FetcherError',
    'GitHubFetcher',
    'PyPIFetcher',
    'NpmFetcher',
    'GoFetcher',
    'MavenFetcher',
]