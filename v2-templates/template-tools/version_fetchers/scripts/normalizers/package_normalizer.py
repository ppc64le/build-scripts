"""
Package name and ecosystem normalization.

Features:
- Lowercase conversion for package names
- Ecosystem mapping (Python, python, Anaconda → python)
- Anaconda/conda package exclusion
- Validation rules
"""

import logging
import re
from typing import Optional, Tuple


logger = logging.getLogger(__name__)


# Ecosystem mapping: input → canonical form (None = exclude)
ECOSYSTEM_MAPPING = {
    # Python
    'python': 'python',
    'Python': 'python',
    'PYTHON': 'python',
    'py': 'python',
    'Py': 'python',
    
    # Anaconda/conda - EXCLUDE
    'Anaconda': None,
    'anaconda': None,
    'conda': None,
    'Conda': None,
    'CONDA': None,
    
    # Node.js
    'node': 'node',
    'Node': 'node',
    'NODE': 'node',
    'nodejs': 'node',
    'NodeJS': 'node',
    'npm': 'node',
    'NPM': 'node',
    
    # Go
    'go': 'go',
    'Go': 'go',
    'GO': 'go',
    'golang': 'go',
    'Golang': 'go',
    
    # Java
    'java': 'java',
    'Java': 'java',
    'JAVA': 'java',
    'maven': 'java',
    'Maven': 'java',
    
    # Ruby
    'ruby': 'ruby',
    'Ruby': 'ruby',
    'RUBY': 'ruby',
    'gem': 'ruby',
    'Gem': 'ruby',
    
    # Rust
    'rust': 'rust',
    'Rust': 'rust',
    'RUST': 'rust',
    'cargo': 'rust',
    'Cargo': 'rust',
    
    # PHP
    'php': 'php',
    'PHP': 'php',
    'Php': 'php',
    'composer': 'php',
    'Composer': 'php',
    
    # C/C++
    'c': 'c',
    'C': 'c',
    'cpp': 'cpp',
    'CPP': 'cpp',
    'c++': 'cpp',
    'C++': 'cpp',
}


def normalize_package_name(name: str) -> str:
    """
    Normalize package name to canonical form.
    
    Rules:
    - Convert to lowercase
    - Trim whitespace
    - Replace multiple spaces with single space
    - Remove special characters (except -, _, ., /, @)
    
    Args:
        name: Package name
    
    Returns:
        Normalized package name
    
    Example:
        >>> normalize_package_name("  NumPy  ")
        'numpy'
        >>> normalize_package_name("@types/node")
        '@types/node'
        >>> normalize_package_name("Spring-Boot-Starter")
        'spring-boot-starter'
    """
    if not name:
        return ''
    
    # Trim whitespace
    name = name.strip()
    
    # Convert to lowercase
    name = name.lower()
    
    # Replace multiple spaces with single space
    name = re.sub(r'\s+', ' ', name)
    
    # Remove special characters except allowed ones
    # Allowed: alphanumeric, -, _, ., /, @, space
    name = re.sub(r'[^a-z0-9\-_./@\s]', '', name)
    
    return name


def normalize_ecosystem(ecosystem: str) -> Optional[str]:
    """
    Normalize ecosystem name to canonical form.
    
    Args:
        ecosystem: Ecosystem/package type
    
    Returns:
        Canonical ecosystem name or None if should be excluded or unknown
    
    Example:
        >>> normalize_ecosystem("Python")
        'python'
        >>> normalize_ecosystem("Anaconda")
        None
        >>> normalize_ecosystem("nodejs")
        'node'
        >>> normalize_ecosystem("Unknown")
        None
    """
    if not ecosystem:
        return None
    
    # Trim and get from mapping
    ecosystem = ecosystem.strip()
    canonical = ECOSYSTEM_MAPPING.get(ecosystem)
    
    if canonical is None:
        # Check if it's already in canonical form
        if ecosystem.lower() in ['python', 'node', 'go', 'java', 'ruby', 'rust', 'php', 'c', 'cpp']:
            return ecosystem.lower()
        
        # Unknown ecosystem - return None so caller can log with package context
        return None
    
    return canonical


def should_exclude_package(package_type: str) -> bool:
    """
    Check if package should be excluded from migration.
    
    Exclusion criteria:
    - Anaconda packages
    - conda packages
    
    Args:
        package_type: Package type/ecosystem
    
    Returns:
        True if should be excluded, False otherwise
    
    Example:
        >>> should_exclude_package("Anaconda")
        True
        >>> should_exclude_package("python")
        False
    """
    if not package_type:
        return False
    
    normalized = normalize_ecosystem(package_type)
    return normalized is None


def validate_package_name(name: str) -> Tuple[bool, str]:
    """
    Validate package name.
    
    Rules:
    - Must not be empty
    - Must contain at least one alphanumeric character
    - Must not exceed 255 characters
    - Must not contain only special characters
    
    Args:
        name: Package name
    
    Returns:
        Tuple of (is_valid, error_message)
    
    Example:
        >>> validate_package_name("numpy")
        (True, '')
        >>> validate_package_name("")
        (False, 'Package name cannot be empty')
        >>> validate_package_name("---")
        (False, 'Package name must contain at least one alphanumeric character')
    """
    if not name or not name.strip():
        return False, 'Package name cannot be empty'
    
    name = name.strip()
    
    if len(name) > 255:
        return False, 'Package name exceeds 255 characters'
    
    # Must contain at least one alphanumeric character
    if not re.search(r'[a-zA-Z0-9]', name):
        return False, 'Package name must contain at least one alphanumeric character'
    
    return True, ''


def validate_ecosystem(ecosystem: str) -> Tuple[bool, str]:
    """
    Validate ecosystem name.
    
    Args:
        ecosystem: Ecosystem name
    
    Returns:
        Tuple of (is_valid, error_message)
    
    Example:
        >>> validate_ecosystem("python")
        (True, '')
        >>> validate_ecosystem("Anaconda")
        (False, 'Ecosystem is excluded: Anaconda')
        >>> validate_ecosystem("")
        (False, 'Ecosystem cannot be empty')
    """
    if not ecosystem or not ecosystem.strip():
        return False, 'Ecosystem cannot be empty'
    
    # Check if should be excluded
    if should_exclude_package(ecosystem):
        return False, f'Ecosystem is excluded: {ecosystem}'
    
    # Check if valid ecosystem
    normalized = normalize_ecosystem(ecosystem)
    if normalized is None:
        return False, f'Unknown ecosystem: {ecosystem}'
    
    return True, ''


def get_ecosystem_display_name(ecosystem: str) -> str:
    """
    Get display name for ecosystem.
    
    Args:
        ecosystem: Canonical ecosystem name
    
    Returns:
        Display name
    
    Example:
        >>> get_ecosystem_display_name("python")
        'Python'
        >>> get_ecosystem_display_name("node")
        'Node.js'
    """
    display_names = {
        'python': 'Python',
        'node': 'Node.js',
        'go': 'Go',
        'java': 'Java',
        'ruby': 'Ruby',
        'rust': 'Rust',
        'php': 'PHP',
        'c': 'C',
        'cpp': 'C++',
    }
    
    return display_names.get(ecosystem, ecosystem.capitalize())


def normalize_package_data(data: dict) -> dict:
    """
    Normalize package data dictionary.
    
    Args:
        data: Package data dictionary with 'package_name' and 'package_type'
    
    Returns:
        Normalized dictionary with additional fields:
        - normalized_name: Normalized package name
        - normalized_ecosystem: Normalized ecosystem
        - should_exclude: Whether package should be excluded
        - validation_errors: List of validation errors
    
    Example:
        >>> data = {'package_name': '  NumPy  ', 'package_type': 'Python'}
        >>> normalized = normalize_package_data(data)
        >>> normalized['normalized_name']
        'numpy'
        >>> normalized['normalized_ecosystem']
        'python'
    """
    result = data.copy()
    errors = []
    
    # Normalize package name
    package_name = data.get('package_name', '')
    normalized_name = normalize_package_name(package_name)
    result['normalized_name'] = normalized_name
    
    # Validate package name
    is_valid, error = validate_package_name(package_name)
    if not is_valid:
        errors.append(f"Package name: {error}")
    
    # Normalize ecosystem
    package_type = data.get('package_type', '')
    normalized_ecosystem = normalize_ecosystem(package_type)
    result['normalized_ecosystem'] = normalized_ecosystem
    
    # Check if should exclude
    result['should_exclude'] = should_exclude_package(package_type)
    
    # Validate ecosystem
    is_valid, error = validate_ecosystem(package_type)
    if not is_valid:
        errors.append(f"Ecosystem: {error}")
    
    # Add validation errors
    result['validation_errors'] = errors
    result['is_valid'] = len(errors) == 0
    
    return result


# Example usage
if __name__ == '__main__':
    import logging
    logging.basicConfig(level=logging.INFO)
    
    # Example 1: Normalize package names
    print("\n=== Example 1: Normalize package names ===")
    names = ["  NumPy  ", "Spring-Boot-Starter", "@types/node", "github.com/gin-gonic/gin"]
    for name in names:
        normalized = normalize_package_name(name)
        print(f"  {name!r} → {normalized!r}")
    
    # Example 2: Normalize ecosystems
    print("\n=== Example 2: Normalize ecosystems ===")
    ecosystems = ["Python", "Anaconda", "nodejs", "Go", "maven", "conda"]
    for eco in ecosystems:
        normalized = normalize_ecosystem(eco)
        excluded = should_exclude_package(eco)
        print(f"  {eco!r} → {normalized!r} (exclude: {excluded})")
    
    # Example 3: Validate package names
    print("\n=== Example 3: Validate package names ===")
    test_names = ["numpy", "", "---", "a" * 300]
    for name in test_names:
        is_valid, error = validate_package_name(name)
        status = "✓" if is_valid else "✗"
        print(f"  {status} {name!r}: {error if error else 'Valid'}")
    
    # Example 4: Normalize package data
    print("\n=== Example 4: Normalize package data ===")
    test_data = [
        {'package_name': '  NumPy  ', 'package_type': 'Python'},
        {'package_name': 'express', 'package_type': 'nodejs'},
        {'package_name': 'pandas', 'package_type': 'Anaconda'},
    ]
    for data in test_data:
        normalized = normalize_package_data(data)
        print(f"  {data['package_name']} ({data['package_type']}):")
        print(f"    → {normalized['normalized_name']} ({normalized['normalized_ecosystem']})")
        print(f"    Exclude: {normalized['should_exclude']}, Valid: {normalized['is_valid']}")
        if normalized['validation_errors']:
            print(f"    Errors: {normalized['validation_errors']}")