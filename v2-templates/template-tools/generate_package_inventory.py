#!/usr/bin/env python3
"""
generate_package_inventory.py - Generate CSV inventory of all packages

Scans build-scripts directory tree for build_info.json files and generates
a comprehensive CSV inventory of all packages with metadata.

Usage:
    ./generate_package_inventory.py [OPTIONS] [DIRECTORY]

Arguments:
    DIRECTORY           Directory to scan (default: current directory)

Options:
    -o, --output FILE   Output CSV file (default: stdout)
    -q, --quiet         Suppress progress messages
    -h, --help          Show this help

Output CSV columns:
    Package Name        - Package name from build_info.json
    Package Version     - Default version from build_info.json
    Language            - Detected from template (python.sh, base.sh, etc.)
    Language Version    - Language version if specified (often empty)
    GitHub URL          - Repository URL
    Build Deps          - Comma-separated list of build dependencies
    Provides Artifact   - Artifact name if this package provides one

Language Detection:
    - python.sh     -> python
    - base.sh       -> c++ (or c, fortran, rust - check build_info.json)
    - node.sh       -> node
    - go.sh         -> go
    - java.sh       -> java
    - ruby.sh       -> ruby
    - Falls back to build_info.json 'language' field if present

Examples:
    # Scan current directory, output to stdout
    ./generate_package_inventory.py

    # Scan specific directory, output to file
    ./generate_package_inventory.py /path/to/build-scripts -o inventory.csv

    # Scan subdirectory
    ./generate_package_inventory.py ./p/pytorch
"""

import argparse
import csv
import json
import os
import re
import sys
from pathlib import Path
from typing import Optional


# Template to language mapping
TEMPLATE_LANGUAGE_MAP = {
    "python.sh": "python",
    "node.sh": "node",
    "nodejs.sh": "node",
    "go.sh": "go",
    "java.sh": "java",
    "ruby.sh": "ruby",
    "php.sh": "php",
    "rust.sh": "rust",
    "conda.sh": "conda",
    "base.sh": None,  # Need to check build_info.json for c/c++/fortran/rust
}

# Language normalization
LANGUAGE_NORMALIZE = {
    "c++": "c++",
    "cpp": "c++",
    "c": "c",
    "fortran": "fortran",
    "rust": "rust",
    "python": "python",
    "node": "node",
    "nodejs": "node",
    "javascript": "node",
    "go": "go",
    "golang": "go",
    "java": "java",
    "ruby": "ruby",
    "php": "php",
    "conda": "conda",
}


def find_build_info_files(base_dir: Path) -> list[Path]:
    """Find all build_info.json files in directory tree."""
    results = []
    for root, dirs, files in os.walk(base_dir):
        # Skip hidden directories and common non-package dirs
        dirs[:] = [d for d in dirs if not d.startswith('.') and d not in ('templates', 'docs', '__pycache__')]

        if 'build_info.json' in files:
            results.append(Path(root) / 'build_info.json')

    return sorted(results)


def load_build_info(path: Path) -> Optional[dict]:
    """Load and parse build_info.json file."""
    try:
        with open(path, 'r', encoding='utf-8') as f:
            return json.load(f)
    except (json.JSONDecodeError, IOError) as e:
        print(f"Warning: Failed to load {path}: {e}", file=sys.stderr)
        return None


def detect_template_from_script(script_path: Path) -> Optional[str]:
    """
    Parse build script to find which template it sources.

    Looks for patterns like:
        source "${SCRIPT_DIR}/../../templates/python.sh"
        source "$SCRIPT_DIR/../../templates/base.sh"
    """
    if not script_path.exists():
        return None

    try:
        with open(script_path, 'r', encoding='utf-8', errors='replace') as f:
            content = f.read()
    except IOError:
        return None

    # Look for template source patterns
    # Match: source "...templates/XXX.sh" or source '...templates/XXX.sh'
    patterns = [
        r'source\s+["\'].*?/templates/(\w+\.sh)["\']',
        r'source\s+\$\{?SCRIPT_DIR\}?.*?/templates/(\w+\.sh)',
        r'\.\s+["\'].*?/templates/(\w+\.sh)["\']',
        r'\.\s+\$\{?SCRIPT_DIR\}?.*?/templates/(\w+\.sh)',
    ]

    for pattern in patterns:
        match = re.search(pattern, content)
        if match:
            return match.group(1)

    return None


def detect_language(build_info: dict, script_path: Optional[Path]) -> str:
    """
    Detect language for a package.

    Priority:
    1. Template file (python.sh -> python, etc.)
    2. build_info.json 'language' field
    3. Default to 'unknown'
    """
    # Try template detection first
    if script_path:
        template = detect_template_from_script(script_path)
        if template:
            lang = TEMPLATE_LANGUAGE_MAP.get(template)
            if lang:
                return lang
            # base.sh - need to check build_info.json
            if template == "base.sh":
                bi_lang = build_info.get('language', '').lower()
                normalized = LANGUAGE_NORMALIZE.get(bi_lang, bi_lang)
                if normalized:
                    return normalized
                return "c++"  # Default for base.sh

    # Fall back to build_info.json
    bi_lang = build_info.get('language', '').lower()
    normalized = LANGUAGE_NORMALIZE.get(bi_lang, bi_lang)
    if normalized:
        return normalized

    return "unknown"


def get_build_script_path(build_info: dict, build_info_path: Path) -> Optional[Path]:
    """Get the path to the build script from build_info.json."""
    script_name = build_info.get('build_script')
    if not script_name:
        # Try to find a .sh file with same name as directory
        pkg_dir = build_info_path.parent
        pkg_name = build_info.get('package_name', pkg_dir.name)
        candidates = [
            pkg_dir / f"{pkg_name}.sh",
            pkg_dir / f"{pkg_name.replace('-', '_')}.sh",
            pkg_dir / f"{pkg_name.replace('_', '-')}.sh",
        ]
        for candidate in candidates:
            if candidate.exists():
                return candidate
        return None

    return build_info_path.parent / script_name


def extract_package_info(build_info: dict, build_info_path: Path) -> dict:
    """Extract all relevant fields from build_info.json."""
    script_path = get_build_script_path(build_info, build_info_path)

    # Get build_deps as comma-separated string
    build_deps = build_info.get('build_deps', [])
    if isinstance(build_deps, list):
        build_deps_str = ','.join(build_deps)
    else:
        build_deps_str = str(build_deps)

    return {
        'package_name': build_info.get('package_name', ''),
        'package_version': build_info.get('version', ''),
        'language': detect_language(build_info, script_path),
        'language_version': build_info.get('language_version', ''),
        'github_url': build_info.get('github_url', ''),
        'build_deps': build_deps_str,
        'provides_artifact': build_info.get('provides_artifact', ''),
    }


def generate_inventory(base_dir: Path, quiet: bool = False) -> list[dict]:
    """Generate inventory of all packages in directory tree."""
    build_info_files = find_build_info_files(base_dir)

    if not quiet:
        print(f"Found {len(build_info_files)} build_info.json files", file=sys.stderr)

    inventory = []
    for path in build_info_files:
        build_info = load_build_info(path)
        if build_info is None:
            continue

        info = extract_package_info(build_info, path)
        if info['package_name']:  # Skip entries without package name
            inventory.append(info)

    if not quiet:
        print(f"Processed {len(inventory)} packages", file=sys.stderr)

    return inventory


def write_csv(inventory: list[dict], output_file=None):
    """Write inventory to CSV."""
    fieldnames = [
        'Package Name',
        'Package Version',
        'Language',
        'Language Version',
        'GitHub URL',
        'Build Deps',
        'Provides Artifact',
    ]

    # Map internal keys to display names
    key_map = {
        'package_name': 'Package Name',
        'package_version': 'Package Version',
        'language': 'Language',
        'language_version': 'Language Version',
        'github_url': 'GitHub URL',
        'build_deps': 'Build Deps',
        'provides_artifact': 'Provides Artifact',
    }

    if output_file:
        f = open(output_file, 'w', newline='', encoding='utf-8')
    else:
        f = sys.stdout

    try:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()

        for item in inventory:
            row = {key_map[k]: v for k, v in item.items()}
            writer.writerow(row)
    finally:
        if output_file:
            f.close()


def main():
    parser = argparse.ArgumentParser(
        description='Generate CSV inventory of all packages in build-scripts tree',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__.split('Examples:')[1] if 'Examples:' in __doc__ else ''
    )
    parser.add_argument(
        'directory',
        nargs='?',
        default='.',
        help='Directory to scan (default: current directory)'
    )
    parser.add_argument(
        '-o', '--output',
        help='Output CSV file (default: stdout)'
    )
    parser.add_argument(
        '-q', '--quiet',
        action='store_true',
        help='Suppress progress messages'
    )

    args = parser.parse_args()

    base_dir = Path(args.directory).resolve()
    if not base_dir.exists():
        print(f"Error: Directory not found: {base_dir}", file=sys.stderr)
        sys.exit(1)

    inventory = generate_inventory(base_dir, quiet=args.quiet)

    if not inventory:
        print("Warning: No packages found", file=sys.stderr)
        sys.exit(0)

    write_csv(inventory, args.output)

    if args.output and not args.quiet:
        print(f"Wrote {len(inventory)} packages to {args.output}", file=sys.stderr)


if __name__ == '__main__':
    main()
