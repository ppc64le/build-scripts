"""
Package deduplication logic.

Features:
- Group packages by (name, version)
- Select best entry based on quality score
- Track deduplication statistics
"""

import logging
from typing import List, Dict, Tuple, Any
from collections import defaultdict
from dataclasses import dataclass, field

import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent.parent))

from quality.quality_scorer import calculate_quality_score


logger = logging.getLogger(__name__)


@dataclass
class DeduplicationStats:
    """Statistics for deduplication process."""
    total_documents: int = 0
    unique_packages: int = 0
    duplicates_found: int = 0
    duplicates_removed: int = 0
    groups_by_count: Dict[int, int] = field(default_factory=dict)
    
    def add_group(self, group_size: int):
        """Add a group to statistics."""
        if group_size not in self.groups_by_count:
            self.groups_by_count[group_size] = 0
        self.groups_by_count[group_size] += 1
        
        if group_size > 1:
            self.duplicates_found += group_size
            self.duplicates_removed += group_size - 1
    
    def __str__(self) -> str:
        """String representation of stats."""
        lines = [
            f"Total documents: {self.total_documents}",
            f"Unique packages: {self.unique_packages}",
            f"Duplicates found: {self.duplicates_found}",
            f"Duplicates removed: {self.duplicates_removed}",
            f"Reduction: {self.duplicates_removed / self.total_documents * 100:.1f}%",
            "",
            "Groups by size:",
        ]
        
        for size in sorted(self.groups_by_count.keys()):
            count = self.groups_by_count[size]
            lines.append(f"  {size} duplicates: {count} groups")
        
        return "\n".join(lines)


def group_by_package_version(
    documents: List[dict]
) -> Dict[Tuple[str, str], List[dict]]:
    """
    Group documents by (package_name, version).
    
    Args:
        documents: List of package documents
    
    Returns:
        Dictionary mapping (name, version) to list of documents
    
    Example:
        >>> docs = [
        ...     {'package_name': 'numpy', 'version': '1.26.3', ...},
        ...     {'package_name': 'numpy', 'version': '1.26.3', ...},  # Duplicate
        ... ]
        >>> groups = group_by_package_version(docs)
        >>> len(groups[('numpy', '1.26.3')])
        2
    """
    groups = defaultdict(list)
    
    for doc in documents:
        # Get package name (try multiple fields)
        package_name = (
            doc.get('normalized_name') or
            doc.get('package_name') or
            'unknown'
        )
        package_name = package_name.lower().strip()
        
        # Get version (try multiple fields)
        version = (
            doc.get('normalized_version') or
            doc.get('version_ported') or
            doc.get('version') or
            doc.get('available_versions') or
            'unknown'
        )
        version = str(version).strip()
        
        # Create key
        key = (package_name, version)
        groups[key].append(doc)
    
    logger.info(f"Grouped {len(documents)} documents into {len(groups)} unique packages")
    
    return dict(groups)


def select_best_entry(duplicates: List[dict]) -> dict:
    """
    Select the best entry from a list of duplicates based on quality score.
    
    Args:
        duplicates: List of duplicate documents
    
    Returns:
        Best document (highest quality score)
    
    Example:
        >>> docs = [
        ...     {'package_name': 'numpy', 'github_url': 'https://...', ...},
        ...     {'package_name': 'numpy', 'github_url': 'N/A', ...},
        ... ]
        >>> best = select_best_entry(docs)
    """
    if not duplicates:
        raise ValueError("Cannot select from empty list")
    
    if len(duplicates) == 1:
        return duplicates[0]
    
    # Calculate quality scores for all duplicates
    scored_docs = []
    for doc in duplicates:
        quality_result = calculate_quality_score(doc)
        scored_docs.append((quality_result['total_score'], doc))
    
    # Sort by score (highest first)
    scored_docs.sort(key=lambda x: x[0], reverse=True)
    
    best_score, best_doc = scored_docs[0]
    
    logger.debug(
        f"Selected best entry with score {best_score} from {len(duplicates)} duplicates"
    )
    
    return best_doc


def deduplicate_packages(
    documents: List[dict],
    merge_data: bool = True
) -> Tuple[List[dict], DeduplicationStats]:
    """
    Deduplicate packages, keeping the best quality entry for each (name, version).
    
    Args:
        documents: List of package documents
        merge_data: Whether to merge data from duplicates into best entry
    
    Returns:
        Tuple of (deduplicated_documents, statistics)
    
    Example:
        >>> docs = [...]  # List with duplicates
        >>> deduplicated, stats = deduplicate_packages(docs)
        >>> print(stats)
    """
    stats = DeduplicationStats()
    stats.total_documents = len(documents)
    
    # Group by (name, version)
    groups = group_by_package_version(documents)
    stats.unique_packages = len(groups)
    
    # Process each group
    deduplicated = []
    
    for key, group_docs in groups.items():
        package_name, version = key
        group_size = len(group_docs)
        
        # Track group size
        stats.add_group(group_size)
        
        if group_size == 1:
            # No duplicates, keep as-is
            deduplicated.append(group_docs[0])
        else:
            # Select best entry
            logger.info(
                f"Found {group_size} duplicates for {package_name} {version}"
            )
            best_doc = select_best_entry(group_docs)
            
            # Merge data from duplicates if requested
            if merge_data:
                from .merger import merge_duplicate_data
                best_doc = merge_duplicate_data(best_doc, group_docs)
            
            deduplicated.append(best_doc)
    
    logger.info(
        f"Deduplication complete: {stats.total_documents} → {len(deduplicated)} "
        f"({stats.duplicates_removed} removed)"
    )
    
    return deduplicated, stats


def find_duplicates(documents: List[dict]) -> Dict[Tuple[str, str], List[dict]]:
    """
    Find all duplicate groups (groups with more than one document).
    
    Args:
        documents: List of package documents
    
    Returns:
        Dictionary of duplicate groups
    
    Example:
        >>> docs = [...]
        >>> duplicates = find_duplicates(docs)
        >>> for key, group in duplicates.items():
        ...     print(f"{key}: {len(group)} duplicates")
    """
    groups = group_by_package_version(documents)
    
    # Filter to only groups with duplicates
    duplicates = {
        key: docs
        for key, docs in groups.items()
        if len(docs) > 1
    }
    
    logger.info(f"Found {len(duplicates)} duplicate groups")
    
    return duplicates


# Example usage
if __name__ == '__main__':
    import logging
    logging.basicConfig(level=logging.INFO)
    
    # Example 1: Group by package/version
    print("\n=== Example 1: Group by package/version ===")
    docs = [
        {'package_name': 'numpy', 'version_ported': '1.26.3', 'github_url': 'https://github.com/numpy/numpy'},
        {'package_name': 'numpy', 'version_ported': '1.26.3', 'github_url': 'N/A'},  # Duplicate
        {'package_name': 'numpy', 'version_ported': '1.26.2', 'github_url': 'https://github.com/numpy/numpy'},
        {'package_name': 'pandas', 'version_ported': '2.0.0', 'github_url': 'https://github.com/pandas-dev/pandas'},
    ]
    groups = group_by_package_version(docs)
    print(f"  Total documents: {len(docs)}")
    print(f"  Unique packages: {len(groups)}")
    for key, group in groups.items():
        print(f"    {key}: {len(group)} document(s)")
    
    # Example 2: Select best entry
    print("\n=== Example 2: Select best entry ===")
    duplicates = [
        {
            'package_name': 'numpy',
            'version_ported': '1.26.3',
            'github_url': 'https://github.com/numpy/numpy',
            'description': 'Array computing',
            'license': 'BSD',
        },
        {
            'package_name': 'numpy',
            'version_ported': '1.26.3',
            'github_url': 'N/A',
        },
    ]
    best = select_best_entry(duplicates)
    print(f"  Selected: {best.get('package_name')} with GitHub URL: {best.get('github_url')}")
    
    # Example 3: Deduplicate packages
    print("\n=== Example 3: Deduplicate packages ===")
    deduplicated, stats = deduplicate_packages(docs, merge_data=False)
    print(f"  Before: {len(docs)} documents")
    print(f"  After: {len(deduplicated)} documents")
    print(f"  Removed: {stats.duplicates_removed} duplicates")
    print(f"\n{stats}")
    
    # Example 4: Find duplicates
    print("\n=== Example 4: Find duplicates ===")
    duplicate_groups = find_duplicates(docs)
    print(f"  Found {len(duplicate_groups)} duplicate groups:")
    for key, group in duplicate_groups.items():
        print(f"    {key}: {len(group)} duplicates")