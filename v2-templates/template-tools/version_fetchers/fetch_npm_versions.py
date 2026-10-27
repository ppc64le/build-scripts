#!/usr/bin/env python3
"""
Fetch npm versions for Node.js packages from input file.

Features:
- Reads package list from file (default: node.list)
- Parses various package name formats:
  * Regular package names: express, lodash, @types/node
  * CSV build script lines: "abbrev","/build-scripts/a/abbrev/..."
- Fetches all versions from npm registry
- Extracts repository URLs and metadata
- Saves to mapping file for reuse (cache)
- No authentication required
- Incremental fetching with --start and --count

Input Format Examples:
    # Regular package names
    express
    lodash
    @types/node
    
    # CSV build script lines (package name in first quoted field)
    "abbrev","/build-scripts/a/abbrev/abbrev_rhel_8.3.sh","Node",...

Usage:
    python fetch_npm_versions.py                           # Fetch all from node.list
    python fetch_npm_versions.py --input custom.list       # Use custom input file
    python fetch_npm_versions.py --start 0 --count 10      # First 10 packages
    python fetch_npm_versions.py --start 10 --count 50     # Next 50 packages
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

from fetchers.npm_fetcher import NpmFetcher, FetcherError
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
        description='Fetch npm versions for Node.js packages',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s                              # Fetch all from node.list
  %(prog)s --input custom.list          # Use custom input file
  %(prog)s --start 0 --count 10         # First 10 packages
  %(prog)s --start 10 --count 50        # Next 50 packages
        """
    )
    parser.add_argument('--input', type=str, default='node2.list',
                        help='Input CSV file with package info (default: node2.list)')
    parser.add_argument('--output', type=str, default='npm_versions.json',
                        help='Output JSON file (default: npm_versions.json)')
    parser.add_argument('--errors', type=str, default='npm_errors.json',
                        help='Error log JSON file (default: npm_errors.json)')
    parser.add_argument('--start', type=int, default=0,
                        help='Start index (0-based, default: 0)')
    parser.add_argument('--count', type=int, default=None,
                        help='Number of packages to fetch (default: all remaining)')
    
    args = parser.parse_args()
    
    print("=" * 70)
    print("NPM VERSION FETCHER")
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
    
    # 2. Filter for Node packages
    print("\n[2/6] Filtering Node packages...")
    node_packages = [pkg for pkg in packages if pkg.get('language', '').lower() in ('node', 'nodejs', 'javascript')]
    
    print(f"✓ Found {len(node_packages):,} Node packages")
    if len(node_packages) < len(packages):
        print(f"   (Filtered out {len(packages) - len(node_packages):,} non-Node packages)")
    
    # Use node_packages for the rest of the processing
    packages = node_packages
    
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
    print("\n[4/6] Fetching npm versions...")
    
    fetcher = NpmFetcher()
    audit_logger = AuditLogger(output_dir=mapping_file.parent)
    
    mapping = cache.copy()
    errors = []
    skipped = 0
    fetched = 0
    api_calls = 0
    
    for i, pkg in enumerate(packages_to_fetch):
        package_name = pkg.get('package_name', '')
        actual_index = args.start + i
        
        print(f"\n[{actual_index}] {package_name}")
        print(f"    Script: {pkg.get('script_path', 'N/A')}")
        
        # Skip if already in cache
        if package_name in mapping:
            print(f"    ✓ Already in cache (skipped)")
            skipped += 1
            continue
        
        try:
            # Validate package name for security
            try:
                package_name = validate_package_name(package_name, ecosystem='npm')
            except ValidationError as e:
                print(f"    ✗ Invalid package name: {e}")
                errors.append({
                    'package_name': package_name,
                    'error': f'Validation error: {e}',
                    'timestamp': datetime.now().isoformat()
                })
                continue
            
            # Fetch package data (includes all versions)
            package_data = fetcher.fetch_package_data(package_name)
            api_calls += 1
            
            # Extract versions
            versions_data = package_data.get('versions', {})
            time_data = package_data.get('time', {})
            
            versions = []
            for version, version_info in versions_data.items():
                versions.append({
                    'version': version,
                    'publish_date': time_data.get(version),
                    'deprecated': 'deprecated' in version_info,
                    'deprecation_message': version_info.get('deprecated') if 'deprecated' in version_info else None
                })
            
            # Sort by publish date (newest first)
            versions.sort(key=lambda x: x['publish_date'] or '', reverse=True)
            
            # Log if no versions found
            if not versions or len(versions) == 0:
                audit_logger.log_no_versions(
                    package_name=package_name,
                    ecosystem='npm',
                    attempted_sources=['npm_registry'],
                    package_url=pkg.get('package_url', ''),
                    script_path=pkg.get('script_path', '')
                )
                print(f"    ⚠️  No versions found - logged to audit")
            
            # Get repository info
            repository = package_data.get('repository', {})
            if isinstance(repository, str):
                repo_url = repository
                repo_type = 'unknown'
            else:
                repo_url = repository.get('url', '')
                repo_type = repository.get('type', 'unknown')
            
            # Clean up git URLs
            if repo_url:
                repo_url = repo_url.replace('git+', '').replace('git://', 'https://')
                repo_url = re.sub(r'\.git$', '', repo_url)
            
            # Categorize source platform
            source_platform = categorize_source_url(repo_url)
            
            # Get latest version
            dist_tags = package_data.get('dist-tags', {})
            latest_version = dist_tags.get('latest')
            
            # Generate PURL (Package URL) format
            purl = f"pkg:npm/{package_name}"
            if latest_version:
                purl_with_version = f"{purl}@{latest_version}"
            else:
                purl_with_version = purl
            
            mapping[package_name] = {
                'package_name': package_name,
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
                'ecosystem': 'node',
                'versions': versions,
                'version_count': len(versions),
                'latest_version': latest_version,
                'dist_tags': dist_tags,
                'repository': {
                    'type': repo_type,
                    'url': repo_url,
                    'platform': source_platform
                },
                'homepage': package_data.get('homepage'),
                'description': package_data.get('description'),
                'license': package_data.get('license'),
                'author': package_data.get('author'),
                'keywords': package_data.get('keywords', []),
                'created': time_data.get('created'),
                'modified': time_data.get('modified'),
                'source': 'npm',
                'fetched_at': datetime.now().isoformat()
            }
            fetched += 1
            print(f"    ✓ Fetched {len(versions)} versions")
            if repo_url:
                print(f"    ✓ Repository: {source_platform} - {repo_url}")
            
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
            if name in [p.get('package_name', '') for p in packages_to_fetch]
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
        if args.input != 'node2.list':
            cmd += f" --input {args.input}"
        if args.output != 'npm_versions.json':
            cmd += f" --output {args.output}"
        if args.errors != 'npm_errors.json':
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