"""
URL normalization for package repositories.

Features:
- GitHub URL standardization
- Registry URL normalization
- URL parsing and validation
"""

import logging
import re
from typing import Optional, Tuple, Dict, Any
from urllib.parse import urlparse, urlunparse


logger = logging.getLogger(__name__)


def normalize_github_url(url: str) -> Optional[str]:
    """
    Normalize GitHub URL to canonical HTTPS format.
    
    Converts various GitHub URL formats to:
    https://github.com/owner/repo
    
    Args:
        url: GitHub URL in any format
    
    Returns:
        Normalized GitHub URL or None if invalid
    
    Example:
        >>> normalize_github_url('git@github.com:numpy/numpy.git')
        'https://github.com/numpy/numpy'
        >>> normalize_github_url('https://github.com/numpy/numpy/')
        'https://github.com/numpy/numpy'
        >>> normalize_github_url('github.com/numpy/numpy')
        'https://github.com/numpy/numpy'
    """
    if not url:
        return None
    
    url = url.strip()
    
    # Remove .git suffix
    if url.endswith('.git'):
        url = url[:-4]
    
    # Remove trailing slashes
    url = url.rstrip('/')
    
    # Handle git@ SSH format
    if url.startswith('git@github.com:'):
        # git@github.com:owner/repo → https://github.com/owner/repo
        path = url.replace('git@github.com:', '')
        return f'https://github.com/{path}'
    
    # Handle ssh:// format
    if url.startswith('ssh://git@github.com/'):
        path = url.replace('ssh://git@github.com/', '')
        return f'https://github.com/{path}'
    
    # Handle URLs without protocol
    if url.startswith('github.com/'):
        return f'https://{url}'
    
    # Handle URLs with protocol
    if url.startswith(('http://', 'https://')):
        parsed = urlparse(url)
        if parsed.netloc == 'github.com':
            # Ensure HTTPS
            return f'https://github.com{parsed.path}'
    
    # Try to extract owner/repo pattern
    match = re.search(r'github\.com[:/]([^/]+/[^/]+)', url)
    if match:
        return f'https://github.com/{match.group(1)}'
    
    logger.warning(f"Could not normalize GitHub URL: {url}")
    return None


def parse_github_url(url: str) -> Optional[Tuple[str, str]]:
    """
    Parse GitHub URL to extract owner and repo.
    
    Args:
        url: GitHub URL
    
    Returns:
        Tuple of (owner, repo) or None if invalid
    
    Example:
        >>> parse_github_url('https://github.com/numpy/numpy')
        ('numpy', 'numpy')
        >>> parse_github_url('git@github.com:expressjs/express.git')
        ('expressjs', 'express')
    """
    normalized = normalize_github_url(url)
    if not normalized:
        return None
    
    # Extract owner/repo from normalized URL
    match = re.search(r'github\.com/([^/]+)/([^/]+)', normalized)
    if match:
        return match.group(1), match.group(2)
    
    return None


def normalize_registry_url(url: str, registry_type: str) -> Optional[str]:
    """
    Normalize package registry URL.
    
    Args:
        url: Registry URL
        registry_type: Type of registry (pypi, npm, maven, go)
    
    Returns:
        Normalized registry URL or None if invalid
    
    Example:
        >>> normalize_registry_url('pypi.org/project/numpy/', 'pypi')
        'https://pypi.org/project/numpy'
        >>> normalize_registry_url('registry.npmjs.org/express', 'npm')
        'https://registry.npmjs.org/express'
    """
    if not url:
        return None
    
    url = url.strip().rstrip('/')
    
    # Add protocol if missing
    if not url.startswith(('http://', 'https://')):
        url = f'https://{url}'
    
    parsed = urlparse(url)
    
    # Registry-specific normalization
    if registry_type == 'pypi':
        # Normalize to pypi.org
        if 'pypi' in parsed.netloc:
            # Extract package name from path
            match = re.search(r'/project/([^/]+)', parsed.path)
            if match:
                package = match.group(1)
                return f'https://pypi.org/project/{package}'
    
    elif registry_type == 'npm':
        # Normalize to registry.npmjs.org
        if 'npm' in parsed.netloc:
            # Keep path as-is
            return f'https://registry.npmjs.org{parsed.path}'
    
    elif registry_type == 'maven':
        # Maven Central
        if 'maven' in parsed.netloc or 'sonatype' in parsed.netloc:
            return f'https://search.maven.org{parsed.path}'
    
    elif registry_type == 'go':
        # Go module proxy
        if 'golang' in parsed.netloc or 'proxy.golang.org' in url:
            return f'https://proxy.golang.org{parsed.path}'
    
    # Return as-is if no specific normalization
    return urlunparse((
        'https',  # Always use HTTPS
        parsed.netloc,
        parsed.path,
        '',  # params
        '',  # query
        ''   # fragment
    ))


def is_valid_url(url: str) -> Tuple[bool, str]:
    """
    Validate URL format.
    
    Args:
        url: URL string
    
    Returns:
        Tuple of (is_valid, error_message)
    
    Example:
        >>> is_valid_url('https://github.com/numpy/numpy')
        (True, '')
        >>> is_valid_url('not a url')
        (False, 'Invalid URL format')
    """
    if not url or not url.strip():
        return False, 'URL cannot be empty'
    
    url = url.strip()
    
    # Check for basic URL structure
    if not re.match(r'^[a-zA-Z][a-zA-Z0-9+.-]*:', url):
        # No protocol - check if it looks like a domain
        if not re.match(r'^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}', url):
            return False, 'Invalid URL format'
    
    try:
        parsed = urlparse(url)
        
        # Must have netloc (domain)
        if not parsed.netloc and not parsed.path:
            return False, 'URL must have a domain'
        
        return True, ''
    
    except Exception as e:
        return False, f'Invalid URL: {e}'


def is_github_url(url: str) -> bool:
    """
    Check if URL is a GitHub URL.
    
    Args:
        url: URL string
    
    Returns:
        True if GitHub URL, False otherwise
    
    Example:
        >>> is_github_url('https://github.com/numpy/numpy')
        True
        >>> is_github_url('https://pypi.org/project/numpy')
        False
    """
    if not url:
        return False
    
    return 'github.com' in url.lower()


def extract_domain(url: str) -> Optional[str]:
    """
    Extract domain from URL.
    
    Args:
        url: URL string
    
    Returns:
        Domain name or None if invalid
    
    Example:
        >>> extract_domain('https://github.com/numpy/numpy')
        'github.com'
        >>> extract_domain('https://pypi.org/project/numpy')
        'pypi.org'
    """
    if not url:
        return None
    
    try:
        # Add protocol if missing
        if not url.startswith(('http://', 'https://', 'git@', 'ssh://')):
            url = f'https://{url}'
        
        # Handle git@ format
        if url.startswith('git@'):
            match = re.search(r'git@([^:]+):', url)
            if match:
                return match.group(1)
        
        parsed = urlparse(url)
        return parsed.netloc if parsed.netloc else None
    
    except Exception:
        return None


def normalize_url_data(data: dict) -> dict:
    """
    Normalize URL data dictionary.
    
    Args:
        data: URL data dictionary with 'url' and optionally 'type'
    
    Returns:
        Normalized dictionary with additional fields
    
    Example:
        >>> data = {'url': 'github.com/numpy/numpy', 'type': 'github'}
        >>> normalized = normalize_url_data(data)
        >>> normalized['normalized_url']
        'https://github.com/numpy/numpy'
    """
    result = data.copy()
    
    url = data.get('url', '')
    url_type = data.get('type', 'unknown')
    
    # Normalize based on type
    if url_type == 'github' or is_github_url(url):
        normalized = normalize_github_url(url)
        result['url_type'] = 'github'
        
        # Parse GitHub URL
        if normalized:
            parsed = parse_github_url(normalized)
            if parsed:
                result['owner'] = parsed[0]
                result['repo'] = parsed[1]
    
    elif url_type in ['pypi', 'npm', 'maven', 'go']:
        normalized = normalize_registry_url(url, url_type)
    
    else:
        # Generic URL normalization
        if not url.startswith(('http://', 'https://')):
            normalized = f'https://{url}'
        else:
            normalized = url
        
        # Remove trailing slash
        normalized = normalized.rstrip('/')
    
    result['normalized_url'] = normalized
    
    # Extract domain
    domain = extract_domain(url)
    if domain:
        result['domain'] = domain
    
    # Validate
    is_valid, error = is_valid_url(url)
    result['is_valid'] = is_valid
    result['validation_error'] = error if error else None
    
    return result


# Example usage
if __name__ == '__main__':
    import logging
    logging.basicConfig(level=logging.INFO)
    
    # Example 1: Normalize GitHub URLs
    print("\n=== Example 1: Normalize GitHub URLs ===")
    github_urls = [
        'git@github.com:numpy/numpy.git',
        'https://github.com/numpy/numpy/',
        'github.com/numpy/numpy',
        'http://github.com/expressjs/express',
    ]
    for url in github_urls:
        normalized = normalize_github_url(url)
        print(f"  {url}")
        print(f"    → {normalized}")
    
    # Example 2: Parse GitHub URLs
    print("\n=== Example 2: Parse GitHub URLs ===")
    for url in github_urls:
        parsed = parse_github_url(url)
        if parsed:
            print(f"  {url}")
            print(f"    → owner: {parsed[0]}, repo: {parsed[1]}")
    
    # Example 3: Normalize registry URLs
    print("\n=== Example 3: Normalize registry URLs ===")
    registry_urls = [
        ('pypi.org/project/numpy/', 'pypi'),
        ('registry.npmjs.org/express', 'npm'),
        ('search.maven.org/artifact/org.springframework.boot/spring-boot-starter', 'maven'),
    ]
    for url, reg_type in registry_urls:
        normalized = normalize_registry_url(url, reg_type)
        print(f"  {url} ({reg_type})")
        print(f"    → {normalized}")
    
    # Example 4: Validate URLs
    print("\n=== Example 4: Validate URLs ===")
    test_urls = [
        'https://github.com/numpy/numpy',
        'not a url',
        '',
        'github.com/numpy/numpy',
    ]
    for url in test_urls:
        is_valid, error = is_valid_url(url)
        status = "✓" if is_valid else "✗"
        print(f"  {status} {url!r}: {error if error else 'Valid'}")
    
    # Example 5: Extract domains
    print("\n=== Example 5: Extract domains ===")
    for url in github_urls:
        domain = extract_domain(url)
        print(f"  {url}")
        print(f"    → {domain}")