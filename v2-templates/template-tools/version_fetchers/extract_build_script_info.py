#!/usr/bin/env python3
"""
Extract package information from build scripts.

Parses shell scripts in ~/src/build-scripts-v2 or ~/src/build-scripts to extract:
- Package name
- Package version
- Package URL (GitHub/GitLab/etc.)
- Language
- Language version (NODE_VERSION, PYTHON_VERSION, etc.)
- Build script path

Supports both old and new build script formats.

Outputs a CSV file with all extracted information.

Usage:
    python extract_build_script_info.py
    python extract_build_script_info.py --input ~/src/build-scripts
    python extract_build_script_info.py --input ~/src/build-scripts-v2
    python extract_build_script_info.py --output custom_output.csv
"""

import os
import re
import csv
import argparse
from pathlib import Path
from typing import Dict, Optional, List


def extract_shell_variable(content: str, var_name: str) -> Optional[str]:
    """
    Extract a shell variable value from script content.
    
    Handles formats:
    - VAR=value
    - VAR="value"
    - VAR='value'
    - VAR="${1:-default}"  (extracts just 'default')
    - export VAR=value
    
    Args:
        content: Shell script content
        var_name: Variable name to extract
    
    Returns:
        Variable value (with shell syntax removed) or None if not found
    """
    # Try to match VAR="${1:-default}" and extract just the default value
    match = re.search(rf'^(?:export\s+)?{var_name}="\${{[^:]+:-([^}}]+)}}"', content, re.MULTILINE)
    if match:
        return match.group(1).strip()
    
    # Try to match VAR=${1:-default} (without quotes)
    match = re.search(rf'^(?:export\s+)?{var_name}=\${{[^:]+:-([^}}]+)}}', content, re.MULTILINE)
    if match:
        return match.group(1).strip()
    
    # Try other patterns (with optional export prefix)
    patterns = [
        rf'^(?:export\s+)?{var_name}="([^"]*)"',      # VAR="value" or export VAR="value"
        rf"^(?:export\s+)?{var_name}='([^']*)'",      # VAR='value' or export VAR='value'
        rf'^(?:export\s+)?{var_name}=([^"\'\s]+)',    # VAR=value or export VAR=value
    ]
    
    for pattern in patterns:
        match = re.search(pattern, content, re.MULTILINE)
        if match:
            value = match.group(1).strip()
            # Skip if it's a variable reference like $VERSION or ${VERSION}
            if value.startswith('$'):
                continue
            return value
    
    return None


def extract_comment_field(content: str, field_name: str) -> Optional[str]:
    """
    Extract a field from comments.
    
    Looks for patterns like:
    # Language: Node
    # Language      : Python
    # Language : Ruby
    
    Args:
        content: Shell script content
        field_name: Field name to extract (e.g., "Language")
    
    Returns:
        Field value or None if not found
    """
    # Handle various spacing patterns around the colon
    pattern = rf'#\s*{field_name}\s*:\s*(.+?)(?:\n|$)'
    match = re.search(pattern, content, re.IGNORECASE)
    if match:
        return match.group(1).strip()
    return None


def parse_build_script(script_path: Path) -> Dict[str, str]:
    """
    Parse a build script and extract all relevant information.
    
    Supports both old and new build script formats:
    - New format: Uses PACKAGE_NAME, PACKAGE_VERSION, PACKAGE_URL variables
    - Old format: May have info in comments or simple variable assignments
    
    Args:
        script_path: Path to the build script
    
    Returns:
        Dictionary with extracted information
    """
    try:
        with open(script_path, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
    except Exception as e:
        print(f"Warning: Could not read {script_path}: {e}")
        return {}
    
    # Extract base directory name (parent directory of the script)
    base_dir = script_path.parent.name
    
    # Extract variables (try shell variables first)
    package_name = extract_shell_variable(content, 'PACKAGE_NAME')
    package_version = extract_shell_variable(content, 'PACKAGE_VERSION')
    package_url = extract_shell_variable(content, 'PACKAGE_URL')
    
    # If package_name contains unexpanded variables or is literally "PACKAGE_NAME", treat it as not found
    if package_name and ('$' in package_name or package_name == 'PACKAGE_NAME'):
        package_name = None
    
    # For old format: try to extract from comments if not found in variables
    if not package_name:
        package_name = extract_comment_field(content, 'Package')
    if not package_version:
        package_version = extract_comment_field(content, 'Version')
    if not package_url:
        # Try various comment field names
        package_url = (extract_comment_field(content, 'Source repo') or
                      extract_comment_field(content, 'Source Repo') or
                      extract_comment_field(content, 'Source'))
    
    # Extract language from comments
    language = extract_comment_field(content, 'Language')
    
    # Extract language-specific versions
    node_version = extract_shell_variable(content, 'NODE_VERSION')
    python_version = extract_shell_variable(content, 'PYTHON_VERSION')
    go_version = extract_shell_variable(content, 'GO_VERSION')
    java_version = extract_shell_variable(content, 'JAVA_VERSION')
    php_version = extract_shell_variable(content, 'PHP_VERSION')
    ruby_version = extract_shell_variable(content, 'RUBY_VERSION')
    
    # Combine language versions into a single field
    language_versions = []
    if node_version:
        language_versions.append(f"Node:{node_version}")
    if python_version:
        language_versions.append(f"Python:{python_version}")
    if go_version:
        language_versions.append(f"Go:{go_version}")
    if java_version:
        language_versions.append(f"Java:{java_version}")
    if php_version:
        language_versions.append(f"PHP:{php_version}")
    if ruby_version:
        language_versions.append(f"Ruby:{ruby_version}")
    
    language_version_str = "; ".join(language_versions) if language_versions else ""
    
    return {
        'base_dir': base_dir,
        'package_name': package_name or base_dir,  # Fallback to base_dir if package_name not found
        'package_version': package_version or '',
        'language': language or '',
        'language_versions': language_version_str,
        'script_path': str(script_path),
        'package_url': package_url or '',
    }


def find_build_scripts(root_dir: Path) -> List[Path]:
    """
    Find all .sh files in the directory tree.
    
    Args:
        root_dir: Root directory to search
    
    Returns:
        List of paths to .sh files
    """
    build_scripts = []
    
    for script_path in root_dir.rglob('*.sh'):
        if script_path.is_file():
            build_scripts.append(script_path)
    
    return sorted(build_scripts)


def main():
    parser = argparse.ArgumentParser(
        description='Extract package information from build scripts',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s                                    # Use default ~/src/build-scripts-v2
  %(prog)s --input ~/custom/path              # Use custom input directory
  %(prog)s --output custom.csv                # Use custom output filename
  %(prog)s --input ~/path --output out.csv    # Both custom
        """
    )
    
    default_input = Path.home() / 'src' / 'build-scripts-v2'
    
    parser.add_argument(
        '--input',
        type=Path,
        default=default_input,
        help=f'Input directory with build scripts (default: {default_input})'
    )
    parser.add_argument(
        '--output',
        type=Path,
        default='build_scripts_info.csv',
        help='Output CSV file (default: build_scripts_info.csv)'
    )
    
    args = parser.parse_args()
    
    # Validate input directory
    if not args.input.exists():
        print(f"Error: Input directory does not exist: {args.input}")
        return 1
    
    if not args.input.is_dir():
        print(f"Error: Input path is not a directory: {args.input}")
        return 1
    
    print(f"Scanning build scripts in: {args.input}")
    print(f"Output file: {args.output}")
    print()
    
    # Find all build scripts
    print("Finding build scripts...")
    build_scripts = find_build_scripts(args.input)
    print(f"Found {len(build_scripts)} build scripts")
    print()
    
    # Parse all scripts
    print("Parsing build scripts...")
    results = []
    parsed_count = 0
    skipped_count = 0
    
    for i, script_path in enumerate(build_scripts, 1):
        if i % 100 == 0:
            print(f"  Processed {i}/{len(build_scripts)} scripts...")
        
        # Get relative path from input directory
        try:
            rel_path = script_path.relative_to(args.input)
        except ValueError:
            rel_path = script_path
        
        info = parse_build_script(script_path)
        
        if info:
            info['script_path'] = str(rel_path)
            results.append(info)
            parsed_count += 1
        else:
            skipped_count += 1
    
    print(f"  Processed {len(build_scripts)}/{len(build_scripts)} scripts")
    print(f"  Parsed: {parsed_count}")
    print(f"  Skipped: {skipped_count}")
    print()
    
    # Write CSV
    print(f"Writing CSV to {args.output}...")
    
    fieldnames = [
        'base_dir',
        'package_name',
        'package_version',
        'language',
        'language_versions',
        'script_path',
        'package_url',
    ]
    
    with open(args.output, 'w', newline='', encoding='utf-8') as csvfile:
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(results)
    
    print(f"✓ Wrote {len(results)} entries to {args.output}")
    print()
    
    # Statistics
    print("Statistics:")
    print(f"  Total scripts: {len(build_scripts)}")
    print(f"  With package_name: {sum(1 for r in results if r['package_name'])}")
    print(f"  With package_url: {sum(1 for r in results if r['package_url'])}")
    print(f"  With language: {sum(1 for r in results if r['language'])}")
    print(f"  With language_versions: {sum(1 for r in results if r['language_versions'])}")
    
    # Language breakdown
    languages = {}
    for r in results:
        lang = r['language'] or 'Unknown'
        languages[lang] = languages.get(lang, 0) + 1
    
    if languages:
        print()
        print("Language breakdown:")
        for lang, count in sorted(languages.items(), key=lambda x: x[1], reverse=True):
            print(f"  {lang:15s}: {count:4d} scripts")
    
    return 0


if __name__ == '__main__':
    exit(main())