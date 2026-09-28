"""
Data merging logic for duplicate entries.

Features:
- Merge data from multiple duplicate documents
- Preserve best quality data
- Combine lists and dictionaries
- Handle conflicts intelligently
"""

import logging
from typing import Any, List, Dict, Optional


logger = logging.getLogger(__name__)


def merge_field(
    primary_value: Any,
    duplicate_values: List[Any],
    field_name: str
) -> Any:
    """
    Merge a single field from multiple documents.
    
    Strategy:
    - If primary has value, keep it
    - If primary is empty/None/N/A, try duplicates
    - For lists, combine and deduplicate
    - For dicts, merge keys
    
    Args:
        primary_value: Value from primary (best quality) document
        duplicate_values: Values from duplicate documents
        field_name: Name of the field (for logging)
    
    Returns:
        Merged value
    
    Example:
        >>> merge_field('value1', ['value2', 'value3'], 'field')
        'value1'
        >>> merge_field(None, ['value2', 'value3'], 'field')
        'value2'
    """
    # Check if primary value is usable
    if primary_value and primary_value not in [None, '', 'N/A', 'Unknown', 'unknown']:
        return primary_value
    
    # Try to find a usable value from duplicates
    for value in duplicate_values:
        if value and value not in [None, '', 'N/A', 'Unknown', 'unknown']:
            logger.debug(f"Using duplicate value for {field_name}: {value}")
            return value
    
    # No usable value found, return primary
    return primary_value


def merge_lists(
    primary_list: Optional[List],
    duplicate_lists: List[List]
) -> List:
    """
    Merge multiple lists, removing duplicates.
    
    Args:
        primary_list: List from primary document
        duplicate_lists: Lists from duplicate documents
    
    Returns:
        Merged list with duplicates removed
    
    Example:
        >>> merge_lists([1, 2], [[2, 3], [3, 4]])
        [1, 2, 3, 4]
    """
    if primary_list is None:
        primary_list = []
    
    # Combine all lists
    combined = list(primary_list)
    for dup_list in duplicate_lists:
        if dup_list:
            combined.extend(dup_list)
    
    # Remove duplicates while preserving order
    seen = set()
    result = []
    for item in combined:
        # Handle unhashable types
        try:
            if item not in seen:
                seen.add(item)
                result.append(item)
        except TypeError:
            # Unhashable type, just append
            result.append(item)
    
    return result


def merge_dicts(
    primary_dict: Optional[Dict],
    duplicate_dicts: List[Dict]
) -> Dict:
    """
    Merge multiple dictionaries.
    
    Strategy:
    - Start with primary dict
    - Add keys from duplicates if not in primary
    - For nested dicts, merge recursively
    
    Args:
        primary_dict: Dict from primary document
        duplicate_dicts: Dicts from duplicate documents
    
    Returns:
        Merged dictionary
    
    Example:
        >>> merge_dicts({'a': 1}, [{'b': 2}, {'c': 3}])
        {'a': 1, 'b': 2, 'c': 3}
    """
    if primary_dict is None:
        primary_dict = {}
    
    result = dict(primary_dict)
    
    for dup_dict in duplicate_dicts:
        if not dup_dict:
            continue
        
        for key, value in dup_dict.items():
            if key not in result:
                # Key not in primary, add it
                result[key] = value
            elif isinstance(result[key], dict) and isinstance(value, dict):
                # Both are dicts, merge recursively
                result[key] = merge_dicts(result[key], [value])
            elif isinstance(result[key], list) and isinstance(value, list):
                # Both are lists, merge
                result[key] = merge_lists(result[key], [value])
            # Otherwise keep primary value
    
    return result


def merge_duplicate_data(
    primary: dict,
    duplicates: List[dict]
) -> dict:
    """
    Merge data from duplicate documents into primary document.
    
    Strategy:
    - Keep all data from primary (best quality)
    - Fill in missing fields from duplicates
    - Combine lists and dicts
    - Add metadata about merge
    
    Args:
        primary: Primary (best quality) document
        duplicates: List of all documents (including primary)
    
    Returns:
        Merged document
    
    Example:
        >>> primary = {'name': 'numpy', 'url': 'https://...'}
        >>> duplicates = [
        ...     primary,
        ...     {'name': 'numpy', 'url': 'N/A', 'license': 'BSD'}
        ... ]
        >>> merged = merge_duplicate_data(primary, duplicates)
        >>> merged['license']
        'BSD'
    """
    # Start with copy of primary
    merged = dict(primary)
    
    # Get other duplicates (exclude primary)
    other_duplicates = [d for d in duplicates if d is not primary]
    
    if not other_duplicates:
        return merged
    
    logger.info(f"Merging data from {len(other_duplicates)} duplicates")
    
    # Fields to merge
    string_fields = [
        'description', 'summary', 'license', 'author', 'maintainer',
        'homepage', 'documentation', 'ci_engine', 'dockerhub_link',
    ]
    
    list_fields = [
        'keywords', 'tags', 'classifiers', 'maintainers', 'contributors',
    ]
    
    dict_fields = [
        'metadata', 'links', 'project_urls', 'dependencies',
    ]
    
    # Merge string fields
    for field in string_fields:
        if field in merged:
            duplicate_values = [d.get(field) for d in other_duplicates if field in d]
            merged[field] = merge_field(merged[field], duplicate_values, field)
    
    # Merge list fields
    for field in list_fields:
        if field in merged or any(field in d for d in other_duplicates):
            primary_list = merged.get(field)
            duplicate_lists = [d.get(field) for d in other_duplicates if field in d]
            merged[field] = merge_lists(primary_list, duplicate_lists)
    
    # Merge dict fields
    for field in dict_fields:
        if field in merged or any(field in d for d in other_duplicates):
            primary_dict = merged.get(field)
            duplicate_dicts = [d.get(field) for d in other_duplicates if field in d]
            merged[field] = merge_dicts(primary_dict, duplicate_dicts)
    
    # Add merge metadata
    merged['_merge_info'] = {
        'merged_from': len(other_duplicates),
        'merge_date': None,  # Will be set during migration
    }
    
    return merged


def compare_documents(doc1: dict, doc2: dict) -> Dict[str, Any]:
    """
    Compare two documents and show differences.
    
    Args:
        doc1: First document
        doc2: Second document
    
    Returns:
        Dictionary with comparison results:
        {
            'common_fields': [...],
            'only_in_doc1': [...],
            'only_in_doc2': [...],
            'different_values': {...}
        }
    
    Example:
        >>> doc1 = {'name': 'numpy', 'version': '1.26.3'}
        >>> doc2 = {'name': 'numpy', 'version': '1.26.2', 'license': 'BSD'}
        >>> comparison = compare_documents(doc1, doc2)
    """
    keys1 = set(doc1.keys())
    keys2 = set(doc2.keys())
    
    common_fields = keys1 & keys2
    only_in_doc1 = keys1 - keys2
    only_in_doc2 = keys2 - keys1
    
    different_values = {}
    for key in common_fields:
        if doc1[key] != doc2[key]:
            different_values[key] = {
                'doc1': doc1[key],
                'doc2': doc2[key],
            }
    
    return {
        'common_fields': list(common_fields),
        'only_in_doc1': list(only_in_doc1),
        'only_in_doc2': list(only_in_doc2),
        'different_values': different_values,
    }


# Example usage
if __name__ == '__main__':
    import logging
    logging.basicConfig(level=logging.INFO)
    
    # Example 1: Merge field
    print("\n=== Example 1: Merge field ===")
    result = merge_field('value1', ['value2', 'value3'], 'test_field')
    print(f"  Primary has value: {result}")
    
    result = merge_field(None, ['value2', 'value3'], 'test_field')
    print(f"  Primary is None: {result}")
    
    result = merge_field('N/A', ['value2', 'value3'], 'test_field')
    print(f"  Primary is N/A: {result}")
    
    # Example 2: Merge lists
    print("\n=== Example 2: Merge lists ===")
    result = merge_lists([1, 2], [[2, 3], [3, 4]])
    print(f"  Merged list: {result}")
    
    # Example 3: Merge dicts
    print("\n=== Example 3: Merge dicts ===")
    result = merge_dicts(
        {'a': 1, 'nested': {'x': 1}},
        [{'b': 2}, {'nested': {'y': 2}}]
    )
    print(f"  Merged dict: {result}")
    
    # Example 4: Merge duplicate data
    print("\n=== Example 4: Merge duplicate data ===")
    primary = {
        'package_name': 'numpy',
        'version': '1.26.3',
        'github_url': 'https://github.com/numpy/numpy',
        'description': 'Array computing',
    }
    duplicates = [
        primary,
        {
            'package_name': 'numpy',
            'version': '1.26.3',
            'github_url': 'N/A',
            'license': 'BSD-3-Clause',
            'keywords': ['array', 'scientific'],
        },
        {
            'package_name': 'numpy',
            'version': '1.26.3',
            'github_url': 'N/A',
            'keywords': ['computing'],
            'author': 'NumPy Developers',
        },
    ]
    merged = merge_duplicate_data(primary, duplicates)
    print(f"  Original fields: {len(primary)}")
    print(f"  Merged fields: {len(merged)}")
    print(f"  Added fields:")
    for key in merged:
        if key not in primary:
            print(f"    {key}: {merged[key]}")
    
    # Example 5: Compare documents
    print("\n=== Example 5: Compare documents ===")
    doc1 = {'name': 'numpy', 'version': '1.26.3', 'license': 'BSD'}
    doc2 = {'name': 'numpy', 'version': '1.26.2', 'author': 'NumPy Team'}
    comparison = compare_documents(doc1, doc2)
    print(f"  Common fields: {comparison['common_fields']}")
    print(f"  Only in doc1: {comparison['only_in_doc1']}")
    print(f"  Only in doc2: {comparison['only_in_doc2']}")
    print(f"  Different values: {comparison['different_values']}")