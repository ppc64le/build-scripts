"""
Version string normalization.

Features:
- Semantic versioning normalization
- Prefix removal (v, release-, etc.)
- Source-specific handling
- Bidirectional version mapping
- Tag format detection
"""

import logging
import re
from typing import Optional, Dict, Any, List, Tuple
from packaging import version as pkg_version


logger = logging.getLogger(__name__)


def normalize_version(version_str: str, source: str = 'unknown') -> Optional[str]:
    """
    Normalize version string to semantic versioning.
    
    Rules:
    - Remove common prefixes (v, V, release-, rel-, etc.)
    - Convert to semantic versioning (X.Y.Z)
    - Handle special cases per source
    
    Args:
        version_str: Version string
        source: Source of version (github, pypi, npm, go, maven)
    
    Returns:
        Normalized version string or None if invalid
    
    Example:
        >>> normalize_version('v1.26.3', 'github')
        '1.26.3'
        >>> normalize_version('1.26', 'pypi')
        '1.26.0'
        >>> normalize_version('release-2.0.1', 'github')
        '2.0.1'
    """
    if not version_str:
        return None
    
    original = version_str
    version_str = version_str.strip()
    
    # Remove common prefixes
    prefixes = [
        'v', 'V',
        'version-', 'Version-', 'VERSION-',
        'release-', 'Release-', 'RELEASE-',
        'rel-', 'Rel-', 'REL-',
        'r-', 'R-',
    ]
    
    for prefix in prefixes:
        if version_str.startswith(prefix):
            version_str = version_str[len(prefix):]
            break
    
    # Source-specific handling
    if source == 'github':
        # GitHub tags might have additional prefixes
        version_str = re.sub(r'^(tag|Tag|TAG)[-_]', '', version_str)
    
    elif source == 'go':
        # Go versions always start with 'v' but we normalize without it
        if version_str.startswith('v'):
            version_str = version_str[1:]
    
    # Try to parse with packaging library
    try:
        parsed = pkg_version.parse(version_str)
        
        # Convert to string (removes build metadata, keeps pre-release)
        normalized = str(parsed)
        
        # Ensure at least X.Y.Z format
        parts = normalized.split('.')
        if len(parts) == 1:
            normalized = f"{parts[0]}.0.0"
        elif len(parts) == 2:
            normalized = f"{parts[0]}.{parts[1]}.0"
        
        logger.debug(f"Normalized version: {original} → {normalized}")
        return normalized
    
    except Exception as e:
        logger.warning(f"Could not normalize version {original}: {e}")
        return None


def parse_version(version_str: str) -> Optional[Dict[str, Any]]:
    """
    Parse version string into components.
    
    Args:
        version_str: Version string
    
    Returns:
        Dictionary with version components or None if invalid:
        {
            'major': 1,
            'minor': 26,
            'patch': 3,
            'pre_release': 'alpha.1',
            'build': '20240115',
            'original': 'v1.26.3-alpha.1+20240115'
        }
    
    Example:
        >>> parse_version('1.26.3-alpha.1+20240115')
        {'major': 1, 'minor': 26, 'patch': 3, ...}
    """
    if not version_str:
        return None
    
    try:
        parsed = pkg_version.parse(version_str)
        
        # Extract components
        result = {
            'original': version_str,
            'major': parsed.major if hasattr(parsed, 'major') else None,
            'minor': parsed.minor if hasattr(parsed, 'minor') else None,
            'patch': parsed.micro if hasattr(parsed, 'micro') else None,
            'pre_release': None,
            'build': None,
        }
        
        # Handle pre-release
        if hasattr(parsed, 'pre') and parsed.pre:
            result['pre_release'] = ''.join(str(x) for x in parsed.pre)
        
        # Handle build metadata (not directly supported by packaging)
        if '+' in version_str:
            result['build'] = version_str.split('+')[1]
        
        return result
    
    except Exception as e:
        logger.warning(f"Could not parse version {version_str}: {e}")
        return None


def create_version_mapping(
    original: str,
    normalized: str,
    source: str
) -> Dict[str, Any]:
    """
    Create bidirectional version mapping.
    
    Args:
        original: Original version string
        normalized: Normalized version string
        source: Source of version
    
    Returns:
        Version mapping dictionary:
        {
            'original': 'v1.26.3',
            'normalized': '1.26.3',
            'source': 'github',
            'format': 'v{version}'
        }
    
    Example:
        >>> mapping = create_version_mapping('v1.26.3', '1.26.3', 'github')
    """
    # Detect format pattern
    format_pattern = detect_version_format(original, normalized)
    
    return {
        'original': original,
        'normalized': normalized,
        'source': source,
        'format': format_pattern,
    }


def detect_version_format(original: str, normalized: str) -> str:
    """
    Detect version format pattern.
    
    Args:
        original: Original version string
        normalized: Normalized version string
    
    Returns:
        Format pattern string
    
    Example:
        >>> detect_version_format('v1.26.3', '1.26.3')
        'v{version}'
        >>> detect_version_format('release-2.0.1', '2.0.1')
        'release-{version}'
    """
    if not original or not normalized:
        return '{version}'
    
    # Find where the normalized version appears in original
    idx = original.find(normalized)
    if idx == -1:
        # Try without patch version
        parts = normalized.split('.')
        if len(parts) >= 2:
            short_version = f"{parts[0]}.{parts[1]}"
            idx = original.find(short_version)
    
    if idx == -1:
        return '{version}'
    
    # Extract prefix
    prefix = original[:idx]
    suffix = original[idx + len(normalized):]
    
    if prefix and suffix:
        return f"{prefix}{{version}}{suffix}"
    elif prefix:
        return f"{prefix}{{version}}"
    elif suffix:
        return f"{{version}}{suffix}"
    else:
        return '{version}'


def detect_tag_format(tags: List[str]) -> str:
    """
    Detect tag format pattern from a list of tags.
    
    Args:
        tags: List of tag strings
    
    Returns:
        Most common tag format pattern
    
    Example:
        >>> tags = ['v1.26.3', 'v1.26.2', 'v1.26.1']
        >>> detect_tag_format(tags)
        'v{version}'
    """
    if not tags:
        return '{version}'
    
    # Count different patterns
    patterns = {
        'v{version}': 0,
        '{version}': 0,
        'release-{version}': 0,
        'rel-{version}': 0,
        'r{version}': 0,
    }
    
    for tag in tags[:20]:  # Check first 20 tags
        if re.match(r'^v\d+\.\d+', tag):
            patterns['v{version}'] += 1
        elif re.match(r'^\d+\.\d+', tag):
            patterns['{version}'] += 1
        elif re.match(r'^release-\d+\.\d+', tag):
            patterns['release-{version}'] += 1
        elif re.match(r'^rel-\d+\.\d+', tag):
            patterns['rel-{version}'] += 1
        elif re.match(r'^r\d+\.\d+', tag):
            patterns['r{version}'] += 1
    
    # Return most common pattern
    if patterns:
        return max(patterns, key=patterns.get)
    
    return '{version}'


def denormalize_version(normalized: str, format_pattern: str) -> str:
    """
    Convert normalized version back to original format.
    
    Args:
        normalized: Normalized version string
        format_pattern: Format pattern (e.g., 'v{version}')
    
    Returns:
        Version in original format
    
    Example:
        >>> denormalize_version('1.26.3', 'v{version}')
        'v1.26.3'
        >>> denormalize_version('2.0.1', 'release-{version}')
        'release-2.0.1'
    """
    if not normalized:
        return ''
    
    if not format_pattern or format_pattern == '{version}':
        return normalized
    
    return format_pattern.replace('{version}', normalized)


def compare_versions(version1: str, version2: str) -> int:
    """
    Compare two version strings.
    
    Args:
        version1: First version string
        version2: Second version string
    
    Returns:
        -1 if version1 < version2
         0 if version1 == version2
         1 if version1 > version2
    
    Example:
        >>> compare_versions('1.26.3', '1.26.2')
        1
        >>> compare_versions('1.26.0', '1.26.0')
        0
        >>> compare_versions('1.25.0', '1.26.0')
        -1
    """
    try:
        v1 = pkg_version.parse(version1)
        v2 = pkg_version.parse(version2)
        
        if v1 < v2:
            return -1
        elif v1 > v2:
            return 1
        else:
            return 0
    
    except Exception as e:
        logger.warning(f"Could not compare versions {version1} and {version2}: {e}")
        # Fall back to string comparison
        if version1 < version2:
            return -1
        elif version1 > version2:
            return 1
        else:
            return 0


def is_valid_version(version_str: str) -> Tuple[bool, str]:
    """
    Validate version string.
    
    Args:
        version_str: Version string
    
    Returns:
        Tuple of (is_valid, error_message)
    
    Example:
        >>> is_valid_version('1.26.3')
        (True, '')
        >>> is_valid_version('invalid')
        (False, 'Invalid version format')
    """
    if not version_str or not version_str.strip():
        return False, 'Version cannot be empty'
    
    try:
        pkg_version.parse(version_str)
        return True, ''
    except Exception as e:
        return False, f'Invalid version format: {e}'


def normalize_version_data(data: dict) -> dict:
    """
    Normalize version data dictionary.
    
    Args:
        data: Version data dictionary with 'version' and optionally 'source'
    
    Returns:
        Normalized dictionary with additional fields
    
    Example:
        >>> data = {'version': 'v1.26.3', 'source': 'github'}
        >>> normalized = normalize_version_data(data)
        >>> normalized['normalized_version']
        '1.26.3'
    """
    result = data.copy()
    
    version_str = data.get('version', '')
    source = data.get('source', 'unknown')
    
    # Normalize version
    normalized = normalize_version(version_str, source)
    result['normalized_version'] = normalized
    
    # Parse version
    parsed = parse_version(version_str)
    if parsed:
        result['version_components'] = parsed
    
    # Create mapping
    if normalized:
        mapping = create_version_mapping(version_str, normalized, source)
        result['version_mapping'] = mapping
    
    # Validate
    is_valid, error = is_valid_version(version_str)
    result['is_valid'] = is_valid
    result['validation_error'] = error if error else None
    
    return result


# Example usage
if __name__ == '__main__':
    import logging
    logging.basicConfig(level=logging.INFO)
    
    # Example 1: Normalize versions
    print("\n=== Example 1: Normalize versions ===")
    versions = [
        ('v1.26.3', 'github'),
        ('1.26', 'pypi'),
        ('release-2.0.1', 'github'),
        ('v1.9.1', 'go'),
    ]
    for ver, source in versions:
        normalized = normalize_version(ver, source)
        print(f"  {ver} ({source}) → {normalized}")
    
    # Example 2: Parse versions
    print("\n=== Example 2: Parse versions ===")
    test_versions = ['1.26.3', '2.0.0-alpha.1', '3.1.4+20240115']
    for ver in test_versions:
        parsed = parse_version(ver)
        if parsed:
            print(f"  {ver}:")
            print(f"    Major: {parsed['major']}, Minor: {parsed['minor']}, Patch: {parsed['patch']}")
            if parsed['pre_release']:
                print(f"    Pre-release: {parsed['pre_release']}")
    
    # Example 3: Detect tag format
    print("\n=== Example 3: Detect tag format ===")
    tag_sets = [
        ['v1.26.3', 'v1.26.2', 'v1.26.1'],
        ['1.26.3', '1.26.2', '1.26.1'],
        ['release-2.0.1', 'release-2.0.0', 'release-1.9.0'],
    ]
    for tags in tag_sets:
        format_pattern = detect_tag_format(tags)
        print(f"  {tags[0]} ... → {format_pattern}")
    
    # Example 4: Compare versions
    print("\n=== Example 4: Compare versions ===")
    comparisons = [
        ('1.26.3', '1.26.2'),
        ('1.26.0', '1.26.0'),
        ('1.25.0', '1.26.0'),
    ]
    for v1, v2 in comparisons:
        result = compare_versions(v1, v2)
        op = '>' if result > 0 else '=' if result == 0 else '<'
        print(f"  {v1} {op} {v2}")
    
    # Example 5: Denormalize versions
    print("\n=== Example 5: Denormalize versions ===")
    denorm_tests = [
        ('1.26.3', 'v{version}'),
        ('2.0.1', 'release-{version}'),
        ('1.9.1', '{version}'),
    ]
    for ver, pattern in denorm_tests:
        denormalized = denormalize_version(ver, pattern)
        print(f"  {ver} + {pattern} → {denormalized}")