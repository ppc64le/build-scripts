#!/usr/bin/env python3
"""
Analyze packages from github_tags_missing.csv against version caches.

Compares a CSV of "missing" packages against:
1. github_tags_mapping.json (GitHub releases/tags cache)
2. Language-specific registry files (pypi, npm, go, maven, etc.)

Outputs:
1. packages_not_in_cache.csv - Packages completely missing from GitHub cache
2. versions_not_in_cache.csv - Packages in cache but requested version too old/missing
3. analysis_summary.txt - Human-readable summary

Usage:
    python analyze_missing_versions.py [--input FILE] [--version-data DIR] [--output-dir DIR]

Examples:
    python analyze_missing_versions.py
    python analyze_missing_versions.py --input ./github_tags_missing.csv
    python analyze_missing_versions.py --version-data ./version_data --output-dir ./analysis
"""

import argparse
import csv
import json
import sys
from datetime import datetime
from pathlib import Path
from typing import Optional


# Language to version file mapping (same as version_matcher.py)
LANGUAGE_VERSION_FILES = {
    "python": "pypi_versions.json",
    "node": "npm_versions.json",
    "nodejs": "npm_versions.json",
    "javascript": "npm_versions.json",
    "go": "go_versions.json",
    "golang": "go_versions.json",
    "php": "packagist_versions.json",
    "java": "maven_versions.json",
    "ruby": "ruby_versions.json",
}

GITHUB_CACHE_FILE = "github_tags_mapping.json"


def load_json_file(path: Path) -> dict:
    """Load a JSON file, return empty dict on error."""
    if not path.exists():
        return {}
    try:
        with open(path, 'r', encoding='utf-8') as f:
            return json.load(f)
    except (json.JSONDecodeError, IOError) as e:
        print(f"Warning: Failed to load {path}: {e}", file=sys.stderr)
        return {}


def read_csv_skip_comments(path: Path) -> list[dict]:
    """Read CSV file, skipping comment lines starting with #."""
    rows = []
    with open(path, 'r', encoding='utf-8', newline='') as f:
        lines = [line for line in f if not line.strip().startswith('#')]
        reader = csv.DictReader(lines)
        for row in reader:
            rows.append(row)
    return rows


def extract_github_versions(pkg_data: dict) -> list[str]:
    """Extract version names from GitHub cache entry."""
    versions = pkg_data.get('versions', [])
    if isinstance(versions, list):
        return [v.get('name', v) if isinstance(v, dict) else str(v) for v in versions]
    return []


def extract_registry_versions(pkg_data: dict) -> list[str]:
    """Extract version names from registry cache entry."""
    versions = pkg_data.get('versions', [])
    if isinstance(versions, list):
        # Handle both simple lists and lists of dicts
        result = []
        for v in versions:
            if isinstance(v, dict):
                result.append(v.get('version', v.get('name', str(v))))
            else:
                result.append(str(v))
        return result
    return []


def get_latest_date(pkg_data: dict) -> Optional[str]:
    """Get the most recent release date from GitHub cache entry."""
    versions = pkg_data.get('versions', [])
    if not versions:
        return None

    dates = []
    for v in versions:
        if isinstance(v, dict):
            date_str = v.get('date')
            if date_str:
                try:
                    dates.append(datetime.fromisoformat(date_str.replace('Z', '+00:00')))
                except ValueError:
                    pass

    if dates:
        return max(dates).strftime('%Y-%m-%d')
    return None


def find_in_registry(pkg_name: str, language: str, registry_data: dict) -> Optional[dict]:
    """Find package in registry data using various strategies."""
    if not registry_data:
        return None

    pkg_lower = pkg_name.lower()

    # Strategy 1: Exact match
    if pkg_name in registry_data:
        return registry_data[pkg_name]

    # Strategy 2: Case-insensitive
    for key in registry_data:
        if key.lower() == pkg_lower:
            return registry_data[key]

    # Strategy 3: For Go, try with/without github.com prefix
    if language.lower() in ('go', 'golang'):
        if pkg_name.startswith('github.com/'):
            short_name = pkg_name.split('/')[-1]
            for key in registry_data:
                if key.lower() == short_name.lower():
                    return registry_data[key]
        else:
            for key in registry_data:
                if key.endswith('/' + pkg_name) or key.endswith('/' + pkg_name.lower()):
                    return registry_data[key]

    return None


def analyze_packages(
    input_csv: Path,
    version_data_dir: Path,
    output_dir: Path
) -> None:
    """Main analysis function."""

    print(f"Loading input CSV: {input_csv}")
    missing_packages = read_csv_skip_comments(input_csv)
    print(f"  Found {len(missing_packages)} entries")

    # Load GitHub cache
    github_cache_path = version_data_dir / GITHUB_CACHE_FILE
    print(f"Loading GitHub cache: {github_cache_path}")
    github_cache = load_json_file(github_cache_path)
    print(f"  Loaded {len(github_cache)} packages")

    # Load registry caches
    registry_caches = {}
    for lang, filename in LANGUAGE_VERSION_FILES.items():
        if filename not in [f for f in registry_caches.values()]:
            path = version_data_dir / filename
            if path.exists():
                data = load_json_file(path)
                registry_caches[filename] = data
                print(f"  Loaded {filename}: {len(data)} packages")

    # Analyze each package
    not_in_cache = []  # Package not in GitHub cache at all
    version_mismatch = []  # Package in cache but version not found

    for row in missing_packages:
        pkg_name = row.get('package_name', '').strip()
        want_version = row.get('package_version', '').strip()
        language = row.get('language', '').strip()
        script_path = row.get('script_path', '').strip()
        package_url = row.get('package_url', '').strip()

        if not pkg_name:
            continue

        # Check GitHub cache
        github_pkg = None
        github_key = None

        # Try exact match first
        if pkg_name in github_cache:
            github_pkg = github_cache[pkg_name]
            github_key = pkg_name
        else:
            # Try case-insensitive
            for key in github_cache:
                if key.lower() == pkg_name.lower():
                    github_pkg = github_cache[key]
                    github_key = key
                    break

        # Get registry data
        registry_file = LANGUAGE_VERSION_FILES.get(language.lower())
        registry_data = registry_caches.get(registry_file, {}) if registry_file else {}
        registry_pkg = find_in_registry(pkg_name, language, registry_data)

        if github_pkg is None:
            # Package not in GitHub cache
            registry_versions = extract_registry_versions(registry_pkg) if registry_pkg else []
            not_in_cache.append({
                'package_name': pkg_name,
                'requested_version': want_version,
                'language': language,
                'script_path': script_path,
                'package_url': package_url,
                'in_registry': 'yes' if registry_pkg else 'no',
                'registry_version_count': len(registry_versions),
                'registry_latest': registry_versions[0] if registry_versions else '',
            })
        else:
            # Package in cache but check if version exists
            github_versions = extract_github_versions(github_pkg)
            latest_date = get_latest_date(github_pkg)
            source = github_pkg.get('source', 'unknown')

            # Check if requested version is in the list
            version_found = want_version in github_versions

            # Also check normalized (with/without 'v' prefix)
            if not version_found:
                want_norm = want_version.lstrip('v')
                for gv in github_versions:
                    if gv.lstrip('v') == want_norm:
                        version_found = True
                        break

            if not version_found:
                # Get registry info for cross-reference
                registry_versions = extract_registry_versions(registry_pkg) if registry_pkg else []
                version_in_registry = want_version in registry_versions
                if not version_in_registry:
                    want_norm = want_version.lstrip('v')
                    version_in_registry = any(rv.lstrip('v') == want_norm for rv in registry_versions)

                version_mismatch.append({
                    'package_name': pkg_name,
                    'github_key': github_key,
                    'requested_version': want_version,
                    'language': language,
                    'script_path': script_path,
                    'package_url': package_url,
                    'github_source': source,
                    'github_version_count': len(github_versions),
                    'github_newest': github_versions[0] if github_versions else '',
                    'github_oldest': github_versions[-1] if github_versions else '',
                    'github_last_release': latest_date or '',
                    'github_all_versions': ';'.join(github_versions[:20]) + ('...' if len(github_versions) > 20 else ''),
                    'in_registry': 'yes' if registry_pkg else 'no',
                    'version_in_registry': 'yes' if version_in_registry else 'no',
                    'registry_version_count': len(registry_versions),
                })

    # Create output directory
    output_dir.mkdir(parents=True, exist_ok=True)

    # Write packages not in cache
    not_in_cache_file = output_dir / 'packages_not_in_cache.csv'
    print(f"\nWriting {len(not_in_cache)} packages not in cache to: {not_in_cache_file}")
    with open(not_in_cache_file, 'w', encoding='utf-8', newline='') as f:
        if not_in_cache:
            writer = csv.DictWriter(f, fieldnames=not_in_cache[0].keys())
            writer.writeheader()
            writer.writerows(not_in_cache)

    # Write version mismatches
    version_mismatch_file = output_dir / 'versions_not_in_cache.csv'
    print(f"Writing {len(version_mismatch)} version mismatches to: {version_mismatch_file}")
    with open(version_mismatch_file, 'w', encoding='utf-8', newline='') as f:
        if version_mismatch:
            writer = csv.DictWriter(f, fieldnames=version_mismatch[0].keys())
            writer.writeheader()
            writer.writerows(version_mismatch)

    # Write summary
    summary_file = output_dir / 'analysis_summary.txt'
    print(f"Writing summary to: {summary_file}")

    with open(summary_file, 'w', encoding='utf-8') as f:
        f.write("=" * 70 + "\n")
        f.write("MISSING VERSIONS ANALYSIS SUMMARY\n")
        f.write("=" * 70 + "\n\n")
        f.write(f"Input file: {input_csv}\n")
        f.write(f"Analysis date: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n")

        f.write("OVERVIEW\n")
        f.write("-" * 40 + "\n")
        f.write(f"Total packages analyzed:        {len(missing_packages):,}\n")
        f.write(f"Packages not in GitHub cache:   {len(not_in_cache):,}\n")
        f.write(f"Packages with version mismatch: {len(version_mismatch):,}\n\n")

        # Breakdown by language
        f.write("BY LANGUAGE\n")
        f.write("-" * 40 + "\n")

        lang_stats = {}
        for row in not_in_cache:
            lang = row['language'] or 'unknown'
            lang_stats.setdefault(lang, {'not_in_cache': 0, 'version_mismatch': 0})
            lang_stats[lang]['not_in_cache'] += 1
        for row in version_mismatch:
            lang = row['language'] or 'unknown'
            lang_stats.setdefault(lang, {'not_in_cache': 0, 'version_mismatch': 0})
            lang_stats[lang]['version_mismatch'] += 1

        f.write(f"{'Language':<15} {'Not in Cache':>15} {'Version Mismatch':>18}\n")
        for lang in sorted(lang_stats.keys()):
            stats = lang_stats[lang]
            f.write(f"{lang:<15} {stats['not_in_cache']:>15,} {stats['version_mismatch']:>18,}\n")

        # Activity analysis for version mismatches
        f.write("\n\nACTIVITY ANALYSIS (packages with version mismatch)\n")
        f.write("-" * 40 + "\n")

        active_2024 = sum(1 for r in version_mismatch if r['github_last_release'] >= '2024-01-01')
        active_2023 = sum(1 for r in version_mismatch if '2023-01-01' <= r['github_last_release'] < '2024-01-01')
        active_2022 = sum(1 for r in version_mismatch if '2022-01-01' <= r['github_last_release'] < '2023-01-01')
        older = sum(1 for r in version_mismatch if r['github_last_release'] and r['github_last_release'] < '2022-01-01')
        no_date = sum(1 for r in version_mismatch if not r['github_last_release'])

        f.write(f"Last release in 2024+:  {active_2024:,}\n")
        f.write(f"Last release in 2023:   {active_2023:,}\n")
        f.write(f"Last release in 2022:   {active_2022:,}\n")
        f.write(f"Last release before 2022: {older:,}\n")
        f.write(f"No date available:      {no_date:,}\n")

        # Registry cross-reference
        f.write("\n\nREGISTRY CROSS-REFERENCE\n")
        f.write("-" * 40 + "\n")

        in_registry = sum(1 for r in version_mismatch if r['in_registry'] == 'yes')
        version_in_registry = sum(1 for r in version_mismatch if r['version_in_registry'] == 'yes')

        f.write(f"Packages also in language registry: {in_registry:,}\n")
        f.write(f"Requested version in registry:      {version_in_registry:,}\n")

        f.write("\n\nOUTPUT FILES\n")
        f.write("-" * 40 + "\n")
        f.write(f"1. {not_in_cache_file.name}\n")
        f.write(f"   Packages completely missing from GitHub cache.\n")
        f.write(f"   May need to fetch or may not have releases.\n\n")
        f.write(f"2. {version_mismatch_file.name}\n")
        f.write(f"   Packages in cache but requested version not found.\n")
        f.write(f"   Likely requesting versions older than 5-year fetch window.\n")

    # Print summary to stdout
    print("\n" + "=" * 70)
    print("ANALYSIS COMPLETE")
    print("=" * 70)
    print(f"Packages not in GitHub cache:   {len(not_in_cache):,}")
    print(f"Packages with version mismatch: {len(version_mismatch):,}")
    print(f"\nOutput files in: {output_dir}")


def main():
    parser = argparse.ArgumentParser(
        description='Analyze missing versions against GitHub and registry caches',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__
    )
    parser.add_argument(
        '--input', '-i',
        type=Path,
        default=Path('./output/templates/template-tools/github_tags_missing.csv'),
        help='Input CSV file (default: ./output/templates/template-tools/github_tags_missing.csv)'
    )
    parser.add_argument(
        '--version-data', '-v',
        type=Path,
        default=Path('./version_data'),
        help='Directory containing version JSON files (default: ./version_data)'
    )
    parser.add_argument(
        '--output-dir', '-o',
        type=Path,
        default=Path('./missing_versions_analysis'),
        help='Output directory for analysis files (default: ./missing_versions_analysis)'
    )

    args = parser.parse_args()

    if not args.input.exists():
        print(f"Error: Input file not found: {args.input}", file=sys.stderr)
        sys.exit(1)

    if not args.version_data.exists():
        print(f"Error: Version data directory not found: {args.version_data}", file=sys.stderr)
        sys.exit(1)

    analyze_packages(args.input, args.version_data, args.output_dir)


if __name__ == '__main__':
    main()
