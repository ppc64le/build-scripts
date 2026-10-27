"""
Data normalization modules for database migration.

Provides normalization for:
- Package names and ecosystems
- Version strings
- URLs
- Dates

All normalizers follow consistent patterns:
- normalize() - Convert to canonical form
- validate() - Check if input is valid
- denormalize() - Convert back to original form (where applicable)
"""

from .package_normalizer import (
    normalize_package_name,
    normalize_ecosystem,
    should_exclude_package,
    ECOSYSTEM_MAPPING,
)
from .version_normalizer import (
    normalize_version,
    create_version_mapping,
    detect_tag_format,
    parse_version,
)
from .url_normalizer import (
    normalize_github_url,
    normalize_registry_url,
    parse_github_url,
)
from .date_normalizer import (
    normalize_date,
    parse_date,
    format_iso8601,
)

__all__ = [
    # Package normalization
    'normalize_package_name',
    'normalize_ecosystem',
    'should_exclude_package',
    'ECOSYSTEM_MAPPING',
    
    # Version normalization
    'normalize_version',
    'create_version_mapping',
    'detect_tag_format',
    'parse_version',
    
    # URL normalization
    'normalize_github_url',
    'normalize_registry_url',
    'parse_github_url',
    
    # Date normalization
    'normalize_date',
    'parse_date',
    'format_iso8601',
]