#!/usr/bin/env python3
"""
Fetch PyPI versions for Python packages from input file.

Features:
- Reads package list from CSV file (default: python2.list)
- Fetches all versions from PyPI with upload dates
- Saves to mapping file for reuse (cache)
- No authentication required
- Incremental fetching with --start and --count

Usage:
    python fetch_pypi_versions.py                           # Fetch all from python2.list
    python fetch_pypi_versions.py --input custom.list       # Use custom input file
    python fetch_pypi_versions.py --start 0 --count 10      # First 10 packages
    python fetch_pypi_versions.py --start 10 --count 50     # Next 50 packages
"""

import json
import sys
import argparse
import csv
from pathlib import Path
from datetime import datetime
from typing import Dict, List

# Add scripts to path
sys.path.insert(0, str(Path(__file__).parent / 'scripts'))

from fetchers.pypi_fetcher import PyPIFetcher, FetcherError
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


def main():
    # Parse command-line arguments
    parser = argparse.ArgumentParser(
        description='Fetch PyPI versions for Python packages',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s                          # Fetch all Python packages
  %(prog)s --start 0 --count 10     # First 10 Python packages
  %(prog)s --start 10 --count 50    # Next 50 Python packages
        """
    )
    parser.add_argument('--input', type=str, default='python2.list',
                        help='Input CSV file with package info (default: python2.list)')
    parser.add_argument('--output', type=str, default='pypi_versions.json',
                        help='Output JSON file (default: pypi_versions.json)')
    parser.add_argument('--errors', type=str, default='pypi_errors.json',
                        help='Error log JSON file (default: pypi_errors.json)')
    parser.add_argument('--start', type=int, default=0,
                        help='Start index (0-based, default: 0)')
    parser.add_argument('--count', type=int, default=None,
                        help='Number of packages to fetch (default: all remaining)')
    
    args = parser.parse_args()
    
    print("=" * 70)
    print("PYPI VERSION FETCHER")
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
    
    # 2. Filter for Python packages
    print("\n[2/6] Filtering Python packages...")
    python_packages = [pkg for pkg in packages if pkg.get('language', '').lower() == 'python']
    
    print(f"✓ Found {len(python_packages):,} Python packages")
    if len(python_packages) < len(packages):
        print(f"   (Filtered out {len(packages) - len(python_packages):,} non-Python packages)")
    
    # Apply start and count filters
    end_index = args.start + args.count if args.count else len(python_packages)
    packages_to_fetch = python_packages[args.start:end_index]
    
    print(f"✓ Will fetch packages {args.start} to {min(end_index, len(python_packages))-1} ({len(packages_to_fetch):,} packages)")
    
    if not packages_to_fetch:
        print("❌ No packages to fetch with given filters")
        sys.exit(1)
    
    # 3. Load existing cache
    mapping_file = Path(args.output)
    cache = {}
    if mapping_file.exists():
        print(f"\n[4/6] Loading existing cache from {mapping_file}...")
        with open(mapping_file) as f:
            cache = json.load(f)
        print(f"✓ Loaded {len(cache):,} cached entries")
    else:
        print(f"\n[3/6] No existing cache found, will create new one")
    
    # 4. Fetch versions
    print("\n[4/6] Fetching PyPI versions...")
    
    fetcher = PyPIFetcher()
    audit_logger = AuditLogger(output_dir=mapping_file.parent)
    
    mapping = cache.copy()
    errors = []
    skipped = 0
    fetched = 0
    api_calls = 0
    
    for i, pkg in enumerate(packages_to_fetch):
        pkg_name = pkg.get('package_name', '')
        actual_index = args.start + i
        
        print(f"\n[{actual_index}] {pkg_name}")
        print(f"    Script: {pkg.get('script_path', 'N/A')}")
        
        # Skip if already in cache
        if pkg_name in mapping:
            print(f"    ✓ Already in cache (skipped)")
            skipped += 1
            continue
        
        try:
            # Validate package name for security
            try:
                pkg_name = validate_package_name(pkg_name, ecosystem='pypi')
            except ValidationError as e:
                print(f"    ✗ Invalid package name: {e}")
                errors.append({
                    'package_name': pkg_name,
                    'error': f'Validation error: {e}',
                    'timestamp': datetime.now().isoformat()
                })
                continue
            
            # Fetch versions from PyPI
            versions = fetcher.fetch_versions(pkg_name)
            api_calls += 1  # One API call per package
            
            # Log if no versions found
            if not versions or len(versions) == 0:
                audit_logger.log_no_versions(
                    package_name=pkg_name,
                    ecosystem='pypi',
                    attempted_sources=['pypi_api'],
                    package_url=pkg.get('package_url', ''),
                    script_path=pkg.get('script_path', '')
                )
                print(f"    ⚠️  No versions found - logged to audit")
            
            mapping[pkg_name] = {
                'package_name': pkg_name,
                'purl': f"pkg:pypi/{pkg_name}",
                'ecosystem': 'python',
                'versions': versions,
                'version_count': len(versions),
                'build_script_info': {
                    'base_dir': pkg.get('base_dir', ''),
                    'package_version': pkg.get('package_version', ''),
                    'language_versions': pkg.get('language_versions', ''),
                    'script_path': pkg.get('script_path', ''),
                    'package_url': pkg.get('package_url', '')
                },
                'source': 'pypi',
                'fetched_at': datetime.now().isoformat()
            }
            fetched += 1
            if len(versions) > 0:
                print(f"    ✓ Fetched {len(versions)} versions")
            
            # Save after each fetch (cache)
            with open(mapping_file, 'w') as f:
                json.dump(mapping, f, indent=2)
            
        except FetcherError as e:
            print(f"    ✗ Error: {e}")
            errors.append({
                'package_name': pkg_name,
                'script_path': pkg.get('script_path', ''),
                'error': str(e)
            })
        except Exception as e:
            print(f"    ✗ Unexpected error: {e}")
            errors.append({
                'package_name': pkg_name,
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
    
    print(f"\nTotal packages in cache: {len(mapping):,}")
    print(f"Packages with versions:  {packages_with_versions:,}")
    print(f"Total versions:          {total_versions:,}")
    if mapping:
        print(f"Average per package:     {total_versions / len(mapping):.1f}")
    
    # Show packages fetched in this run
    if fetched > 0:
        print(f"\nPackages fetched in this run:")
        newly_fetched = [
            (name, data) for name, data in mapping.items()
            if name in [p.get('package_name', '') for p in packages_to_fetch]
            and name not in cache
        ]
        for pkg_name, data in newly_fetched[:10]:  # Show first 10
            print(f"  {pkg_name:30s} {data['version_count']:4d} versions")
        if len(newly_fetched) > 10:
            print(f"  ... and {len(newly_fetched) - 10} more")
    
    print(f"\nOutput files:")
    print(f"  - {args.output}")
    if errors:
        print(f"  - {args.errors}")
    
    # Next steps
    print(f"\nNext steps:")
    remaining = len(python_packages) - end_index
    if remaining > 0:
        cmd = f"python {sys.argv[0]}"
        if args.input != 'python2.list':
            cmd += f" --input {args.input}"
        if args.output != 'pypi_versions.json':
            cmd += f" --output {args.output}"
        if args.errors != 'pypi_errors.json':
            cmd += f" --errors {args.errors}"
        cmd += f" --start {end_index}"
        if args.count:
            cmd += f" --count {args.count}"
        print(f"  To continue: {cmd}")
        print(f"  Remaining: {remaining:,} Python packages")
    else:
        print(f"  ✓ All Python packages processed!")
    
    # Show rate limit stats
    print(f"\nRate limit stats:")
    stats = fetcher.get_rate_limit_stats()
    print(f"  Available calls: {stats['available_calls']}/{stats['max_calls']}")
    print(f"  Utilization: {stats['utilization']:.1%}")


if __name__ == '__main__':
    main()
