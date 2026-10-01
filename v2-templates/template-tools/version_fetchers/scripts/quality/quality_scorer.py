"""
Quality score calculation for package documents.

Scoring breakdown (0-100):
- GitHub information: 30 points
- Version information: 30 points
- Build information: 20 points
- Metadata completeness: 10 points
- Data freshness: 10 points

Quality levels:
- Complete: 90-100 points
- Good: 70-89 points
- Partial: 40-69 points
- Poor: 0-39 points
"""

import logging
from typing import Dict, Any, Tuple
from datetime import datetime, timezone, timedelta


logger = logging.getLogger(__name__)


def score_github_info(doc: dict) -> Tuple[int, list]:
    """
    Score GitHub information completeness (0-30 points).
    
    Scoring:
    - Has GitHub URL: 10 points
    - Has valid GitHub URL format: 5 points
    - Has repository metadata: 10 points
    - Has tag format detected: 5 points
    
    Args:
        doc: Package document
    
    Returns:
        Tuple of (score, details)
    
    Example:
        >>> doc = {'github_url': 'https://github.com/numpy/numpy', ...}
        >>> score, details = score_github_info(doc)
    """
    score = 0
    details = []
    
    # Has GitHub URL (10 points)
    github_url = doc.get('github_url') or doc.get('repo_url') or doc.get('source_code')
    if github_url and github_url.strip() and github_url != 'N/A':
        score += 10
        details.append("Has GitHub URL (+10)")
        
        # Valid GitHub URL format (5 points)
        if 'github.com' in github_url.lower():
            score += 5
            details.append("Valid GitHub URL (+5)")
    else:
        details.append("Missing GitHub URL (-10)")
    
    # Has repository metadata (10 points)
    has_metadata = any([
        doc.get('description'),
        doc.get('license'),
        doc.get('stars'),
        doc.get('forks'),
    ])
    if has_metadata:
        score += 10
        details.append("Has repository metadata (+10)")
    
    # Has tag format detected (5 points)
    if doc.get('tag_format') or doc.get('version_format'):
        score += 5
        details.append("Has tag format (+5)")
    
    return score, details


def score_version_info(doc: dict) -> Tuple[int, list]:
    """
    Score version information completeness (0-30 points).
    
    Scoring:
    - Has version: 10 points
    - Version is not "Unknown": 10 points
    - Has normalized version: 5 points
    - Has version mapping: 5 points
    
    Args:
        doc: Package document
    
    Returns:
        Tuple of (score, details)
    """
    score = 0
    details = []
    
    # Has version (10 points)
    version = doc.get('version_ported') or doc.get('version') or doc.get('available_versions')
    if version and version.strip():
        score += 10
        details.append("Has version (+10)")
        
        # Version is not "Unknown" (10 points)
        if version.lower() not in ['unknown', 'n/a', 'none', '']:
            score += 10
            details.append("Version is known (+10)")
        else:
            details.append("Version is Unknown (-10)")
    else:
        details.append("Missing version (-20)")
    
    # Has normalized version (5 points)
    if doc.get('normalized_version'):
        score += 5
        details.append("Has normalized version (+5)")
    
    # Has version mapping (5 points)
    if doc.get('version_mapping') or doc.get('version_mappings'):
        score += 5
        details.append("Has version mapping (+5)")
    
    return score, details


def score_build_info(doc: dict) -> Tuple[int, list]:
    """
    Score build information completeness (0-20 points).
    
    Scoring:
    - Has build script: 10 points
    - Has Docker file: 5 points
    - Has CI engine: 5 points
    
    Args:
        doc: Package document
    
    Returns:
        Tuple of (score, details)
    """
    score = 0
    details = []
    
    # Has build script (10 points)
    build_script = doc.get('link_build_script') or doc.get('build_script')
    if build_script and build_script.strip() and build_script != 'N/A':
        score += 10
        details.append("Has build script (+10)")
    
    # Has Docker file (5 points)
    docker_file = doc.get('link_docker_file') or doc.get('dockerfile')
    if docker_file and docker_file.strip() and docker_file != 'N/A':
        score += 5
        details.append("Has Docker file (+5)")
    
    # Has CI engine (5 points)
    ci_engine = doc.get('ci_engine')
    if ci_engine and ci_engine.strip() and ci_engine != 'N/A':
        score += 5
        details.append("Has CI engine (+5)")
    
    return score, details


def score_metadata_completeness(doc: dict) -> Tuple[int, list]:
    """
    Score metadata completeness (0-10 points).
    
    Scoring:
    - Has package name: 3 points
    - Has package type/ecosystem: 3 points
    - Has description or summary: 2 points
    - Has license: 2 points
    
    Args:
        doc: Package document
    
    Returns:
        Tuple of (score, details)
    """
    score = 0
    details = []
    
    # Has package name (3 points)
    package_name = doc.get('package_name')
    if package_name and package_name.strip():
        score += 3
        details.append("Has package name (+3)")
    
    # Has package type/ecosystem (3 points)
    package_type = doc.get('package_type') or doc.get('ecosystem')
    if package_type and package_type.strip():
        score += 3
        details.append("Has package type (+3)")
    
    # Has description or summary (2 points)
    description = doc.get('description') or doc.get('summary')
    if description and description.strip():
        score += 2
        details.append("Has description (+2)")
    
    # Has license (2 points)
    license_info = doc.get('license')
    if license_info and license_info.strip():
        score += 2
        details.append("Has license (+2)")
    
    return score, details


def score_data_freshness(doc: dict) -> Tuple[int, list]:
    """
    Score data freshness (0-10 points).
    
    Scoring:
    - Updated within last 30 days: 10 points
    - Updated within last 90 days: 7 points
    - Updated within last 180 days: 5 points
    - Updated within last year: 3 points
    - Older than 1 year: 0 points
    
    Args:
        doc: Package document
    
    Returns:
        Tuple of (score, details)
    """
    score = 0
    details = []
    
    # Get last updated date
    last_updated = doc.get('last_updated') or doc.get('updated_at') or doc.get('modified')
    
    if not last_updated:
        details.append("No update date (-10)")
        return score, details
    
    try:
        # Parse date
        if isinstance(last_updated, str):
            from dateutil import parser as date_parser
            updated_dt = date_parser.parse(last_updated)
        elif isinstance(last_updated, datetime):
            updated_dt = last_updated
        else:
            details.append("Invalid date format (-10)")
            return score, details
        
        # Ensure UTC
        if updated_dt.tzinfo is None:
            updated_dt = updated_dt.replace(tzinfo=timezone.utc)
        
        # Calculate age
        now = datetime.now(timezone.utc)
        age = now - updated_dt
        
        if age <= timedelta(days=30):
            score = 10
            details.append("Updated within 30 days (+10)")
        elif age <= timedelta(days=90):
            score = 7
            details.append("Updated within 90 days (+7)")
        elif age <= timedelta(days=180):
            score = 5
            details.append("Updated within 180 days (+5)")
        elif age <= timedelta(days=365):
            score = 3
            details.append("Updated within 1 year (+3)")
        else:
            details.append(f"Updated {age.days} days ago (-10)")
    
    except Exception as e:
        logger.warning(f"Could not parse date {last_updated}: {e}")
        details.append(f"Date parse error (-10)")
    
    return score, details


def calculate_quality_score(doc: dict) -> Dict[str, Any]:
    """
    Calculate overall quality score for a package document.
    
    Args:
        doc: Package document
    
    Returns:
        Dictionary with quality score and breakdown:
        {
            'total_score': 85,
            'quality_level': 'good',
            'breakdown': {
                'github_info': {'score': 25, 'max': 30, 'details': [...]},
                'version_info': {'score': 30, 'max': 30, 'details': [...]},
                'build_info': {'score': 15, 'max': 20, 'details': [...]},
                'metadata': {'score': 8, 'max': 10, 'details': [...]},
                'freshness': {'score': 7, 'max': 10, 'details': [...]}
            }
        }
    
    Example:
        >>> doc = {'package_name': 'numpy', 'github_url': '...', ...}
        >>> result = calculate_quality_score(doc)
        >>> result['total_score']
        85
        >>> result['quality_level']
        'good'
    """
    # Calculate individual scores
    github_score, github_details = score_github_info(doc)
    version_score, version_details = score_version_info(doc)
    build_score, build_details = score_build_info(doc)
    metadata_score, metadata_details = score_metadata_completeness(doc)
    freshness_score, freshness_details = score_data_freshness(doc)
    
    # Calculate total
    total_score = (
        github_score +
        version_score +
        build_score +
        metadata_score +
        freshness_score
    )
    
    # Determine quality level
    quality_level = get_quality_level(total_score)
    
    return {
        'total_score': total_score,
        'quality_level': quality_level,
        'breakdown': {
            'github_info': {
                'score': github_score,
                'max': 30,
                'details': github_details
            },
            'version_info': {
                'score': version_score,
                'max': 30,
                'details': version_details
            },
            'build_info': {
                'score': build_score,
                'max': 20,
                'details': build_details
            },
            'metadata': {
                'score': metadata_score,
                'max': 10,
                'details': metadata_details
            },
            'freshness': {
                'score': freshness_score,
                'max': 10,
                'details': freshness_details
            }
        }
    }


def get_quality_level(score: int) -> str:
    """
    Convert quality score to quality level.
    
    Args:
        score: Quality score (0-100)
    
    Returns:
        Quality level: 'complete', 'good', 'partial', or 'poor'
    
    Example:
        >>> get_quality_level(95)
        'complete'
        >>> get_quality_level(75)
        'good'
        >>> get_quality_level(50)
        'partial'
        >>> get_quality_level(25)
        'poor'
    """
    if score >= 90:
        return 'complete'
    elif score >= 70:
        return 'good'
    elif score >= 40:
        return 'partial'
    else:
        return 'poor'


# Example usage
if __name__ == '__main__':
    import logging
    logging.basicConfig(level=logging.INFO)
    
    # Example 1: High quality document
    print("\n=== Example 1: High quality document ===")
    doc1 = {
        'package_name': 'numpy',
        'package_type': 'python',
        'version_ported': '1.26.3',
        'github_url': 'https://github.com/numpy/numpy',
        'description': 'Fundamental package for array computing',
        'license': 'BSD-3-Clause',
        'link_build_script': 'https://example.com/build.sh',
        'link_docker_file': 'https://example.com/Dockerfile',
        'ci_engine': 'GitHub Actions',
        'last_updated': '2024-01-15T00:00:00Z',
        'normalized_version': '1.26.3',
        'version_mapping': {'github': 'v1.26.3'},
        'tag_format': 'v{version}',
    }
    result1 = calculate_quality_score(doc1)
    print(f"  Total Score: {result1['total_score']}/100")
    print(f"  Quality Level: {result1['quality_level']}")
    print("  Breakdown:")
    for category, data in result1['breakdown'].items():
        print(f"    {category}: {data['score']}/{data['max']}")
    
    # Example 2: Low quality document
    print("\n=== Example 2: Low quality document ===")
    doc2 = {
        'package_name': 'unknown-package',
        'package_type': 'python',
        'version_ported': 'Unknown',
        'github_url': 'N/A',
        'link_build_script': 'N/A',
    }
    result2 = calculate_quality_score(doc2)
    print(f"  Total Score: {result2['total_score']}/100")
    print(f"  Quality Level: {result2['quality_level']}")
    print("  Breakdown:")
    for category, data in result2['breakdown'].items():
        print(f"    {category}: {data['score']}/{data['max']}")
        if data['details']:
            for detail in data['details']:
                print(f"      - {detail}")