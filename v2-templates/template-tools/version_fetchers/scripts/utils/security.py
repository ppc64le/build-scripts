"""
Security utilities for safe handling of sensitive data.

Provides functions for masking tokens, sanitizing logs, and preventing
information leakage.
"""

import re
from typing import Optional


def mask_token(token: Optional[str], show_chars: int = 4) -> str:
    """
    Mask sensitive token for safe logging.
    
    Args:
        token: Token to mask (can be None)
        show_chars: Number of characters to show at start/end
    
    Returns:
        Masked token string safe for logging
    
    Examples:
        >>> mask_token("ghp_1234567890abcdef")
        'ghp_...cdef'
        >>> mask_token(None)
        'None'
        >>> mask_token("short")
        '***'
    """
    if not token:
        return "None"
    
    if not isinstance(token, str):
        return "***"
    
    if len(token) < show_chars * 2:
        return "***"
    
    return f"{token[:show_chars]}...{token[-show_chars:]}"


def mask_url_credentials(url: str) -> str:
    """
    Mask credentials in URLs for safe logging.
    
    Args:
        url: URL that may contain credentials
    
    Returns:
        URL with credentials masked
    
    Examples:
        >>> mask_url_credentials("https://user:pass@github.com/repo")
        'https://***:***@github.com/repo'
    """
    if not url:
        return url
    
    # Match URLs with credentials: protocol://user:pass@host
    pattern = r'(https?://)[^:]+:[^@]+@'
    return re.sub(pattern, r'\1***:***@', url)


def sanitize_error_message(message: str, sensitive_patterns: Optional[list] = None) -> str:
    """
    Remove sensitive data from error messages.
    
    Args:
        message: Error message to sanitize
        sensitive_patterns: Additional regex patterns to mask
    
    Returns:
        Sanitized error message
    """
    if not message:
        return message
    
    # Default patterns to mask
    patterns = [
        (r'ghp_[a-zA-Z0-9]{36}', 'ghp_***'),  # GitHub personal access tokens
        (r'github_pat_[a-zA-Z0-9_]{82}', 'github_pat_***'),  # GitHub fine-grained tokens
        (r'gho_[a-zA-Z0-9]{36}', 'gho_***'),  # GitHub OAuth tokens
        (r'Bearer [a-zA-Z0-9_\-\.]+', 'Bearer ***'),  # Bearer tokens
        (r'token [a-zA-Z0-9_\-\.]+', 'token ***'),  # Generic tokens
    ]
    
    # Add custom patterns
    if sensitive_patterns:
        patterns.extend(sensitive_patterns)
    
    result = message
    for pattern, replacement in patterns:
        result = re.sub(pattern, replacement, result, flags=re.IGNORECASE)
    
    return result