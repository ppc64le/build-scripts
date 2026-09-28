#!/usr/bin/env python3
"""
Fetch Packagist versions for PHP packages from input file.

Features:
- Reads package list from file (default: php.list)
- Parses various package name formats:
  * Composer package names: symfony/console, doctrine/orm
  * CSV build script lines: "symfony__console","/build-scripts/s/symfony__console/..."
- Fetches all versions from Packagist
- Extracts repository URLs and metadata
- Saves to mapping file for reuse (cache)
- No authentication required
- Incremental fetching with --start and --count

Input Format Examples:
    # Regular package names (vendor/package)
    symfony/console
    doctrine/orm
    guzzlehttp/guzzle
    
    # CSV build script lines (package name in first quoted field, may use __)
    "symfony__console","/build-scripts/s/symfony__console/symfony__console_ubi_8.5.sh","PHP",...

Usage:
    python fetch_packagist_versions.py                           # Fetch all from php.list
    python fetch_packagist_versions.py --input custom.list       # Use custom input file
    python fetch_packagist_versions.py --start 0 --count 10      # First 10 packages
    python fetch_packagist_versions.py --start 10 --count 50     # Next 50 packages
"""

import json
import sys
import argparse
import csv
import re
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Optional

# Add scripts to path
sys.path.insert(0, str(Path(__file__).parent / 'scripts'))

from fetchers.packagist_fetcher import PackagistFetcher, FetcherError
from utils.validation import validate_package_name, ValidationError
from utils.audit_logger import AuditLogger


def read_csv_input(file_path: str) -> List[Dict[str, str]]:
    """
    Read CSV from extract_build_script_info.py.
    
    Args:
        file_path: Path to CSV file
    
    Returns:
        List of package dictionaries
    """
    packages = []
    
    with open(file_path, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            packages.append(row)
    
    return packages


def categorize_source_url(url: str) -> str:
    """
    Categorize source URL by hosting platform.
    
    Args:
        url: Source URL
    
    Returns:
        Platform name (github, gitlab, bitbucket, etc.)
    """
    if not url:
        return 'unknown'
    
    url_lower = url.lower()
    
    if 'github.com' in url_lower or 'github.io' in url_lower:
        return 'github'
    elif 'gitlab.com' in url_lower or 'gitlab.' in url_lower:
        return 'gitlab'
    elif 'bitbucket.org' in url_lower:
        return 'bitbucket'
    elif 'sourceforge.net' in url_lower:
        return 'sourceforge'
    elif 'gitee.com' in url_lower:
        return 'gitee'
    elif 'codeberg.org' in url_lower:
        return 'codeberg'
    elif 'git.sr.ht' in url_lower or 'sourcehut' in url_lower:
        return 'sourcehut'
    else:
        return 'other'


def main():
    # Parse command-line arguments
    parser = argparse.ArgumentParser(
        description='Fetch Packagist versions for PHP packages',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s                              # Fetch all from php.list
  %(prog)s --input custom.list          # Use custom input file
  %(prog)s --start 0 --count 10         # First 10 packages
  %(prog)s --start 10 --count 50        # Next 50 packages
        """
    )
    parser.add_argument('--input', type=str, default='php2.list',
                        help='Input CSV file with package info (default: php2.list)')
    parser.add_argument('--output', type=str, default='packagist_versions.json',
                        help='Output JSON file (default: packagist_versions.json)')
    parser.add_argument('--errors', type=str, default='packagist_errors.json',
                        help='Error log JSON file (default: packagist_errors.json)')
    parser.add_argument('--start', type=int, default=0,
                        help='Start index (0-based, default: 0)')
    parser.add_argument('--count', type=int, default=None,
                        help='Number of packages to fetch (default: all remaining)')
    
    args = parser.parse_args()
    
    print("=" * 70)
    print("PACKAGIST VERSION FETCHER")
    print("=" * 70)
    print(f"Input file: {args.input}")
    print(f"Start index: {args.start}")
    print(f"Count: {args.count if args.count else 'all remaining'}")
    
    # 1. Load input CSV file
    print(f"\n[1/6] Loading input CSV file...")
    input_file = Path(args.input)
    if not input_file.exists():
        print(f"❌ Input file not found: {args.input}")
        sys.exit(1)
    
    packages = read_csv_input(str(input_file))
    print(f"✓ Loaded {len(packages):,} packages from {args.input}")
    
    # 2. Filter for PHP packages
    print("\n[2/6] Filtering PHP packages...")
    php_packages = [pkg for pkg in packages if pkg.get('language', '').lower() == 'php']
    
    print(f"✓ Found {len(php_packages):,} PHP packages")
    if len(php_packages) < len(packages):
        print(f"   (Filtered out {len(packages) - len(php_packages):,} non-PHP packages)")
    
    # Use php_packages for the rest of the processing
    packages = php_packages
    
    # Apply start and count filters
    end_index = args.start + args.count if args.count else len(packages)
    packages_to_fetch = packages[args.start:end_index]
    
    print(f"✓ Will fetch packages {args.start} to {min(end_index, len(packages))-1} ({len(packages_to_fetch):,} packages)")
    
    if not packages_to_fetch:
        print("❌ No packages to fetch with given filters")
        sys.exit(1)
    
    # 3. Load existing cache
    mapping_file = Path(args.output)
    cache = {}
    if mapping_file.exists():
        print(f"\n[3/6] Loading existing cache from {mapping_file}...")
        with open(mapping_file) as f:
            cache = json.load(f)
        print(f"✓ Loaded {len(cache):,} cached entries")
    else:
        print(f"\n[3/6] No existing cache found, will create new one")
    
    # 4. Fetch versions
    print("\n[4/6] Fetching Packagist versions...")
    
    fetcher = PackagistFetcher()
    audit_logger = AuditLogger(output_dir=mapping_file.parent)
    
    mapping = cache.copy()
    errors = []
    skipped = 0
    fetched = 0
    api_calls = 0
    
    for i, pkg in enumerate(packages_to_fetch):
        package_name = pkg.get('package_name', '')
        actual_index = args.start + i
        
        # Normalize package name for cache key (use / separator)
        normalized_name = package_name.replace('__', '/')
        
        print(f"\n[{actual_index}] {package_name}")
        print(f"    Script: {pkg.get('script_path', 'N/A')}")
        if package_name != normalized_name:
            print(f"    Normalized: {normalized_name}")
        
        # Validate package name before processing
        try:
            validated_name = validate_package_name(
                normalized_name,
                ecosystem='packagist',
                max_length=200
            )
        except ValidationError as e:
            print(f"    ✗ Validation error: {e}")
            errors.append({
                'package_name': package_name,
                'normalized_name': normalized_name,
                'script_path': pkg.get('script_path', ''),
                'error': f"Validation failed: {str(e)}",
                'error_type': 'validation'
            })
            continue
        
        # Skip if already in cache
        if normalized_name in mapping:
            print(f"    ✓ Already in cache (skipped)")
            skipped += 1
            continue
        
        try:
            # Fetch package data (includes all versions)
            versions = fetcher.fetch_versions(package_name)
            api_calls += 1
            
            if not versions:
                audit_logger.log_no_versions(
                    package_name=package_name,
                    ecosystem='packagist',
                    attempted_sources=['packagist_api'],
                    package_url=pkg.get('package_url', ''),
                    script_path=pkg.get('script_path', '')
                )
                print(f"    ⚠️  No versions found - logged to audit")
                errors.append({
                    'package_name': package_name,
                    'script_path': pkg.get('script_path', ''),
                    'error': 'No versions found'
                })
                continue
            
            # Get metadata
            metadata = fetcher.fetch_metadata(package_name)
            
            # Get repository info
            repository = metadata.get('repository', '')
            source_platform = categorize_source_url(repository)
            
            # Get latest version
            latest_version = metadata.get('latest_version')
            
            # Generate PURL (Package URL) format
            purl = f"pkg:composer/{normalized_name}"
            if latest_version:
                purl_with_version = f"{purl}@{latest_version}"
            else:
                purl_with_version = purl
            
            mapping[normalized_name] = {
            'package_name': normalized_name,
            'purl': purl,
            'purl_latest': purl_with_version,
            'original_input': pkg.get('script_path', ''),
            'build_script_info': {
                'base_dir': pkg.get('base_dir', ''),
                'package_version': pkg.get('package_version', ''),
                'language_versions': pkg.get('language_versions', ''),
                'script_path': pkg.get('script_path', ''),
                'package_url': pkg.get('package_url', '')
            },
                'ecosystem': 'php',
                'versions': versions,
                'version_count': len(versions),
                'latest_version': latest_version,
                'description': metadata.get('description'),
                'type': metadata.get('type'),
                'license': metadata.get('license', []),
                'homepage': metadata.get('homepage'),
                'repository': {
                    'url': repository,
                    'platform': source_platform,
                    'source': metadata.get('source', {})
                },
                'authors': metadata.get('authors', []),
                'keywords': metadata.get('keywords', []),
                'support': metadata.get('support', {}),
                'require': metadata.get('require', {}),
                'source': 'packagist',
                'fetched_at': datetime.now().isoformat()
            }
            fetched += 1
            print(f"    ✓ Fetched {len(versions)} versions")
            if repository:
                print(f"    ✓ Repository: {source_platform} - {repository}")
            
            # Save after each fetch (cache)
            with open(mapping_file, 'w') as f:
                json.dump(mapping, f, indent=2)
            
        except FetcherError as e:
            print(f"    ✗ Error: {e}")
            errors.append({
                'package_name': package_name,
                'script_path': pkg.get('script_path', ''),
                'error': str(e)
            })
        except Exception as e:
            print(f"    ✗ Unexpected error: {e}")
            errors.append({
                'package_name': package_name,
                'script_path': pkg.get('script_path', ''),
                'error': f"Unexpected: {str(e)}"
            })
    
    # Close fetcher and audit logger
    fetcher.close()
    audit_logger.close()
    
    # 5. Summary
    print(f"\n" + "=" * 70)
    print("RESULTS")
    print("=" * 70)
    print(f"✓ Fetched: {fetched:,} packages")
    print(f"✓ Skipped (cached): {skipped:,} packages")
    print(f"✓ Errors: {len(errors):,}")
    print(f"✓ API calls made: {api_calls:,}")
    
    with open(mapping_file, 'w') as f:
        json.dump(mapping, f, indent=2)
    print(f"\n✓ Saved cache to {mapping_file}")
    
    # Save errors
    if errors:
        error_file = Path(args.errors)
        with open(error_file, 'w') as f:
            json.dump(errors, f, indent=2)
        print(f"✓ Saved errors to {error_file}")
    
    # Statistics
    print("\n" + "=" * 70)
    print("CACHE STATISTICS")
    print("=" * 70)
    
    total_versions = sum(entry['version_count'] for entry in mapping.values())
    packages_with_versions = sum(1 for entry in mapping.values() if entry['version_count'] > 0)
    packages_with_repos = sum(1 for entry in mapping.values() if entry.get('repository', {}).get('url'))
    
    print(f"\nTotal packages in cache: {len(mapping):,}")
    print(f"Packages with versions:  {packages_with_versions:,}")
    print(f"Packages with repos:     {packages_with_repos:,}")
    print(f"Total versions:          {total_versions:,}")
    if mapping:
        print(f"Average per package:     {total_versions / len(mapping):.1f}")
    
    # Source platform breakdown
    platform_counts = {}
    for entry in mapping.values():
        platform = entry.get('repository', {}).get('platform')
        if platform:
            platform_counts[platform] = platform_counts.get(platform, 0) + 1
    
    if platform_counts:
        print(f"\nSource platforms:")
        for platform, count in sorted(platform_counts.items(), key=lambda x: x[1], reverse=True):
            print(f"  {platform:15s}: {count:4d} packages")
    
    # Show packages fetched in this run
    if fetched > 0:
        print(f"\nPackages fetched in this run:")
        newly_fetched = [
            (name, data) for name, data in mapping.items()
            if name in [p.get('package_name', '').replace('__', '/') for p in packages_to_fetch]
            and name not in cache
        ]
        for package_name, data in newly_fetched[:10]:  # Show first 10
            platform = data.get('repository', {}).get('platform', 'none')
            print(f"  {package_name:50s} {data['version_count']:4d} versions, platform: {platform}")
        if len(newly_fetched) > 10:
            print(f"  ... and {len(newly_fetched) - 10} more")
    
    print(f"\nOutput files:")
    print(f"  - {args.output}")
    if errors:
        print(f"  - {args.errors}")
    
    # Next steps
    print(f"\nNext steps:")
    remaining = len(packages) - end_index
    if remaining > 0:
        cmd = f"python {sys.argv[0]}"
        if args.input != 'php2.list':
            cmd += f" --input {args.input}"
        if args.output != 'packagist_versions.json':
            cmd += f" --output {args.output}"
        if args.errors != 'packagist_errors.json':
            cmd += f" --errors {args.errors}"
        cmd += f" --start {end_index}"
        if args.count:
            cmd += f" --count {args.count}"
        print(f"  To continue: {cmd}")
        print(f"  Remaining: {remaining:,} packages")
    else:
        print(f"  ✓ All packages processed!")
    
    # Show rate limit stats
    print(f"\nRate limit stats:")
    stats = fetcher.get_rate_limit_stats()
    print(f"  Available calls: {stats['available_calls']}/{stats['max_calls']}")
    print(f"  Utilization: {stats['utilization']:.1%}")


if __name__ == '__main__':
    main()