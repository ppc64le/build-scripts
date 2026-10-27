"""
Deduplication modules for database migration.

Provides:
- Package deduplication based on (name, version)
- Quality-based selection of best entry
- Data merging from duplicates
- Deduplication statistics
"""

from .deduplicator import (
    deduplicate_packages,
    group_by_package_version,
    select_best_entry,
    DeduplicationStats,
)
from .merger import (
    merge_duplicate_data,
    merge_field,
    merge_lists,
    merge_dicts,
)

__all__ = [
    # Deduplication
    'deduplicate_packages',
    'group_by_package_version',
    'select_best_entry',
    'DeduplicationStats',
    
    # Merging
    'merge_duplicate_data',
    'merge_field',
    'merge_lists',
    'merge_dicts',
]