"""
Field validation for package documents.

Provides validation for:
- Field types
- Field constraints
- Required fields
- Data format
"""

import logging
import re
from typing import Any, List, Dict, Optional, Tuple
from dataclasses import dataclass


logger = logging.getLogger(__name__)


class ValidationError(Exception):
    """Raised when validation fails."""
    pass


@dataclass
class ValidationResult:
    """Result of validation."""
    is_valid: bool
    errors: List[str]
    warnings: List[str]
    
    def __bool__(self):
        """Allow using result in boolean context."""
        return self.is_valid
    
    def add_error(self, error: str):
        """Add an error."""
        self.errors.append(error)
        self.is_valid = False
    
    def add_warning(self, warning: str):
        """Add a warning."""
        self.warnings.append(warning)


def validate_field(
    field_name: str,
    value: Any,
    field_type: type,
    required: bool = False,
    min_length: Optional[int] = None,
    max_length: Optional[int] = None,
    pattern: Optional[str] = None,
    allowed_values: Optional[List[Any]] = None,
) -> ValidationResult:
    """
    Validate a single field.
    
    Args:
        field_name: Name of the field
        value: Field value
        field_type: Expected type
        required: Whether field is required
        min_length: Minimum length (for strings/lists)
        max_length: Maximum length (for strings/lists)
        pattern: Regex pattern (for strings)
        allowed_values: List of allowed values
    
    Returns:
        ValidationResult
    
    Example:
        >>> result = validate_field('package_name', 'numpy', str, required=True)
        >>> result.is_valid
        True
    """
    result = ValidationResult(is_valid=True, errors=[], warnings=[])
    
    # Check if required
    if required and (value is None or value == ''):
        result.add_error(f"{field_name} is required")
        return result
    
    # Skip further validation if value is None/empty and not required
    if value is None or value == '':
        return result
    
    # Check type
    if not isinstance(value, field_type):
        result.add_error(
            f"{field_name} must be {field_type.__name__}, got {type(value).__name__}"
        )
        return result
    
    # String-specific validation
    if field_type == str:
        # Check length
        if min_length is not None and len(value) < min_length:
            result.add_error(
                f"{field_name} must be at least {min_length} characters"
            )
        
        if max_length is not None and len(value) > max_length:
            result.add_error(
                f"{field_name} must be at most {max_length} characters"
            )
        
        # Check pattern
        if pattern and not re.match(pattern, value):
            result.add_error(
                f"{field_name} does not match required pattern: {pattern}"
            )
    
    # List-specific validation
    elif isinstance(value, list):
        if min_length is not None and len(value) < min_length:
            result.add_error(
                f"{field_name} must have at least {min_length} items"
            )
        
        if max_length is not None and len(value) > max_length:
            result.add_error(
                f"{field_name} must have at most {max_length} items"
            )
    
    # Check allowed values
    if allowed_values is not None and value not in allowed_values:
        result.add_error(
            f"{field_name} must be one of {allowed_values}, got {value}"
        )
    
    return result


def validate_package_document(doc: dict) -> ValidationResult:
    """
    Validate a complete package document.
    
    Args:
        doc: Package document
    
    Returns:
        ValidationResult with all validation errors and warnings
    
    Example:
        >>> doc = {'package_name': 'numpy', 'package_type': 'python', ...}
        >>> result = validate_package_document(doc)
        >>> if not result:
        ...     print(result.errors)
    """
    result = ValidationResult(is_valid=True, errors=[], warnings=[])
    
    # Required fields
    required_fields = ['package_name', 'package_type']
    for field in required_fields:
        if field not in doc or not doc[field]:
            result.add_error(f"Missing required field: {field}")
    
    # Validate package_name
    if 'package_name' in doc:
        field_result = validate_field(
            'package_name',
            doc['package_name'],
            str,
            required=True,
            min_length=1,
            max_length=255
        )
        result.errors.extend(field_result.errors)
        result.warnings.extend(field_result.warnings)
        if not field_result.is_valid:
            result.is_valid = False
    
    # Validate package_type
    if 'package_type' in doc:
        allowed_types = [
            'python', 'node', 'go', 'java', 'ruby', 'rust', 'php', 'c', 'cpp'
        ]
        field_result = validate_field(
            'package_type',
            doc['package_type'],
            str,
            required=True,
            allowed_values=allowed_types
        )
        result.errors.extend(field_result.errors)
        result.warnings.extend(field_result.warnings)
        if not field_result.is_valid:
            result.is_valid = False
        
        # Warn about excluded types
        if doc['package_type'] in ['Anaconda', 'conda']:
            result.add_warning(
                f"Package type {doc['package_type']} will be excluded from migration"
            )
    
    # Validate version
    if 'version_ported' in doc or 'version' in doc:
        version = doc.get('version_ported') or doc.get('version')
        if version and version.lower() == 'unknown':
            result.add_warning("Version is 'Unknown' - quality score will be reduced")
    
    # Validate GitHub URL
    if 'github_url' in doc:
        github_url = doc['github_url']
        if github_url and github_url != 'N/A':
            if 'github.com' not in github_url.lower():
                result.add_error("github_url does not contain 'github.com'")
    
    # Validate URLs
    url_fields = ['github_url', 'repo_url', 'source_code', 'link_build_script', 'link_docker_file']
    for field in url_fields:
        if field in doc and doc[field]:
            value = doc[field]
            if value != 'N/A' and not value.startswith(('http://', 'https://', 'git@', 'ssh://')):
                result.add_warning(f"{field} does not appear to be a valid URL: {value}")
    
    # Validate ppc64le_supported
    if 'ppc64le_supported' in doc:
        allowed_values = ['Supported', 'Not Supported', 'Unknown']
        if doc['ppc64le_supported'] not in allowed_values:
            result.add_warning(
                f"ppc64le_supported has unexpected value: {doc['ppc64le_supported']}"
            )
    
    # Validate ported
    if 'ported' in doc:
        allowed_values = ['Yes', 'No', 'Unknown']
        if doc['ported'] not in allowed_values:
            result.add_warning(
                f"ported has unexpected value: {doc['ported']}"
            )
    
    return result


def validate_normalized_document(doc: dict) -> ValidationResult:
    """
    Validate a normalized package document.
    
    Args:
        doc: Normalized package document
    
    Returns:
        ValidationResult
    
    Example:
        >>> doc = {'normalized_name': 'numpy', 'normalized_ecosystem': 'python', ...}
        >>> result = validate_normalized_document(doc)
    """
    result = ValidationResult(is_valid=True, errors=[], warnings=[])
    
    # Check for normalized fields
    if 'normalized_name' not in doc:
        result.add_error("Missing normalized_name")
    
    if 'normalized_ecosystem' not in doc:
        result.add_error("Missing normalized_ecosystem")
    
    # Check if should be excluded
    if doc.get('should_exclude'):
        result.add_warning("Document is marked for exclusion")
    
    # Validate normalized_version if present
    if 'normalized_version' in doc:
        version = doc['normalized_version']
        if version:
            # Check semantic versioning format
            if not re.match(r'^\d+\.\d+\.\d+', version):
                result.add_warning(
                    f"normalized_version does not follow semantic versioning: {version}"
                )
    
    # Validate normalized_url if present
    if 'normalized_url' in doc:
        url = doc['normalized_url']
        if url and not url.startswith('https://'):
            result.add_warning(
                f"normalized_url should use HTTPS: {url}"
            )
    
    return result


def validate_batch(documents: List[dict]) -> Dict[str, Any]:
    """
    Validate a batch of documents.
    
    Args:
        documents: List of package documents
    
    Returns:
        Dictionary with validation summary:
        {
            'total': 100,
            'valid': 85,
            'invalid': 15,
            'warnings': 20,
            'errors_by_doc': {...}
        }
    
    Example:
        >>> docs = [{'package_name': 'numpy', ...}, ...]
        >>> summary = validate_batch(docs)
        >>> print(f"Valid: {summary['valid']}/{summary['total']}")
    """
    total = len(documents)
    valid = 0
    invalid = 0
    total_warnings = 0
    errors_by_doc = {}
    
    for i, doc in enumerate(documents):
        result = validate_package_document(doc)
        
        if result.is_valid:
            valid += 1
        else:
            invalid += 1
            errors_by_doc[i] = {
                'package_name': doc.get('package_name', 'unknown'),
                'errors': result.errors,
                'warnings': result.warnings,
            }
        
        total_warnings += len(result.warnings)
    
    return {
        'total': total,
        'valid': valid,
        'invalid': invalid,
        'warnings': total_warnings,
        'errors_by_doc': errors_by_doc,
        'validation_rate': valid / total if total > 0 else 0,
    }


# Example usage
if __name__ == '__main__':
    import logging
    logging.basicConfig(level=logging.INFO)
    
    # Example 1: Validate single field
    print("\n=== Example 1: Validate single field ===")
    result = validate_field('package_name', 'numpy', str, required=True, min_length=1)
    print(f"  Valid: {result.is_valid}")
    if result.errors:
        print(f"  Errors: {result.errors}")
    
    # Example 2: Validate complete document (valid)
    print("\n=== Example 2: Validate complete document (valid) ===")
    doc1 = {
        'package_name': 'numpy',
        'package_type': 'python',
        'version_ported': '1.26.3',
        'github_url': 'https://github.com/numpy/numpy',
    }
    result1 = validate_package_document(doc1)
    print(f"  Valid: {result1.is_valid}")
    if result1.errors:
        print(f"  Errors: {result1.errors}")
    if result1.warnings:
        print(f"  Warnings: {result1.warnings}")
    
    # Example 3: Validate complete document (invalid)
    print("\n=== Example 3: Validate complete document (invalid) ===")
    doc2 = {
        'package_name': '',  # Empty
        'package_type': 'invalid_type',  # Not allowed
        'version_ported': 'Unknown',
        'github_url': 'not a url',
    }
    result2 = validate_package_document(doc2)
    print(f"  Valid: {result2.is_valid}")
    if result2.errors:
        print(f"  Errors:")
        for error in result2.errors:
            print(f"    - {error}")
    if result2.warnings:
        print(f"  Warnings:")
        for warning in result2.warnings:
            print(f"    - {warning}")
    
    # Example 4: Validate batch
    print("\n=== Example 4: Validate batch ===")
    docs = [doc1, doc2, doc1, doc1]
    summary = validate_batch(docs)
    print(f"  Total: {summary['total']}")
    print(f"  Valid: {summary['valid']}")
    print(f"  Invalid: {summary['invalid']}")
    print(f"  Validation rate: {summary['validation_rate']:.1%}")