"""
Safe parsing utilities for API responses.

Provides functions for safely parsing JSON with size limits and error handling.
"""

import json
import logging
from typing import Dict, Any, Optional
import requests


logger = logging.getLogger(__name__)


class ParsingError(Exception):
    """Raised when parsing fails."""
    pass


def safe_json_parse(
    response: requests.Response,
    max_size_mb: int = 10,
    expected_type: type = dict
) -> Any:
    """
    Safely parse JSON response with size limits and error handling.
    
    Args:
        response: requests.Response object
        max_size_mb: Maximum allowed response size in MB
        expected_type: Expected type of parsed data (dict, list, etc.)
    
    Returns:
        Parsed JSON data
    
    Raises:
        ParsingError: If parsing fails or data is invalid
    
    Examples:
        >>> response = requests.get("https://api.example.com/data")
        >>> data = safe_json_parse(response)
        >>> data = safe_json_parse(response, max_size_mb=5, expected_type=list)
    """
    # Check response size before parsing
    content_length = response.headers.get('content-length')
    if content_length:
        try:
            size_bytes = int(content_length)
            size_mb = size_bytes / (1024 * 1024)
            
            if size_mb > max_size_mb:
                raise ParsingError(
                    f"Response too large: {size_mb:.2f}MB exceeds limit of {max_size_mb}MB"
                )
            
            logger.debug(f"Response size: {size_mb:.2f}MB")
        except ValueError:
            logger.warning(f"Invalid content-length header: {content_length}")
    
    # Parse JSON with error handling
    try:
        data = response.json()
    except json.JSONDecodeError as e:
        # Log first 200 chars of response for debugging
        preview = response.text[:200] if response.text else "(empty)"
        raise ParsingError(
            f"Invalid JSON response: {e}. Preview: {preview}..."
        )
    except Exception as e:
        raise ParsingError(f"Failed to parse JSON: {e}")
    
    # Validate type
    if not isinstance(data, expected_type):
        raise ParsingError(
            f"Expected {expected_type.__name__}, got {type(data).__name__}"
        )
    
    return data


def safe_dict_get(
    data: Dict[str, Any],
    key: str,
    default: Any = None,
    required: bool = False,
    expected_type: Optional[type] = None
) -> Any:
    """
    Safely get value from dictionary with type checking.
    
    Args:
        data: Dictionary to get value from
        key: Key to retrieve
        default: Default value if key not found
        required: If True, raise error if key not found
        expected_type: Expected type of value
    
    Returns:
        Value from dictionary
    
    Raises:
        ParsingError: If required key missing or type mismatch
    
    Examples:
        >>> data = {"name": "test", "count": 42}
        >>> safe_dict_get(data, "name", expected_type=str)
        'test'
        >>> safe_dict_get(data, "missing", default="default")
        'default'
        >>> safe_dict_get(data, "required", required=True)
        ParsingError: Required key 'required' not found
    """
    if key not in data:
        if required:
            raise ParsingError(f"Required key '{key}' not found in data")
        return default
    
    value = data[key]
    
    if expected_type is not None and value is not None:
        if not isinstance(value, expected_type):
            raise ParsingError(
                f"Key '{key}': expected {expected_type.__name__}, "
                f"got {type(value).__name__}"
            )
    
    return value


def safe_list_get(
    data: list,
    index: int,
    default: Any = None,
    expected_type: Optional[type] = None
) -> Any:
    """
    Safely get value from list with bounds checking.
    
    Args:
        data: List to get value from
        index: Index to retrieve
        default: Default value if index out of bounds
        expected_type: Expected type of value
    
    Returns:
        Value from list
    
    Raises:
        ParsingError: If type mismatch
    """
    if not isinstance(data, list):
        raise ParsingError(f"Expected list, got {type(data).__name__}")
    
    if index < 0 or index >= len(data):
        return default
    
    value = data[index]
    
    if expected_type is not None and value is not None:
        if not isinstance(value, expected_type):
            raise ParsingError(
                f"Index {index}: expected {expected_type.__name__}, "
                f"got {type(value).__name__}"
            )
    
    return value


def validate_version_string(version: str) -> bool:
    """
    Validate that a string looks like a version number.
    
    Args:
        version: Version string to validate
    
    Returns:
        True if valid, False otherwise
    
    Examples:
        >>> validate_version_string("1.2.3")
        True
        >>> validate_version_string("v1.2.3")
        True
        >>> validate_version_string("not-a-version")
        False
    """
    if not version or not isinstance(version, str):
        return False
    
    # Strip common prefixes
    version = version.lstrip('vV')
    
    # Check for version-like pattern (numbers and dots/dashes)
    import re
    return bool(re.match(r'^\d+[\d.\-a-zA-Z]*$', version))