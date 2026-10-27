"""
Date normalization for timestamps.

Features:
- Parse various date formats
- Convert to ISO 8601 UTC
- Validation
"""

import logging
import re
from typing import Optional, Tuple
from datetime import datetime, timezone
from dateutil import parser as date_parser


logger = logging.getLogger(__name__)


def normalize_date(date_input: any) -> Optional[str]:
    """
    Normalize date to ISO 8601 UTC format.
    
    Accepts:
    - ISO 8601 strings
    - Unix timestamps (int or float)
    - datetime objects
    - Various date string formats
    
    Args:
        date_input: Date in any supported format
    
    Returns:
        ISO 8601 UTC string (YYYY-MM-DDTHH:MM:SS.ffffffZ) or None if invalid
    
    Example:
        >>> normalize_date('2024-01-15T10:30:00Z')
        '2024-01-15T10:30:00.000000Z'
        >>> normalize_date(1705318200)
        '2024-01-15T10:30:00.000000Z'
        >>> normalize_date('Jan 15, 2024 10:30 AM')
        '2024-01-15T10:30:00.000000Z'
    """
    if date_input is None:
        return None
    
    try:
        # Handle datetime objects
        if isinstance(date_input, datetime):
            dt = date_input
        
        # Handle Unix timestamps (int or float)
        elif isinstance(date_input, (int, float)):
            # Check if it's in milliseconds (> year 2100 in seconds)
            if date_input > 4102444800:  # 2100-01-01 in seconds
                date_input = date_input / 1000
            dt = datetime.fromtimestamp(date_input, tz=timezone.utc)
        
        # Handle string dates
        elif isinstance(date_input, str):
            date_input = date_input.strip()
            
            if not date_input:
                return None
            
            # Try to parse with dateutil (handles many formats)
            dt = date_parser.parse(date_input)
        
        else:
            logger.warning(f"Unsupported date type: {type(date_input)}")
            return None
        
        # Convert to UTC if not already
        if dt.tzinfo is None:
            # Assume UTC if no timezone
            dt = dt.replace(tzinfo=timezone.utc)
        elif dt.tzinfo != timezone.utc:
            dt = dt.astimezone(timezone.utc)
        
        # Format as ISO 8601 with microseconds
        return dt.strftime('%Y-%m-%dT%H:%M:%S.%fZ')
    
    except Exception as e:
        logger.warning(f"Could not normalize date {date_input}: {e}")
        return None


def parse_date(date_str: str) -> Optional[datetime]:
    """
    Parse date string to datetime object.
    
    Args:
        date_str: Date string in any format
    
    Returns:
        datetime object in UTC or None if invalid
    
    Example:
        >>> dt = parse_date('2024-01-15T10:30:00Z')
        >>> dt.year
        2024
    """
    if not date_str:
        return None
    
    try:
        dt = date_parser.parse(date_str)
        
        # Convert to UTC
        if dt.tzinfo is None:
            dt = dt.replace(tzinfo=timezone.utc)
        elif dt.tzinfo != timezone.utc:
            dt = dt.astimezone(timezone.utc)
        
        return dt
    
    except Exception as e:
        logger.warning(f"Could not parse date {date_str}: {e}")
        return None


def format_iso8601(dt: datetime) -> str:
    """
    Format datetime as ISO 8601 string.
    
    Args:
        dt: datetime object
    
    Returns:
        ISO 8601 string
    
    Example:
        >>> dt = datetime(2024, 1, 15, 10, 30, 0, tzinfo=timezone.utc)
        >>> format_iso8601(dt)
        '2024-01-15T10:30:00.000000Z'
    """
    # Ensure UTC
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    elif dt.tzinfo != timezone.utc:
        dt = dt.astimezone(timezone.utc)
    
    return dt.strftime('%Y-%m-%dT%H:%M:%S.%fZ')


def is_valid_date(date_str: str) -> Tuple[bool, str]:
    """
    Validate date string.
    
    Args:
        date_str: Date string
    
    Returns:
        Tuple of (is_valid, error_message)
    
    Example:
        >>> is_valid_date('2024-01-15T10:30:00Z')
        (True, '')
        >>> is_valid_date('invalid date')
        (False, 'Invalid date format')
    """
    if not date_str or not date_str.strip():
        return False, 'Date cannot be empty'
    
    try:
        date_parser.parse(date_str)
        return True, ''
    except Exception as e:
        return False, f'Invalid date format: {e}'


def compare_dates(date1: str, date2: str) -> int:
    """
    Compare two date strings.
    
    Args:
        date1: First date string
        date2: Second date string
    
    Returns:
        -1 if date1 < date2
         0 if date1 == date2
         1 if date1 > date2
    
    Example:
        >>> compare_dates('2024-01-15', '2024-01-14')
        1
        >>> compare_dates('2024-01-15', '2024-01-15')
        0
    """
    try:
        dt1 = parse_date(date1)
        dt2 = parse_date(date2)
        
        if dt1 is None or dt2 is None:
            return 0
        
        if dt1 < dt2:
            return -1
        elif dt1 > dt2:
            return 1
        else:
            return 0
    
    except Exception as e:
        logger.warning(f"Could not compare dates {date1} and {date2}: {e}")
        return 0


def get_current_timestamp() -> str:
    """
    Get current timestamp in ISO 8601 UTC format.
    
    Returns:
        Current timestamp string
    
    Example:
        >>> timestamp = get_current_timestamp()
        >>> timestamp.endswith('Z')
        True
    """
    return format_iso8601(datetime.now(timezone.utc))


def extract_date_components(date_str: str) -> Optional[dict]:
    """
    Extract date components from date string.
    
    Args:
        date_str: Date string
    
    Returns:
        Dictionary with date components or None if invalid:
        {
            'year': 2024,
            'month': 1,
            'day': 15,
            'hour': 10,
            'minute': 30,
            'second': 0,
            'microsecond': 0
        }
    
    Example:
        >>> components = extract_date_components('2024-01-15T10:30:00Z')
        >>> components['year']
        2024
    """
    dt = parse_date(date_str)
    if dt is None:
        return None
    
    return {
        'year': dt.year,
        'month': dt.month,
        'day': dt.day,
        'hour': dt.hour,
        'minute': dt.minute,
        'second': dt.second,
        'microsecond': dt.microsecond,
    }


def format_date_human(date_str: str) -> Optional[str]:
    """
    Format date in human-readable format.
    
    Args:
        date_str: Date string
    
    Returns:
        Human-readable date string or None if invalid
    
    Example:
        >>> format_date_human('2024-01-15T10:30:00Z')
        'January 15, 2024 at 10:30 AM UTC'
    """
    dt = parse_date(date_str)
    if dt is None:
        return None
    
    return dt.strftime('%B %d, %Y at %I:%M %p UTC')


def normalize_date_data(data: dict) -> dict:
    """
    Normalize date data dictionary.
    
    Args:
        data: Date data dictionary with 'date' field
    
    Returns:
        Normalized dictionary with additional fields
    
    Example:
        >>> data = {'date': '2024-01-15T10:30:00Z'}
        >>> normalized = normalize_date_data(data)
        >>> normalized['normalized_date']
        '2024-01-15T10:30:00.000000Z'
    """
    result = data.copy()
    
    date_input = data.get('date')
    
    # Normalize date
    normalized = normalize_date(date_input)
    result['normalized_date'] = normalized
    
    # Parse date
    if normalized:
        dt = parse_date(normalized)
        if dt:
            result['datetime_object'] = dt
            result['timestamp'] = dt.timestamp()
            result['human_readable'] = format_date_human(normalized)
            
            # Extract components
            components = extract_date_components(normalized)
            if components:
                result['date_components'] = components
    
    # Validate
    if isinstance(date_input, str):
        is_valid, error = is_valid_date(date_input)
        result['is_valid'] = is_valid
        result['validation_error'] = error if error else None
    else:
        result['is_valid'] = normalized is not None
        result['validation_error'] = None if normalized else 'Could not normalize date'
    
    return result


# Example usage
if __name__ == '__main__':
    import logging
    logging.basicConfig(level=logging.INFO)
    
    # Example 1: Normalize various date formats
    print("\n=== Example 1: Normalize various date formats ===")
    dates = [
        '2024-01-15T10:30:00Z',
        '2024-01-15 10:30:00',
        'Jan 15, 2024 10:30 AM',
        '15/01/2024',
        1705318200,  # Unix timestamp
        1705318200000,  # Unix timestamp in milliseconds
    ]
    for date in dates:
        normalized = normalize_date(date)
        print(f"  {date}")
        print(f"    → {normalized}")
    
    # Example 2: Parse dates
    print("\n=== Example 2: Parse dates ===")
    date_strings = [
        '2024-01-15T10:30:00Z',
        'Jan 15, 2024',
        '2024-01-15',
    ]
    for date_str in date_strings:
        dt = parse_date(date_str)
        if dt:
            print(f"  {date_str}")
            print(f"    → {dt}")
    
    # Example 3: Validate dates
    print("\n=== Example 3: Validate dates ===")
    test_dates = [
        '2024-01-15T10:30:00Z',
        'invalid date',
        '',
        '2024-13-45',  # Invalid month/day
    ]
    for date_str in test_dates:
        is_valid, error = is_valid_date(date_str)
        status = "✓" if is_valid else "✗"
        print(f"  {status} {date_str!r}: {error if error else 'Valid'}")
    
    # Example 4: Compare dates
    print("\n=== Example 4: Compare dates ===")
    comparisons = [
        ('2024-01-15', '2024-01-14'),
        ('2024-01-15', '2024-01-15'),
        ('2024-01-14', '2024-01-15'),
    ]
    for d1, d2 in comparisons:
        result = compare_dates(d1, d2)
        op = '>' if result > 0 else '=' if result == 0 else '<'
        print(f"  {d1} {op} {d2}")
    
    # Example 5: Human-readable format
    print("\n=== Example 5: Human-readable format ===")
    for date_str in date_strings:
        human = format_date_human(date_str)
        print(f"  {date_str}")
        print(f"    → {human}")
    
    # Example 6: Current timestamp
    print("\n=== Example 6: Current timestamp ===")
    current = get_current_timestamp()
    print(f"  Current: {current}")