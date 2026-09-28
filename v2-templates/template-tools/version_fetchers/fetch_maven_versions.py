#!/usr/bin/env python3
"""
Fetch Maven versions for Java packages from input file.

Features:
- Reads package list from file (default: java.list)
- Parses various Maven coordinate formats:
  * Maven coordinates: com.auth0/java-jwt, com.auth0:java-jwt
  * CSV build script lines: build-script-index.csv:"/build-scripts/a/accessors-smart/..."
- Auto-discovers groupId for packages with unknown groupId via Maven Central search
- Fetches all versions from Maven Central
- Extracts source repository URLs from POM files
- Saves to mapping file for reuse (cache)
- No authentication required
- Incremental fetching with --start and --count

Input Format Examples:
    # Maven coordinates (groupId/artifactId or groupId:artifactId)
    com.auth0/java-jwt
    org.springframework.boot/spring-boot-starter
    
    # CSV build script lines (package name extracted from path)
    build-script-index.csv:"/build-scripts/a/accessors-smart/accessors-smart_ubi_8.3.sh","Java",...

Usage:
    python fetch_maven_versions.py                           # Fetch all from java.list
    python fetch_maven_versions.py --input custom.list       # Use custom input file
    python fetch_maven_versions.py --start 0 --count 10      # First 10 packages
    python fetch_maven_versions.py --start 10 --count 50     # Next 50 packages
"""

import json
import sys
import argparse
import csv
import re
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Tuple, Optional

# Add scripts to path
sys.path.insert(0, str(Path(__file__).parent / 'scripts'))

from fetchers.maven_fetcher import MavenFetcher, FetcherError
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


def extract_source_urls(pom_content: str) -> Dict[str, str]:
    """
    Extract source repository URLs from POM content.
    
    Args:
        pom_content: POM XML content
    
    Returns:
        Dictionary of source URLs by type
    """
    import xml.etree.ElementTree as ET
    
    sources = {}
    
    try:
        root = ET.fromstring(pom_content)
        ns = {'maven': 'http://maven.apache.org/POM/4.0.0'}
        
        # Check <scm> section
        scm = root.find('maven:scm', ns) or root.find('scm')
        if scm is not None:
            url = scm.findtext('maven:url', namespaces=ns) or scm.findtext('url')
            connection = scm.findtext('maven:connection', namespaces=ns) or scm.findtext('connection')
            dev_connection = scm.findtext('maven:developerConnection', namespaces=ns) or scm.findtext('developerConnection')
            
            if url:
                sources['scm_url'] = url
            if connection:
                sources['scm_connection'] = connection
            if dev_connection:
                sources['scm_dev_connection'] = dev_connection
        
        # Check <url> (project homepage)
        project_url = root.findtext('maven:url', namespaces=ns) or root.findtext('url')
        if project_url:
            sources['project_url'] = project_url
        
        # Check <issueManagement>
        issue_mgmt = root.find('maven:issueManagement', ns) or root.find('issueManagement')
        if issue_mgmt is not None:
            issue_url = issue_mgmt.findtext('maven:url', namespaces=ns) or issue_mgmt.findtext('url')
            if issue_url:
                sources['issue_url'] = issue_url
        
    except ET.ParseError:
        pass
    
    return sources


def categorize_source_url(url: str) -> str:
    """
    Categorize source URL by hosting platform.
    
    Args:
        url: Source URL
    
    Returns:
        Platform name (github, gitlab, bitbucket, etc.)
    """
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
        description='Fetch Maven versions for Java packages',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s                              # Fetch all from java.list
  %(prog)s --input custom.list          # Use custom input file
  %(prog)s --start 0 --count 10         # First 10 packages
  %(prog)s --start 10 --count 50        # Next 50 packages
        """
    )
    parser.add_argument('--input', type=str, default='java2.list',
                        help='Input CSV file with package info (default: java2.list)')
    parser.add_argument('--output', type=str, default='maven_versions.json',
                        help='Output JSON file (default: maven_versions.json)')
    parser.add_argument('--errors', type=str, default='maven_errors.json',
                        help='Error log JSON file (default: maven_errors.json)')
    parser.add_argument('--start', type=int, default=0,
                        help='Start index (0-based, default: 0)')
    parser.add_argument('--count', type=int, default=None,
                        help='Number of packages to fetch (default: all remaining)')
    
    args = parser.parse_args()
    
    print("=" * 70)
    print("MAVEN VERSION FETCHER")
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
    
    # 2. Filter for Java packages
    print("\n[2/6] Filtering Java packages...")
    java_packages = [pkg for pkg in packages if pkg.get('language', '').lower() == 'java']
    
    print(f"✓ Found {len(java_packages):,} Java packages")
    if len(java_packages) < len(packages):
        print(f"   (Filtered out {len(packages) - len(java_packages):,} non-Java packages)")
    
    # Convert to Maven coordinate format
    maven_packages = []
    for pkg in java_packages:
        package_name = pkg.get('package_name', '')
        # For Maven, we need groupId:artifactId
        # If package_name contains /, split it; otherwise use 'unknown' as groupId
        if '/' in package_name or ':' in package_name:
            parts = package_name.replace(':', '/').split('/')
            if len(parts) >= 2:
                group_id = parts[0]
                artifact_id = parts[-1]
            else:
                group_id = 'unknown'
                artifact_id = package_name
        else:
            group_id = 'unknown'
            artifact_id = package_name
        
        maven_packages.append({
            'original_pkg': pkg,
            'group_id': group_id,
            'artifact_id': artifact_id,
            'coordinate': f"{group_id}:{artifact_id}"
        })
    
    print(f"✓ Converted to {len(maven_packages):,} Maven coordinates")
    
    # Apply start and count filters
    end_index = args.start + args.count if args.count else len(maven_packages)
    packages_to_fetch = maven_packages[args.start:end_index]
    
    print(f"✓ Will fetch packages {args.start} to {min(end_index, len(maven_packages))-1} ({len(packages_to_fetch):,} packages)")
    
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
    print("\n[4/6] Fetching Maven versions...")
    
    fetcher = MavenFetcher()
    audit_logger = AuditLogger(output_dir=mapping_file.parent)
    
    mapping = cache.copy()
    errors = []
    skipped = 0
    fetched = 0
    api_calls = 0
    
    for i, pkg in enumerate(packages_to_fetch):
        group_id = pkg['group_id']
        artifact_id = pkg['artifact_id']
        coordinate = pkg['coordinate']
        actual_index = args.start + i
        
        print(f"\n[{actual_index}] {coordinate}")
        print(f"    Package: {pkg['original_pkg'].get('package_name', 'unknown')}")
        
        # Validate coordinate before processing
        try:
            validated_coordinate = validate_package_name(
                coordinate,
                ecosystem='maven',
                max_length=200
            )
        except ValidationError as e:
            print(f"    ✗ Validation error: {e}")
            errors.append({
                'coordinate': coordinate,
                'group_id': group_id,
                'artifact_id': artifact_id,
                'original': pkg['original_pkg'],
                'error': f"Validation failed: {str(e)}",
                'error_type': 'validation'
            })
            continue
        
        # Skip if already in cache
        if coordinate in mapping:
            print(f"    ✓ Already in cache (skipped)")
            skipped += 1
            continue
        
        # If groupId is unknown, try to search for it
        if group_id == 'unknown':
            print(f"    ⚠️  GroupId unknown, searching Maven Central for '{artifact_id}'...")
            try:
                # Search by artifact name
                search_results = fetcher.search_artifacts(f'a:{artifact_id}', rows=5)
                api_calls += 1
                
                if search_results:
                    # Use the first result (most relevant)
                    found_group = search_results[0].get('groupId')
                    found_artifact = search_results[0].get('artifactId')
                    
                    if found_group and found_artifact:
                        print(f"    ✓ Found: {found_group}:{found_artifact}")
                        
                        # Show other matches if any
                        if len(search_results) > 1:
                            print(f"    ℹ️  Other matches found:")
                            for i, result in enumerate(search_results[1:4], 1):
                                alt_group = result.get('groupId')
                                alt_artifact = result.get('artifactId')
                                print(f"       {i}. {alt_group}:{alt_artifact}")
                        
                        group_id = found_group
                        artifact_id = found_artifact
                        coordinate = f"{group_id}:{artifact_id}"
                        
                        # Update package info
                        pkg['group_id'] = group_id
                        pkg['artifact_id'] = artifact_id
                        pkg['coordinate'] = coordinate
                    else:
                        print(f"    ✗ Search returned invalid results")
                        errors.append({
                            'coordinate': coordinate,
                            'original': pkg['original_pkg'],
                            'error': 'Search returned invalid results'
                        })
                        continue
                else:
                    print(f"    ✗ No results found in Maven Central")
                    errors.append({
                        'coordinate': coordinate,
                        'original': pkg['original_pkg'],
                        'error': 'Package not found in Maven Central'
                    })
                    continue
            except FetcherError as e:
                print(f"    ✗ Search error: {e}")
                errors.append({
                    'coordinate': coordinate,
                    'original': pkg['original_pkg'],
                    'error': f'Search error: {str(e)}'
                })
                continue
            except Exception as e:
                print(f"    ✗ Unexpected search error: {e}")
                errors.append({
                    'coordinate': coordinate,
                    'original': pkg['original_pkg'],
                    'error': f'Unexpected search error: {str(e)}'
                })
                continue
        
        try:
            # Fetch metadata (includes all versions)
            metadata = fetcher.fetch_maven_metadata(group_id, artifact_id)
            api_calls += 1
            
            versions = metadata.get('versions', [])
            
            # Log if no versions found
            if not versions or len(versions) == 0:
                audit_logger.log_no_versions(
                    package_name=f"{group_id}:{artifact_id}",
                    ecosystem='maven',
                    attempted_sources=['maven_central'],
                    package_url=pkg.get('package_url', ''),
                    script_path=pkg.get('script_path', ''),
                    group_id=group_id,
                    artifact_id=artifact_id
                )
                print(f"    ⚠️  No versions found - logged to audit")
            
            # Try to fetch POM for latest version to get source URLs
            source_urls = {}
            latest_version = metadata.get('latest') or metadata.get('release')
            if latest_version:
                try:
                    pom_content = fetcher.fetch_pom(group_id, artifact_id, latest_version)
                    api_calls += 1
                    source_urls = extract_source_urls(pom_content)
                except FetcherError:
                    pass  # POM not available
            
            # Categorize source URLs
            source_platforms = {}
            for key, url in source_urls.items():
                platform = categorize_source_url(url)
                if platform not in source_platforms:
                    source_platforms[platform] = []
                source_platforms[platform].append({'type': key, 'url': url})
            
            # Generate PURL (Package URL) format
            purl = f"pkg:maven/{group_id}/{artifact_id}"
            if latest_version:
                purl_with_version = f"{purl}@{latest_version}"
            else:
                purl_with_version = purl
            
            mapping[coordinate] = {
                'group_id': group_id,
                'artifact_id': artifact_id,
                'coordinate': coordinate,
                'package_name': artifact_id,  # The actual installed package name
                'purl': purl,  # Package URL without version
                'purl_latest': purl_with_version,  # Package URL with latest version
                'original_input': pkg['original_pkg'],
                'ecosystem': 'java',
                'versions': versions,
                'version_count': len(versions),
                'latest_version': latest_version,
                'source_urls': source_urls,
                'source_platforms': source_platforms,
                'source': 'maven',
                'fetched_at': datetime.now().isoformat()
            }
            fetched += 1
            print(f"    ✓ Fetched {len(versions)} versions")
            if source_platforms:
                for platform, urls in source_platforms.items():
                    print(f"    ✓ Found {len(urls)} {platform} URL(s)")
            
            # Save after each fetch (cache)
            with open(mapping_file, 'w') as f:
                json.dump(mapping, f, indent=2)
            
        except FetcherError as e:
            print(f"    ✗ Error: {e}")
            errors.append({
                'coordinate': coordinate,
                'group_id': group_id,
                'artifact_id': artifact_id,
                'original': pkg['original_pkg'],
                'error': str(e)
            })
        except Exception as e:
            print(f"    ✗ Unexpected error: {e}")
            errors.append({
                'coordinate': coordinate,
                'group_id': group_id,
                'artifact_id': artifact_id,
                'original': pkg['original_pkg'],
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
    packages_with_sources = sum(1 for entry in mapping.values() if entry.get('source_urls'))
    
    print(f"\nTotal packages in cache: {len(mapping):,}")
    print(f"Packages with versions:  {packages_with_versions:,}")
    print(f"Packages with sources:   {packages_with_sources:,}")
    print(f"Total versions:          {total_versions:,}")
    if mapping:
        print(f"Average per package:     {total_versions / len(mapping):.1f}")
    
    # Source platform breakdown
    platform_counts = {}
    for entry in mapping.values():
        for platform in entry.get('source_platforms', {}).keys():
            platform_counts[platform] = platform_counts.get(platform, 0) + 1
    
    if platform_counts:
        print(f"\nSource platforms:")
        for platform, count in sorted(platform_counts.items(), key=lambda x: x[1], reverse=True):
            print(f"  {platform:15s}: {count:4d} packages")
    
    # Show packages fetched in this run
    if fetched > 0:
        print(f"\nPackages fetched in this run:")
        newly_fetched = [
            (coord, data) for coord, data in mapping.items()
            if coord in [p['coordinate'] for p in packages_to_fetch]
            and coord not in cache
        ]
        for coordinate, data in newly_fetched[:10]:  # Show first 10
            sources = ', '.join(data.get('source_platforms', {}).keys()) or 'none'
            print(f"  {coordinate:50s} {data['version_count']:4d} versions, sources: {sources}")
        if len(newly_fetched) > 10:
            print(f"  ... and {len(newly_fetched) - 10} more")
    
    print(f"\nOutput files:")
    print(f"  - {args.output}")
    if errors:
        print(f"  - {args.errors}")
    
    # Next steps
    print(f"\nNext steps:")
    remaining = len(maven_packages) - end_index
    if remaining > 0:
        cmd = f"python {sys.argv[0]}"
        if args.input != 'java2.list':
            cmd += f" --input {args.input}"
        if args.output != 'maven_versions.json':
            cmd += f" --output {args.output}"
        if args.errors != 'maven_errors.json':
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