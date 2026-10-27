"""
Standardized error handling for version fetchers.

Provides consistent error format across all fetchers for better
debugging, monitoring, and data quality analysis.
"""

from datetime import datetime
from typing import Dict, Any, Optional
from enum import Enum


class ErrorType(Enum):
    """Standard error types for version fetchers."""
    VALIDATION = "validation"
    API_ERROR = "api_error"
    RATE_LIMIT = "rate_limit"
    TIMEOUT = "timeout"
    PARSING = "parsing"
    NOT_FOUND = "not_found"
    NETWORK = "network"
    AUTHENTICATION = "authentication"
    UNKNOWN = "unknown"


class StandardError:
    """
    Standardized error format for all fetchers.
    
    Provides consistent structure for error logging and analysis.
    """
    
    @staticmethod
    def create(
        package_name: str,
        ecosystem: str,
        error_type: ErrorType,
        error_message: str,
        **metadata
    ) -> Dict[str, Any]:
        """
        Create a standardized error entry.
        
        Args:
            package_name: Name of the package that failed
            ecosystem: Ecosystem (npm, pypi, maven, etc.)
            error_type: Type of error (from ErrorType enum)
            error_message: Human-readable error message
            **metadata: Additional context (script_path, url, etc.)
        
        Returns:
            Standardized error dictionary
        
        Example:
            >>> error = StandardError.create(
            ...     package_name="express",
            ...     ecosystem="npm",
            ...     error_type=ErrorType.API_ERROR,
            ...     error_message="HTTP 404: Package not found",
            ...     script_path="/build-scripts/e/express/express.sh",
            ...     package_url="https://github.com/expressjs/express"
            ... )
        """
        error_entry = {
            'package_name': package_name,
            'ecosystem': ecosystem.lower(),
            'error_type': error_type.value,
            'error_message': error_message,
            'timestamp': datetime.utcnow().isoformat() + 'Z',
            'metadata': {}
        }
        
        # Add optional metadata
        if metadata:
            error_entry['metadata'] = metadata
        
        return error_entry
    
    @staticmethod
    def from_validation_error(
        package_name: str,
        ecosystem: str,
        validation_error: Exception,
        **metadata
    ) -> Dict[str, Any]:
        """
        Create error from validation exception.
        
        Args:
            package_name: Package name that failed validation
            ecosystem: Ecosystem name
            validation_error: ValidationError exception
            **metadata: Additional context
        
        Returns:
            Standardized error dictionary
        """
        return StandardError.create(
            package_name=package_name,
            ecosystem=ecosystem,
            error_type=ErrorType.VALIDATION,
            error_message=f"Validation failed: {str(validation_error)}",
            **metadata
        )
    
    @staticmethod
    def from_api_error(
        package_name: str,
        ecosystem: str,
        api_error: Exception,
        **metadata
    ) -> Dict[str, Any]:
        """
        Create error from API exception.
        
        Args:
            package_name: Package name
            ecosystem: Ecosystem name
            api_error: API exception
            **metadata: Additional context
        
        Returns:
            Standardized error dictionary
        """
        error_message = str(api_error)
        
        # Detect specific error types
        error_type = ErrorType.API_ERROR
        if 'rate limit' in error_message.lower():
            error_type = ErrorType.RATE_LIMIT
        elif 'timeout' in error_message.lower():
            error_type = ErrorType.TIMEOUT
        elif '404' in error_message or 'not found' in error_message.lower():
            error_type = ErrorType.NOT_FOUND
        elif 'network' in error_message.lower() or 'connection' in error_message.lower():
            error_type = ErrorType.NETWORK
        elif '401' in error_message or '403' in error_message or 'auth' in error_message.lower():
            error_type = ErrorType.AUTHENTICATION
        
        return StandardError.create(
            package_name=package_name,
            ecosystem=ecosystem,
            error_type=error_type,
            error_message=error_message,
            **metadata
        )
    
    @staticmethod
    def from_exception(
        package_name: str,
        ecosystem: str,
        exception: Exception,
        **metadata
    ) -> Dict[str, Any]:
        """
        Create error from generic exception.
        
        Args:
            package_name: Package name
            ecosystem: Ecosystem name
            exception: Any exception
            **metadata: Additional context
        
        Returns:
            Standardized error dictionary
        """
        return StandardError.create(
            package_name=package_name,
            ecosystem=ecosystem,
            error_type=ErrorType.UNKNOWN,
            error_message=f"Unexpected error: {type(exception).__name__}: {str(exception)}",
            **metadata
        )


class ErrorStats:
    """Calculate statistics from error list."""
    
    @staticmethod
    def analyze(errors: list) -> Dict[str, Any]:
        """
        Analyze error list and return statistics.
        
        Args:
            errors: List of standardized error dictionaries
        
        Returns:
            Dictionary with error statistics
        
        Example:
            >>> stats = ErrorStats.analyze(errors)
            >>> print(f"Total errors: {stats['total']}")
            >>> print(f"By type: {stats['by_type']}")
        """
        if not errors:
            return {
                'total': 0,
                'by_type': {},
                'by_ecosystem': {},
                'most_common_type': None,
                'most_common_message': None
            }
        
        # Count by type
        by_type = {}
        for error in errors:
            error_type = error.get('error_type', 'unknown')
            by_type[error_type] = by_type.get(error_type, 0) + 1
        
        # Count by ecosystem
        by_ecosystem = {}
        for error in errors:
            ecosystem = error.get('ecosystem', 'unknown')
            by_ecosystem[ecosystem] = by_ecosystem.get(ecosystem, 0) + 1
        
        # Find most common
        most_common_type = max(by_type.items(), key=lambda x: x[1])[0] if by_type else None
        
        # Count messages
        message_counts = {}
        for error in errors:
            msg = error.get('error_message', '')
            message_counts[msg] = message_counts.get(msg, 0) + 1
        most_common_message = max(message_counts.items(), key=lambda x: x[1])[0] if message_counts else None
        
        return {
            'total': len(errors),
            'by_type': by_type,
            'by_ecosystem': by_ecosystem,
            'most_common_type': most_common_type,
            'most_common_message': most_common_message
        }
    
    @staticmethod
    def print_summary(errors: list, title: str = "ERROR SUMMARY"):
        """
        Print formatted error summary.
        
        Args:
            errors: List of standardized error dictionaries
            title: Title for the summary
        """
        stats = ErrorStats.analyze(errors)
        
        print()
        print("=" * 70)
        print(title)
        print("=" * 70)
        print(f"Total errors: {stats['total']}")
        
        if stats['total'] > 0:
            print()
            print("By Type:")
            for error_type, count in sorted(stats['by_type'].items(), key=lambda x: x[1], reverse=True):
                percentage = (count / stats['total']) * 100
                print(f"  {error_type:20s}: {count:4d} ({percentage:5.1f}%)")
            
            if len(stats['by_ecosystem']) > 1:
                print()
                print("By Ecosystem:")
                for ecosystem, count in sorted(stats['by_ecosystem'].items(), key=lambda x: x[1], reverse=True):
                    percentage = (count / stats['total']) * 100
                    print(f"  {ecosystem:20s}: {count:4d} ({percentage:5.1f}%)")
            
            if stats['most_common_type']:
                print()
                print(f"Most common error type: {stats['most_common_type']}")