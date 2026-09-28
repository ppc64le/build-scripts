#!/usr/bin/env python3
"""
Enhanced Go module version fetcher with GitHub fallback.

Reads from go2.list (CSV with GitHub URLs) and fetches versions from:
1. Go proxy (pkg.go.dev) - primary source for importable modules
2. GitHub releases/tags - fallback for applications and when proxy fails

Features:
- Dual-source version fetching
- Rate limiting for both APIs
- Caching to avoid re-fetching
- Incremental processing with --start and --count
- Detailed error reporting

Usage:
    python fetch_go_versions_enhanced.py
    python fetch_go_versions_enhanced.py --start 0 --count 10
    python fetch_go_versions_enhanced.py --github-only  # Skip proxy, use GitHub only
"""

import json
import sys
import os
import csv
import argparse
import re
from pathlib import Path
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Set
import requests

# Add scripts to path
sys.path.insert(0, str(Path(__file__).parent / 'scripts'))

from utils.rate_limiter import RateLimiter
from utils.retry import retry_with_backoff
from utils.validation import validate_package_name, ValidationError
from utils.security import mask_token
from utils.audit_logger import AuditLogger


class GoProxyFetcher:
    """Fetch Go module versions from proxy.golang.org."""
    
    def __init__(self):
        self.rate_limiter = RateLimiter(max_calls=100, period=60)
        self.session = requests.Session()
        self.session.headers.update({
            'User-Agent': 'go-version-fetcher/1.0'
        })
    
    @retry_with_backoff(max_retries=2)
    def fetch_versions(self, module_path: str) -> Optional[List[str]]:
        """
        Fetch versions from Go proxy.
        
        Args:
            module_path: Go module path (e.g., github.com/owner/repo)
        
        Returns:
            List of version strings or None if not found
        """
        self.rate_limiter.acquire()
        
        # Go proxy list endpoint
        url = f'https://proxy.golang.org/{module_path}/@v/list'
        
        try:
            response = self.session.get(url, timeout=10)
            
            if response.status_code == 404:
                return None  # Module not found on proxy
            
            response.raise_for_status()
            
            # Parse versions (one per line)
            versions = [v.strip() for v in response.text.strip().split('\n') if v.strip()]
            return versions if versions else None
            
        except requests.exceptions.RequestException as e:
            print(f"      Proxy error: {e}")
            return None


class GitHubFetcher:
    """Fetch GitHub releases/tags."""
    
    def __init__(self, github_token: Optional[str] = None):
        self.github_token = github_token
        self.rate_limiter = RateLimiter(max_calls=60, period=60)
        self.session = requests.Session()
        
        if github_token:
            if github_token.startswith('github_pat_') or github_token.startswith('github_'):
                auth_header = f'Bearer {github_token}'
            else:
                auth_header = f'token {github_token}'
            
            self.session.headers.update({
                'Authorization': auth_header,
                'Accept': 'application/vnd.github.v3+json'
            })
    
    def extract_repo_info(self, github_url: str) -> Optional[tuple]:
        """Extract owner and repo from GitHub URL."""
        if not github_url or 'github.com' not in github_url.lower():
            return None
        
        parts = github_url.rstrip('/').split('github.com/')
        if len(parts) < 2:
            return None
        
        path_parts = parts[1].split('/')
        if len(path_parts) < 2:
            return None
        
        owner = path_parts[0]
        repo = path_parts[1].replace('.git', '')
        
        return (owner, repo)
    
    @retry_with_backoff(max_retries=2)
    def fetch_releases(self, owner: str, repo: str) -> Optional[List[str]]:
        """
        Fetch releases/tags from GitHub.
        
        Args:
            owner: Repository owner
            repo: Repository name
        
        Returns:
            List of version strings or None if not found
        """
        self.rate_limiter.acquire()
        
        # Try releases first
        url = f'https://api.github.com/repos/{owner}/{repo}/releases'
        
        try:
            response = self.session.get(url, params={'per_page': 100}, timeout=10)
            
            if response.status_code == 404:
                return self.fetch_tags(owner, repo)
            
            response.raise_for_status()
            releases = response.json()
            
            if releases:
                versions = [r['tag_name'] for r in releases if r.get('tag_name')]
                if versions:
                    return versions
            
            # Fallback to tags
            return self.fetch_tags(owner, repo)
            
        except requests.exceptions.RequestException as e:
            print(f"      GitHub releases error: {e}")
            return self.fetch_tags(owner, repo)
    
    @retry_with_backoff(max_retries=2)
    def fetch_tags(self, owner: str, repo: str) -> Optional[List[str]]:
        """Fetch tags from GitHub."""
        self.rate_limiter.acquire()
        
        url = f'https://api.github.com/repos/{owner}/{repo}/tags'
        
        try:
            response = self.session.get(url, params={'per_page': 100}, timeout=10)
            
            if response.status_code == 404:
                return None
            
            response.raise_for_status()
            tags = response.json()
            
            if tags:
                return [t['name'] for t in tags if t.get('name')]
            
            return None
            
        except requests.exceptions.RequestException as e:
            print(f"      GitHub tags error: {e}")
            return None


def read_go2_list(file_path: str) -> List[Dict[str, str]]:
    """
    Read go2.list CSV file.
    
    Returns:
        List of dicts with package info
    """
    packages = []
    
    with open(file_path, 'r', encoding='utf-8') as f:
        reader = csv.reader(f)
        for row in reader:
            if len(row) >= 7:
                packages.append({
                    'base_dir': row[0],
                    'package_name': row[1],
                    'package_version': row[2],
                    'language': row[3],
                    'language_versions': row[4],
                    'script_path': row[5],
                    'package_url': row[6]
                })
    
    return packages


def extract_module_path(package_name: str, github_url: str) -> Optional[str]:
    """
    Extract Go module path from package name or GitHub URL.
    
    Args:
        package_name: Package name from CSV
        github_url: GitHub URL
    
    Returns:
        Module path or None
    """
    # If package_name looks like a module path, use it
    if '/' in package_name and ('github.com' in package_name or 'gitlab.com' in package_name):
        return package_name
    
    # Extract from GitHub URL
    if github_url and 'github.com' in github_url:
        parts = github_url.rstrip('/').split('github.com/')
        if len(parts) >= 2:
            path_parts = parts[1].split('/')
            if len(path_parts) >= 2:
                owner = path_parts[0]
                repo = path_parts[1].replace('.git', '')
                return f"github.com/{owner}/{repo}"
    
    return None


def main():
    parser = argparse.ArgumentParser(
        description='Enhanced Go version fetcher with GitHub fallback',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s                          # Fetch all packages
  %(prog)s --start 0 --count 10     # First 10 packages
  %(prog)s --github-only            # Skip Go proxy, use GitHub only
        """
    )
    
    parser.add_argument('--start', type=int, default=0,
                        help='Start index (0-based, default: 0)')
    parser.add_argument('--count', type=int, default=None,
                        help='Number of packages to fetch (default: all)')
    parser.add_argument('--github-only', action='store_true',
                        help='Skip Go proxy, use GitHub releases/tags only')
    parser.add_argument('--input', type=str, default='go2.list',
                        help='Input CSV file (default: go2.list)')
    parser.add_argument('--output', type=str, default='go_versions_enhanced_mapping.json',
                        help='Output mapping file (default: go_versions_enhanced_mapping.json)')
    parser.add_argument('--errors', type=str, default='go_versions_enhanced_errors.json',
                        help='Error log file (default: go_versions_enhanced_errors.json)')
    
    args = parser.parse_args()
    
    print("=" * 70)
    print("ENHANCED GO VERSION FETCHER (with GitHub fallback)")
    print("=" * 70)
    print(f"Input file: {args.input}")
    print(f"Start index: {args.start}")
    print(f"Count: {args.count if args.count else 'all'}")
    print(f"Mode: {'GitHub only' if args.github_only else 'Go proxy + GitHub fallback'}")
    print()
    
    # Check for GitHub token
    github_token = os.environ.get('GITHUB_TOKEN')
    if github_token:
        masked = mask_token(github_token)
        print(f"✓ Using GITHUB_TOKEN from environment: {masked}")
    else:
        print("⚠️  No GITHUB_TOKEN - GitHub rate limits will be lower")
    print()
    
    # Initialize fetchers
    go_proxy = None if args.github_only else GoProxyFetcher()
    github = GitHubFetcher(github_token)
    
    # Read input file
    print(f"Reading {args.input}...")
    if not Path(args.input).exists():
        print(f"❌ File not found: {args.input}")
        print("   Run: python extract_build_script_info.py --input ~/src/build-scripts-v2 --output go2.list")
        print("   Then: grep ',Go,' build_scripts_info.csv > go2.list")
        return 1
    
    packages = read_go2_list(args.input)
    print(f"✓ Found {len(packages)} Go packages")
    print()
    
    # Apply start/count filtering
    end_idx = args.start + args.count if args.count else len(packages)
    packages_to_process = packages[args.start:end_idx]
    
    print(f"Processing packages {args.start} to {min(end_idx, len(packages))-1}")
    print()
    
    # Load existing mappings
    mapping = {}
    if Path(args.output).exists():
        with open(args.output, 'r') as f:
            mapping = json.load(f)
        print(f"✓ Loaded {len(mapping)} existing mappings")
    
    # Load existing errors
    errors = {}
    if Path(args.errors).exists():
        with open(args.errors, 'r') as f:
            errors = json.load(f)
    
    # Initialize audit logger for packages with no versions
    audit_logger = AuditLogger(output_dir=Path(args.output).parent)
    
    # Process packages
    stats = {
        'total': len(packages_to_process),
        'skipped_cached': 0,
        'proxy_success': 0,
        'github_success': 0,
        'both_success': 0,
        'failed': 0
    }
    
    import time
    for i, pkg in enumerate(packages_to_process, 1):
        pkg_start = time.time()
        package_name = pkg['package_name']
        github_url = pkg['package_url']
        
        print(f"[{i}/{len(packages_to_process)}] {package_name}", flush=True)
        
        # Skip if already cached
        if package_name in mapping:
            elapsed = time.time() - pkg_start
            print(f"  ✓ Already cached ({len(mapping[package_name]['versions'])} versions) [{elapsed:.2f}s]", flush=True)
            stats['skipped_cached'] += 1
            continue
        
        # Extract module path
        module_path = extract_module_path(package_name, github_url)
        if not module_path:
            print(f"  ✗ Could not extract module path")
            errors[package_name] = "Could not extract module path"
            stats['failed'] += 1
            continue
        
        print(f"  Module: {module_path}")
        
        # Validate module path before processing
        try:
            validated_path = validate_package_name(
                module_path,
                ecosystem='go',
                max_length=300
            )
        except ValidationError as e:
            print(f"  ✗ Validation error: {e}")
            errors[package_name] = {
                'module_path': module_path,
                'github_url': github_url,
                'error': f"Validation failed: {str(e)}",
                'error_type': 'validation'
            }
            stats['failed'] += 1
            continue
        
        proxy_versions = None
        github_versions = None
        
        # Try Go proxy first (unless github-only mode)
        if go_proxy:
            print(f"  Trying Go proxy...", flush=True)
            proxy_versions = go_proxy.fetch_versions(module_path)
            if proxy_versions:
                print(f"  ✓ Proxy: {len(proxy_versions)} versions", flush=True)
                stats['proxy_success'] += 1
            else:
                print(f"  ✗ Not found on proxy (may be an application, not a library)", flush=True)
        
        # Try GitHub (always, as fallback or primary)
        repo_info = github.extract_repo_info(github_url)
        if repo_info:
            owner, repo = repo_info
            print(f"  Trying GitHub: {owner}/{repo}...", flush=True)
            import time
            start_time = time.time()
            github_versions = github.fetch_releases(owner, repo)
            elapsed = time.time() - start_time
            if github_versions:
                print(f"  ✓ GitHub: {len(github_versions)} versions ({elapsed:.1f}s)", flush=True)
                stats['github_success'] += 1
            else:
                print(f"  ✗ No GitHub releases/tags found ({elapsed:.1f}s)", flush=True)
        
        # Combine results
        sources = []
        if proxy_versions or github_versions:
            all_versions = set()
            
            if proxy_versions:
                all_versions.update(proxy_versions)
                sources.append('proxy')
            
            if github_versions:
                all_versions.update(github_versions)
                sources.append('github')
            
            if proxy_versions and github_versions:
                stats['both_success'] += 1
            
            mapping[package_name] = {
                'module_path': module_path,
                'github_url': github_url,
                'versions': sorted(list(all_versions)),
                'sources': sources,
                'fetched_at': datetime.now().isoformat()
            }
            
            print(f"  ✓ Total unique versions: {len(all_versions)} (from: {', '.join(sources)})")
        else:
            print(f"  ✗ No versions found from any source")
            errors[package_name] = {
                'module_path': module_path,
                'github_url': github_url,
                'error': 'No versions found from proxy or GitHub'
            }
            stats['failed'] += 1
            
            # Log to audit logger
            audit_logger.log_no_versions(
                package_name=package_name,
                ecosystem='go',
                attempted_sources=sources if sources else ['go_proxy', 'github'],
                package_url=github_url,
                script_path=pkg.get('script_path', ''),
                module_path=module_path,
                base_dir=pkg.get('base_dir', ''),
                package_version=pkg.get('package_version', ''),
                language_versions=pkg.get('language_versions', '')
            )
        
        print()
        
        # Save periodically
        if i % 10 == 0:
            with open(args.output, 'w') as f:
                json.dump(mapping, f, indent=2)
            with open(args.errors, 'w') as f:
                json.dump(errors, f, indent=2)
    
    # Final save
    print("Saving results...")
    with open(args.output, 'w') as f:
        json.dump(mapping, f, indent=2)
    with open(args.errors, 'w') as f:
        json.dump(errors, f, indent=2)
    
    print()
    # Close audit logger
    audit_logger.close()
    
    print("=" * 70)
    print("SUMMARY")
    print("=" * 70)
    print(f"Total processed: {stats['total']}")
    print(f"Skipped (cached): {stats['skipped_cached']}")
    print(f"Proxy success: {stats['proxy_success']}")
    print(f"GitHub success: {stats['github_success']}")
    print(f"Both sources: {stats['both_success']}")
    print(f"Failed: {stats['failed']}")
    print()
    print(f"✓ Mappings saved to: {args.output}")
    print(f"✓ Errors saved to: {args.errors}")
    
    return 0


if __name__ == '__main__':
    exit(main())