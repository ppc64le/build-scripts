#!/usr/bin/env python3
"""
Fetch GitHub releases/tags for packages from JSON or CSV input.

Features:
- Reads from database_migrated_enhanced_*.json (default) or build_scripts.csv
- Fetches last 5 years of GitHub releases (with fallback to tags)
- Saves to mapping file for reuse (cache)
- Rate limiting and error handling
- Ecosystem filtering (--ecosystem python, node, etc.)
- Incremental fetching with --start and --count

Usage:
    python fetch_github_tags.py                                    # Fetch all (from JSON)
    python fetch_github_tags.py --input csv                        # Fetch all (from CSV)
    python fetch_github_tags.py --ecosystem python                 # Only Python packages
    python fetch_github_tags.py --ecosystem node --start 0 --count 10   # First 10 Node packages
    python fetch_github_tags.py --start 10 --count 50              # Packages 10-59 (all ecosystems)
"""

import csv
import json
import sys
import argparse
from pathlib import Path
from datetime import datetime, timedelta
from typing import Dict, List, Optional
import requests

# Add scripts to path
sys.path.insert(0, str(Path(__file__).parent / 'scripts'))

from utils.rate_limiter import RateLimiter
from utils.retry import retry_with_backoff


class GitHubFetcher:
    """Fetch GitHub releases/tags with rate limiting and caching."""
    
    def __init__(self, github_token: Optional[str] = None):
        """
        Initialize fetcher.
        
        Args:
            github_token: GitHub personal access token (optional but recommended)
        """
        self.github_token = github_token
        # Conservative rate: 60 requests per minute
        self.rate_limiter = RateLimiter(max_calls=60, period=60)
        self.session = requests.Session()
        self.api_calls = 0  # Track API calls
        
        if github_token:
            # Handle both classic (ghp_) and fine-grained (github_pat_) tokens
            if github_token.startswith('github_pat_') or github_token.startswith('github_'):
                # Fine-grained token - use Bearer
                auth_header = f'Bearer {github_token}'
                token_type = "fine-grained"
            else:
                # Classic token - use token
                auth_header = f'token {github_token}'
                token_type = "classic"
            
            self.session.headers.update({
                'Authorization': auth_header,
                'Accept': 'application/vnd.github.v3+json'
            })
            print(f"✓ Using GitHub token ({token_type}, higher rate limits)")
            
            # Test the token
            print("  Testing token...")
            self.api_calls += 1  # Count test API call
            test_response = self.session.get('https://api.github.com/user')
            if test_response.status_code == 200:
                user_data = test_response.json()
                print(f"  ✓ Token valid - authenticated as: {user_data.get('login', 'unknown')}")
            else:
                print(f"  ✗ Token test failed: {test_response.status_code} - {test_response.text[:100]}")
        else:
            print("⚠️  No GitHub token - rate limits will be lower (60/hour)")
            print("   Set GITHUB_TOKEN environment variable for 5,000/hour")
    
    def extract_repo_info(self, github_url: str) -> Optional[tuple]:
        """
        Extract owner and repo from GitHub URL.
        
        Args:
            github_url: GitHub URL
        
        Returns:
            Tuple of (owner, repo) or None if invalid
        """
        if not github_url or 'github.com' not in github_url.lower():
            return None
        
        # Handle various GitHub URL formats
        parts = github_url.rstrip('/').split('github.com/')
        if len(parts) < 2:
            return None
        
        path_parts = parts[1].split('/')
        if len(path_parts) < 2:
            return None
        
        owner = path_parts[0]
        repo = path_parts[1].replace('.git', '')
        
        return (owner, repo)
    
    @retry_with_backoff(max_retries=1)
    def fetch_releases(self, owner: str, repo: str, since_date: datetime) -> tuple[List[Dict], str]:
        """
        Fetch releases from GitHub API.
        
        Args:
            owner: Repository owner
            repo: Repository name
            since_date: Only fetch releases after this date
        
        Returns:
            Tuple of (list of release dicts, source: 'releases' or 'tags')
        """
        self.rate_limiter.acquire()
        
        # Try releases first
        url = f'https://api.github.com/repos/{owner}/{repo}/releases'
        
        try:
            response = self.session.get(url, params={'per_page': 100})
            response.raise_for_status()
            
            releases = response.json()
            
            # Filter by date and extract relevant info
            filtered = []
            for release in releases:
                published_at = release.get('published_at')
                if published_at:
                    # Parse as timezone-aware datetime
                    release_date = datetime.fromisoformat(published_at.replace('Z', '+00:00'))
                    # Make since_date timezone-aware for comparison
                    if since_date.tzinfo is None:
                        from datetime import timezone
                        since_date_aware = since_date.replace(tzinfo=timezone.utc)
                    else:
                        since_date_aware = since_date
                    if release_date >= since_date_aware:
                        filtered.append({
                            'name': release.get('tag_name', release.get('name', 'unknown')),
                            'date': published_at,
                            'prerelease': release.get('prerelease', False),
                            'draft': release.get('draft', False)
                        })
            
            if filtered:
                return filtered, 'releases'
            
            # No releases found, fallback to tags
            print(f"    No releases found, trying tags...")
            return self.fetch_tags_simple(owner, repo, since_date)
            
        except requests.exceptions.HTTPError as e:
            if e.response.status_code == 404:
                # Repo not found or no releases, try tags
                return self.fetch_tags_simple(owner, repo, since_date)
            else:
                raise
    
    @retry_with_backoff(max_retries=1)
    def fetch_tags_simple(self, owner: str, repo: str, since_date: datetime) -> tuple[List[Dict], str]:
        """
        Fetch tags from GitHub API (simplified - no commit date filtering).
        
        Args:
            owner: Repository owner
            repo: Repository name
            since_date: Only fetch tags after this date (best effort)
        
        Returns:
            Tuple of (list of tag dicts, source: 'tags')
        """
        self.rate_limiter.acquire()
        self.api_calls += 1  # Count API call
        
        url = f'https://api.github.com/repos/{owner}/{repo}/tags'
        
        try:
            response = self.session.get(url, params={'per_page': 100})
            response.raise_for_status()
            
            tags = response.json()
            
            # Return tags without date filtering (we don't have dates without extra API calls)
            # Just return the most recent 100 tags
            result = []
            for tag in tags:
                result.append({
                    'name': tag['name'],
                    'date': None,  # Would need extra API call per tag
                    'sha': tag['commit']['sha']
                })
            
            return result, 'tags'
            
        except requests.exceptions.HTTPError as e:
            if e.response.status_code == 404:
                print(f"    Repository not found: {owner}/{repo}")
                return [], 'error'
            elif e.response.status_code == 403:
                print(f"    Rate limit or access forbidden: {owner}/{repo}")
                raise
            else:
                print(f"    HTTP error: {e}")
                raise


def main():
    # Parse command-line arguments
    parser = argparse.ArgumentParser(
        description='Fetch GitHub releases/tags for packages',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s                                      # Fetch all packages (from JSON)
  %(prog)s --input csv                          # Fetch all packages (from CSV)
  %(prog)s --ecosystem python                   # Only Python packages
  %(prog)s --ecosystem node --start 0 --count 10    # First 10 Node packages
  %(prog)s --start 100 --count 50               # Packages 100-149 (all ecosystems)
        """
    )
    parser.add_argument('--input', type=str, choices=['json', 'csv'], default='json',
                        help='Input format: json (database_migrated_enhanced_*.json) or csv (build_scripts.csv)')
    parser.add_argument('--ecosystem', type=str, default=None,
                        help='Filter by ecosystem (python, node, go, java, ruby, rust, php, c, cpp)')
    parser.add_argument('--start', type=int, default=0,
                        help='Start index within filtered results (0-based, default: 0)')
    parser.add_argument('--count', type=int, default=None,
                        help='Number of packages to fetch (default: all remaining)')
    
    args = parser.parse_args()
    
    print("=" * 70)
    print("GITHUB RELEASES/TAGS FETCHER")
    print("=" * 70)
    print(f"Input format: {args.input}")
    if args.ecosystem:
        print(f"Ecosystem filter: {args.ecosystem}")
    print(f"Start index: {args.start}")
    print(f"Count: {args.count if args.count else 'all remaining'}")

    if args.input == 'json':
        # 1. Find latest migrated database file
        print("\n[1/6] Finding latest migrated database...")
        db_files = sorted(Path('.').glob('database_migrated_enhanced_*.json'))
        if not db_files:
            print("❌ No database_migrated_enhanced_*.json files found")
            sys.exit(1)

        latest_db = db_files[-1]
        print(f"✓ Using: {latest_db}")

        # 2. Load database
        print("\n[2/6] Loading database...")
        with open(latest_db) as f:
            packages = json.load(f)
        print(f"✓ Loaded {len(packages):,} packages")

        # 3. Extract packages with GitHub URLs
        print("\n[3/6] Extracting packages with GitHub URLs...")
        packages_with_github = []
        for pkg in packages:
            github_url = pkg.get('github_url')
            ecosystem = pkg.get('package_type')

            # Apply ecosystem filter
            if args.ecosystem and ecosystem != args.ecosystem:
                continue

            if github_url and github_url not in ['N/A', 'Unknown', '']:
                packages_with_github.append({
                    'package_name': pkg.get('package_name'),
                    'ecosystem': ecosystem,
                    'github_url': github_url
                })

        if args.ecosystem:
            print(f"✓ Found {len(packages_with_github):,} {args.ecosystem} packages with GitHub URLs")
        else:
            print(f"✓ Found {len(packages_with_github):,} packages with GitHub URLs")

    else:  # csv
        # 1. Find build_scripts.csv
        print("\n[1/6] Finding build_scripts.csv...")
        csv_file = Path('build_scripts.csv')
        if not csv_file.exists():
            print("❌ build_scripts.csv not found")
            sys.exit(1)
        print(f"✓ Using: {csv_file}")

        # 2. Load CSV and deduplicate by package_name
        print("\n[2/6] Loading build_scripts.csv...")
        seen_packages = {}  # package_name -> {ecosystem, github_url}
        row_count = 0
        with open(csv_file, newline='', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            for row in reader:
                row_count += 1
                pkg_name = row.get('package_name', '').strip()
                github_url = row.get('package_url', '').strip()
                ecosystem = row.get('language', '').strip()

                if pkg_name and pkg_name not in seen_packages:
                    seen_packages[pkg_name] = {
                        'ecosystem': ecosystem,
                        'github_url': github_url
                    }
        print(f"✓ Loaded {row_count:,} rows, {len(seen_packages):,} unique packages")

        # 3. Extract packages with GitHub URLs
        print("\n[3/6] Extracting packages with GitHub URLs...")
        packages_with_github = []
        for pkg_name, pkg_data in seen_packages.items():
            github_url = pkg_data['github_url']
            ecosystem = pkg_data['ecosystem']

            # Apply ecosystem filter (case-insensitive)
            if args.ecosystem and ecosystem.lower() != args.ecosystem.lower():
                continue

            if github_url and 'github.com' in github_url.lower():
                packages_with_github.append({
                    'package_name': pkg_name,
                    'ecosystem': ecosystem,
                    'github_url': github_url
                })

        if args.ecosystem:
            print(f"✓ Found {len(packages_with_github):,} {args.ecosystem} packages with GitHub URLs")
        else:
            print(f"✓ Found {len(packages_with_github):,} packages with GitHub URLs")
    
    # Apply start and count filters
    end_index = args.start + args.count if args.count else len(packages_with_github)
    packages_to_fetch = packages_with_github[args.start:end_index]
    
    print(f"✓ Will fetch packages {args.start} to {min(end_index, len(packages_with_github))-1} ({len(packages_to_fetch):,} packages)")
    
    if not packages_to_fetch:
        print("❌ No packages to fetch with given filters")
        sys.exit(1)
    
    # 4. Load existing cache
    mapping_file = Path('github_tags_mapping.json')
    cache = {}
    if mapping_file.exists():
        print(f"\n[4/6] Loading existing cache from {mapping_file}...")
        with open(mapping_file) as f:
            cache = json.load(f)
        print(f"✓ Loaded {len(cache):,} cached entries")
    else:
        print(f"\n[4/6] No existing cache found, will create new one")
    
    # 5. Fetch releases/tags
    print("\n[5/6] Fetching GitHub releases/tags (last 5 years)...")
    
    # Get GitHub token from environment
    import os
    github_token = os.environ.get('GITHUB_TOKEN')
    
    if github_token:
        print(f"\n✓ GitHub token found (length: {len(github_token)})")
        print(f"  Token starts with: {github_token[:7]}...")
    else:
        print("\n⚠️  No GITHUB_TOKEN environment variable found")
        print("  Set it with: export GITHUB_TOKEN='your_token_here'")
    
    fetcher = GitHubFetcher(github_token)
    since_date = datetime.now() - timedelta(days=5*365)  # 5 years ago
    
    mapping = cache.copy()
    errors = []
    skipped = 0
    fetched = 0
    
    for i, pkg in enumerate(packages_to_fetch):
        pkg_name = pkg['package_name']
        github_url = pkg['github_url']
        ecosystem = pkg['ecosystem']
        actual_index = args.start + i
        
        print(f"\n[{actual_index}] {pkg_name} ({ecosystem})")
        print(f"    URL: {github_url}")
        
        # Skip if already in cache
        if pkg_name in mapping:
            print(f"    ✓ Already in cache (skipped)")
            skipped += 1
            continue
        
        # Extract repo info
        repo_info = fetcher.extract_repo_info(github_url)
        if not repo_info:
            print(f"    ✗ Invalid GitHub URL")
            errors.append({
                'package': pkg_name,
                'ecosystem': ecosystem,
                'url': github_url,
                'error': 'Invalid GitHub URL'
            })
            continue
        
        owner, repo = repo_info
        print(f"    Repo: {owner}/{repo}")
        
        try:
            versions, source = fetcher.fetch_releases(owner, repo, since_date)
            mapping[pkg_name] = {
                'github_url': github_url,
                'owner': owner,
                'repo': repo,
                'ecosystem': ecosystem,
                'versions': versions,
                'version_count': len(versions),
                'source': source,  # 'releases' or 'tags'
                'fetched_at': datetime.now().isoformat()
            }
            fetched += 1
            print(f"    ✓ Fetched {len(versions)} {source}")
            
            # Save after each fetch (cache)
            with open(mapping_file, 'w') as f:
                json.dump(mapping, f, indent=2)
            
        except Exception as e:
            print(f"    ✗ Error: {e}")
            errors.append({
                'package': pkg_name,
                'ecosystem': ecosystem,
                'url': github_url,
                'error': str(e)
            })
    
    # 6. Summary
    print(f"\n" + "=" * 70)
    print("RESULTS")
    print("=" * 70)
    print(f"✓ Fetched: {fetched:,} packages")
    print(f"✓ Skipped (cached): {skipped:,} packages")
    print(f"✓ Errors: {len(errors):,}")
    print(f"✓ API calls made: {fetcher.api_calls:,}")
    
    with open(mapping_file, 'w') as f:
        json.dump(mapping, f, indent=2)
    print(f"\n✓ Saved cache to {mapping_file}")
    
    # Save errors
    if errors:
        error_file = Path('github_tags_errors.json')
        with open(error_file, 'w') as f:
            json.dump(errors, f, indent=2)
        print(f"✓ Saved errors to {error_file}")
    
    # Statistics
    print("\n" + "=" * 70)
    print("CACHE STATISTICS")
    print("=" * 70)
    
    total_versions = sum(entry['version_count'] for entry in mapping.values())
    packages_with_versions = sum(1 for entry in mapping.values() if entry['version_count'] > 0)
    
    # Count by source
    from_releases = sum(1 for entry in mapping.values() if entry.get('source') == 'releases')
    from_tags = sum(1 for entry in mapping.values() if entry.get('source') == 'tags')
    
    print(f"\nTotal packages in cache: {len(mapping):,}")
    print(f"Packages with versions:  {packages_with_versions:,}")
    print(f"Total versions:          {total_versions:,}")
    if mapping:
        print(f"Average per package:     {total_versions / len(mapping):.1f}")
    print(f"\nSource breakdown:")
    print(f"  From releases API: {from_releases:,}")
    print(f"  From tags API:     {from_tags:,}")
    
    # Show packages fetched in this run
    if fetched > 0:
        print(f"\nPackages fetched in this run:")
        newly_fetched = [
            (name, data) for name, data in mapping.items()
            if name in [p['package_name'] for p in packages_to_fetch]
            and name not in cache
        ]
        for pkg_name, data in newly_fetched[:10]:  # Show first 10
            print(f"  {pkg_name:30s} {data['version_count']:4d} {data['source']}")
        if len(newly_fetched) > 10:
            print(f"  ... and {len(newly_fetched) - 10} more")
    
    print(f"\nOutput files:")
    print(f"  - {mapping_file}")
    if errors:
        print(f"  - github_tags_errors.json")
    
    # Next steps
    print(f"\nNext steps:")
    remaining = len(packages_with_github) - end_index
    if remaining > 0:
        cmd = f"python {sys.argv[0]}"
        if args.ecosystem:
            cmd += f" --ecosystem {args.ecosystem}"
        cmd += f" --start {end_index}"
        if args.count:
            cmd += f" --count {args.count}"
        print(f"  To continue: {cmd}")
        print(f"  Remaining: {remaining:,} packages")
    else:
        print(f"  ✓ All packages processed!")


if __name__ == '__main__':
    main()