"""
Input validation utilities for package names and other user inputs.

Prevents path traversal, injection attacks, and other security issues.
"""

import re
from typing import Optional


class ValidationError(ValueError):
    """Raised when validation fails."""
    pass


def validate_package_name(
    name: str,
    ecosystem: Optional[str] = None,
    max_length: int = 200
) -> str:
    """
    Validate and sanitize package name.
    
    Args:
        name: Package name to validate
        ecosystem: Ecosystem type (npm, pypi, maven, etc.) for specific rules
        max_length: Maximum allowed length
    
    Returns:
        Sanitized package name
    
    Raises:
        ValidationError: If validation fails
    
    Examples:
        >>> validate_package_name("numpy")
        'numpy'
        >>> validate_package_name("@types/node", "npm")
        '@types/node'
        >>> validate_package_name("../../../etc/passwd")
        ValidationError: Invalid characters in package name
    """
    if not name or not isinstance(name, str):
        raise ValidationError("Package name must be a non-empty string")
    
    # Strip whitespace
    name = name.strip()
    
    if not name:
        raise ValidationError("Package name cannot be empty or whitespace only")
    
    # Check length
    if len(name) > max_length:
        raise ValidationError(
            f"Package name too long: {len(name)} characters (max: {max_length})"
        )
    
    # Check for path traversal
    if '..' in name:
        raise ValidationError("Package name contains path traversal sequence (..)")
    
    # Check for absolute paths
    if name.startswith('/') or name.startswith('\\'):
        raise ValidationError("Package name cannot start with path separator")
    
    # Ecosystem-specific validation
    if ecosystem:
        ecosystem = ecosystem.lower()
        
        if ecosystem in ('npm', 'node', 'nodejs', 'javascript'):
            # npm: alphanumeric, -, _, @, /
            # Scoped packages: @scope/package
            if not re.match(r'^[@a-zA-Z0-9_/-]+$', name):
                raise ValidationError(
                    f"Invalid npm package name: {name}. "
                    f"Must contain only alphanumeric, -, _, @, /"
                )
            # Check for valid scoped package format
            if name.startswith('@'):
                if name.count('/') != 1:
                    raise ValidationError(
                        f"Invalid scoped package format: {name}. "
                        f"Must be @scope/package"
                    )
        
        elif ecosystem in ('pypi', 'python'):
            # PyPI: alphanumeric, -, _, .
            if not re.match(r'^[a-zA-Z0-9_.-]+$', name):
                raise ValidationError(
                    f"Invalid PyPI package name: {name}. "
                    f"Must contain only alphanumeric, -, _, ."
                )
        
        elif ecosystem in ('maven', 'java'):
            # Maven: groupId:artifactId or just artifactId
            # Allow alphanumeric, -, _, ., :
            if not re.match(r'^[a-zA-Z0-9_.:/-]+$', name):
                raise ValidationError(
                    f"Invalid Maven artifact name: {name}. "
                    f"Must contain only alphanumeric, -, _, ., :, /"
                )
        
        elif ecosystem in ('packagist', 'php'):
            # Packagist: vendor/package
            if '/' not in name:
                raise ValidationError(
                    f"Invalid Packagist package name: {name}. "
                    f"Must be in vendor/package format"
                )
            if not re.match(r'^[a-zA-Z0-9_-]+/[a-zA-Z0-9_-]+$', name):
                raise ValidationError(
                    f"Invalid Packagist package name: {name}. "
                    f"Must contain only alphanumeric, -, _ in vendor/package format"
                )
        
        elif ecosystem in ('rubygems', 'ruby'):
            # RubyGems: alphanumeric, -, _
            if not re.match(r'^[a-zA-Z0-9_-]+$', name):
                raise ValidationError(
                    f"Invalid RubyGems package name: {name}. "
                    f"Must contain only alphanumeric, -, _"
                )
        
        elif ecosystem == 'go':
            # Go: module path (domain/path/to/module)
            if not re.match(r'^[a-zA-Z0-9._/-]+$', name):
                raise ValidationError(
                    f"Invalid Go module path: {name}. "
                    f"Must contain only alphanumeric, ., -, _, /"
                )
    
    return name


def validate_file_path(path: str, max_length: int = 500) -> str:
    """
    Validate file path for safety.
    
    Args:
        path: File path to validate
        max_length: Maximum allowed length
    
    Returns:
        Sanitized path
    
    Raises:
        ValidationError: If validation fails
    """
    if not path or not isinstance(path, str):
        raise ValidationError("Path must be a non-empty string")
    
    path = path.strip()
    
    if len(path) > max_length:
        raise ValidationError(f"Path too long: {len(path)} (max: {max_length})")
    
    # Check for path traversal
    if '..' in path:
        raise ValidationError("Path contains traversal sequence (..)")
    
    # Check for null bytes
    if '\x00' in path:
        raise ValidationError("Path contains null byte")
    
    return path


def validate_url(url: str, allowed_schemes: Optional[list] = None) -> str:
    """
    Validate URL for safety.
    
    Args:
        url: URL to validate
        allowed_schemes: List of allowed schemes (default: ['http', 'https'])
    
    Returns:
        Validated URL
    
    Raises:
        ValidationError: If validation fails
    """
    if not url or not isinstance(url, str):
        raise ValidationError("URL must be a non-empty string")
    
    url = url.strip()
    
    if allowed_schemes is None:
        allowed_schemes = ['http', 'https']
    
    # Basic URL pattern check
    if not re.match(r'^https?://', url, re.IGNORECASE):
        raise ValidationError(f"URL must start with http:// or https://: {url}")
    
    # Check scheme
    scheme = url.split('://')[0].lower()
    if scheme not in allowed_schemes:
        raise ValidationError(
            f"URL scheme '{scheme}' not allowed. "
            f"Allowed: {', '.join(allowed_schemes)}"
        )
    
    # Check for suspicious patterns
    if any(char in url for char in ['\n', '\r', '\x00']):
        raise ValidationError("URL contains invalid characters")
    
    return url