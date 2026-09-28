#!/usr/bin/env python3
"""
Ruby gem version fetcher with GitHub fallback.

Reads from ruby.list (CSV with GitHub URLs) and fetches versions from:
1. RubyGems.org API - primary source for published gems
2. GitHub releases/tags - fallback when gem not found or for additional versions

Features:
- Dual-source version fetching
- Rate limiting for both APIs
- Caching to avoid re-fetching
- Incremental processing with --start and --count
- Detailed error reporting

Usage:
    python fetch_ruby_versions.py
    python fetch_ruby_versions.py --start 0 --count 10
    python fetch_ruby_versions.py --rubygems-only  # Skip GitHub fallback
"""

import json
import sys
import os
import csv
import argparse
import re
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Optional, Set
import requests

# Add scripts to path
sys.path.insert(0, str(Path(__file__).parent / 'scripts'))

from utils.retry import retry_with_backoff
from utils.validation import validate_package_name, ValidationError
from utils.security import mask_token
from utils.audit_logger import AuditLogger


class RubyGemsFetcher:
    """Fetch gem versions from RubyGems.org API."""
    
    def __init__(self):
        # RubyGems.org has no strict rate limits
        self.session = requests.Session()
        self.session.headers.update({
            'User-Agent': 'ruby-version-fetcher/1.0'
        })
    
    def normalize_gem_name(self, package_name: str, base_dir: str) -> str:
        """
        Normalize package name to gem name.
        
        Handles formats like:
        - rails -> rails
        - ruby-on-rails -> ruby-on-rails
        - owner__gem -> gem
        - redhat_ubi8 (invalid) -> use base_dir instead
        
        Args:
            package_name: Package name from CSV
            base_dir: Base directory name (fallback)
        
        Returns:
            Normalized gem name
        """
        # Skip obviously invalid gem names (build directories)
        invalid_names = ['redhat_ubi8', 'redhat_ubi9', 'ubuntu', 'dockerfiles', 'build']
        if package_name.lower() in invalid_names:
            # Use base_dir as the gem name instead
            package_name = base_dir
        
        # Remove owner prefix if present (e.g., "owner__gem" -> "gem")
        if '__' in package_name:
            parts = package_name.split('__')
            package_name = parts[-1]
        
        # Convert underscores to hyphens (Ruby convention)
        # But keep if it's already the gem name format
        return package_name.lower()
    
    @retry_with_backoff(max_retries=2)
    def fetch_versions(self, gem_name: str) -> Optional[List[str]]:
        """
        Fetch versions from RubyGems.org API.
        
        Args:
            gem_name: Gem name
        
        Returns:
            List of version strings or None if not found
        """
        # RubyGems.org API endpoint
        url = f'https://rubygems.org/api/v1/versions/{gem_name}.json'
        
        try:
            response = self.session.get(url, timeout=10)
            
            if response.status_code == 404:
                return None  # Gem not found
            
            response.raise_for_status()
            
            # Parse versions
            versions_data = response.json()
            versions = [v['number'] for v in versions_data if v.get('number')]
            
            return versions if versions else None
            
        except requests.exceptions.RequestException as e:
            print(f"      RubyGems error: {e}")
            return None


class GitHubFetcher:
    """Fetch GitHub releases/tags."""
    
    def __init__(self, github_token: Optional[str] = None):
        self.github_token = github_token
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
        
        Raises:
            requests.exceptions.HTTPError: If rate limit exceeded (403)
        """
        # Try releases first
        url = f'https://api.github.com/repos/{owner}/{repo}/releases'
        
        try:
            response = self.session.get(url, params={'per_page': 100}, timeout=10)
            
            if response.status_code == 403:
                # Rate limit exceeded - re-raise to stop execution
                print(f"      ❌ GitHub rate limit exceeded!")
                raise requests.exceptions.HTTPError("Rate limit exceeded", response=response)
            
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
            
        except requests.exceptions.HTTPError:
            # Re-raise rate limit errors
            raise
        except requests.exceptions.RequestException as e:
            print(f"      GitHub releases error: {e}")
            return self.fetch_tags(owner, repo)
    
    @retry_with_backoff(max_retries=2)
    def fetch_tags(self, owner: str, repo: str) -> Optional[List[str]]:
        """
        Fetch tags from GitHub.
        
        Raises:
            requests.exceptions.HTTPError: If rate limit exceeded (403)
        """
        url = f'https://api.github.com/repos/{owner}/{repo}/tags'
        
        try:
            response = self.session.get(url, params={'per_page': 100}, timeout=10)
            
            if response.status_code == 403:
                # Rate limit exceeded - re-raise to stop execution
                print(f"      ❌ GitHub rate limit exceeded!")
                raise requests.exceptions.HTTPError("Rate limit exceeded", response=response)
            
            if response.status_code == 404:
                return None
            
            response.raise_for_status()
            tags = response.json()
            
            if tags:
                return [t['name'] for t in tags if t.get('name')]
            
            return None
            
        except requests.exceptions.HTTPError:
            # Re-raise rate limit errors
            raise
        except requests.exceptions.RequestException as e:
            print(f"      GitHub tags error: {e}")
            return None


def read_ruby_list(file_path: str) -> List[Dict[str, str]]:
    """
    Read ruby.list CSV file.
    
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


def main():
    parser = argparse.ArgumentParser(
        description='Ruby gem version fetcher with GitHub fallback',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s                          # Fetch all packages (RubyGems only)
  %(prog)s --start 0 --count 10     # First 10 packages
  %(prog)s --github-fallback        # Enable GitHub fallback (requires GITHUB_TOKEN)
        """
    )
    
    parser.add_argument('--start', type=int, default=0,
                        help='Start index (0-based, default: 0)')
    parser.add_argument('--count', type=int, default=None,
                        help='Number of packages to fetch (default: all)')
    parser.add_argument('--github-fallback', action='store_true',
                        help='Enable GitHub fallback (default: RubyGems only)')
    parser.add_argument('--input', type=str, default='ruby.list',
                        help='Input CSV file (default: ruby.list)')
    parser.add_argument('--output', type=str, default='ruby_versions_mapping.json',
                        help='Output mapping file (default: ruby_versions_mapping.json)')
    parser.add_argument('--errors', type=str, default='ruby_versions_errors.json',
                        help='Error log file (default: ruby_versions_errors.json)')
    
    args = parser.parse_args()
    
    print("=" * 70)
    print("RUBY GEM VERSION FETCHER (with GitHub fallback)")
    print("=" * 70)
    print(f"Input file: {args.input}")
    print(f"Start index: {args.start}")
    print(f"Count: {args.count if args.count else 'all'}")
    print(f"Mode: {'RubyGems + GitHub fallback' if args.github_fallback else 'RubyGems only'}")
    print()
    
    # Check for GitHub token
    github_token = os.environ.get('GITHUB_TOKEN')
    if args.github_fallback:
        if github_token:
            masked = mask_token(github_token)
            print(f"✓ Using GITHUB_TOKEN from environment: {masked}")
        else:
            print("❌ ERROR: --github-fallback requires GITHUB_TOKEN environment variable")
            print("   Set it with: export GITHUB_TOKEN=your_token_here")
            return 1
    else:
        print("ℹ️  GitHub fallback disabled (RubyGems.org should have all gems)")
    print()
    
    # Initialize fetchers
    rubygems = RubyGemsFetcher()
    github = GitHubFetcher(github_token) if args.github_fallback else None
    audit_logger = AuditLogger(output_dir=Path(args.output).parent)
    
    # Read input file
    print(f"Reading {args.input}...")
    if not Path(args.input).exists():
        print(f"❌ File not found: {args.input}")
        print("   Generate it with:")
        print("   python extract_build_script_info.py --input ~/src/build-scripts-v2 --output build_scripts_info.csv")
        print("   grep ',Ruby,' build_scripts_info.csv > ruby.list")
        return 1
    
    packages = read_ruby_list(args.input)
    print(f"✓ Found {len(packages)} Ruby packages")
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
    
    # Process packages
    stats = {
        'total': len(packages_to_process),
        'skipped_cached': 0,
        'rubygems_success': 0,
        'github_success': 0,
        'both_success': 0,
        'failed': 0
    }
    
    for i, pkg in enumerate(packages_to_process, 1):
        package_name = pkg['package_name']
        base_dir = pkg['base_dir']
        github_url = pkg['package_url']
        
        print(f"[{i}/{len(packages_to_process)}] {package_name}")
        
        # Skip if already cached
        if package_name in mapping:
            print(f"  ✓ Already cached ({len(mapping[package_name]['versions'])} versions)")
            stats['skipped_cached'] += 1
            continue
        
        # Normalize gem name
        gem_name = rubygems.normalize_gem_name(package_name, base_dir)
        if gem_name != package_name.lower():
            print(f"  Note: Using '{gem_name}' instead of '{package_name}'")
        print(f"  Gem: {gem_name}")
        
        # Validate gem name before processing
        try:
            validated_name = validate_package_name(
                gem_name,
                ecosystem='rubygems',
                max_length=200
            )
        except ValidationError as e:
            print(f"  ✗ Validation error: {e}")
            errors[package_name] = {
                'gem_name': gem_name,
                'base_dir': base_dir,
                'github_url': github_url,
                'error': f"Validation failed: {str(e)}",
                'error_type': 'validation'
            }
            stats['failed'] += 1
            continue
        
        rubygems_versions = None
        github_versions = None
        
        # Try RubyGems.org
        print(f"  Trying RubyGems.org...")
        rubygems_versions = rubygems.fetch_versions(gem_name)
        if rubygems_versions:
            print(f"  ✓ RubyGems: {len(rubygems_versions)} versions")
            stats['rubygems_success'] += 1
        else:
            print(f"  ✗ Not found on RubyGems.org")
        
        # Try GitHub (if enabled)
        if github and github_url:
            repo_info = github.extract_repo_info(github_url)
            if repo_info:
                owner, repo = repo_info
                print(f"  Trying GitHub: {owner}/{repo}...")
                try:
                    github_versions = github.fetch_releases(owner, repo)
                    if github_versions:
                        print(f"  ✓ GitHub: {len(github_versions)} versions")
                        stats['github_success'] += 1
                    else:
                        print(f"  ✗ No GitHub releases/tags found")
                except requests.exceptions.HTTPError as e:
                    if 'rate limit' in str(e).lower() or (hasattr(e, 'response') and e.response.status_code == 403):
                        print()
                        print("=" * 70)
                        print("❌ GITHUB RATE LIMIT EXCEEDED")
                        print("=" * 70)
                        print("Stopping execution to avoid generating invalid data.")
                        print("Please wait for rate limit to reset or set GITHUB_TOKEN.")
                        print()
                        # Save what we have so far
                        with open(args.output, 'w') as f:
                            json.dump(mapping, f, indent=2)
                        with open(args.errors, 'w') as f:
                            json.dump(errors, f, indent=2)
                        return 1
                    else:
                        raise
        
        # Combine results
        sources = []
        if rubygems_versions or github_versions:
            all_versions = set()
            
            if rubygems_versions:
                all_versions.update(rubygems_versions)
                sources.append('rubygems')
            
            if github_versions:
                all_versions.update(github_versions)
                sources.append('github')
            
            if rubygems_versions and github_versions:
                stats['both_success'] += 1
            
            mapping[package_name] = {
                'gem_name': gem_name,
                'github_url': github_url,
                'versions': sorted(list(all_versions)),
                'sources': sources,
                'fetched_at': datetime.now().isoformat()
            }
            
            print(f"  ✓ Total unique versions: {len(all_versions)} (from: {', '.join(sources)})")
        else:
            # Log to audit logger
            attempted = ['rubygems']
            if github and github_url:
                attempted.append('github')
            
            audit_logger.log_no_versions(
                package_name=package_name,
                ecosystem='rubygems',
                attempted_sources=attempted,
                package_url=github_url,
                script_path=pkg['script_path'],
                gem_name=gem_name,
                base_dir=base_dir
            )
            print(f"  ✗ No versions found from any source - logged to audit")
            errors[package_name] = {
                'gem_name': gem_name,
                'github_url': github_url,
                'error': 'No versions found from RubyGems or GitHub'
            }
            stats['failed'] += 1
        
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
    
    # Close audit logger
    audit_logger.close()
    
    print()
    print("=" * 70)
    print("SUMMARY")
    print("=" * 70)
    print(f"Total processed: {stats['total']}")
    print(f"Skipped (cached): {stats['skipped_cached']}")
    print(f"RubyGems success: {stats['rubygems_success']}")
    print(f"GitHub success: {stats['github_success']}")
    print(f"Both sources: {stats['both_success']}")
    print(f"Failed: {stats['failed']}")
    print()
    print(f"✓ Mappings saved to: {args.output}")
    print(f"✓ Errors saved to: {args.errors}")
    
    return 0


if __name__ == '__main__':
    exit(main())