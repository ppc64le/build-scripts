#!/usr/bin/env python3
"""
split_by_language.py - Split enriched CSV into per-language files

Usage:
    python split_by_language.py input.csv output_dir/
    python split_by_language.py  # Uses defaults

Defaults:
    input:  output.feb2/build_scripts_enriched.csv
    output: output.feb2/by_language/
"""

import csv
import sys
from collections import defaultdict
from pathlib import Path


def split_by_language(input_csv: Path, output_dir: Path) -> dict:
    """Split a CSV file by language column into separate files."""

    output_dir.mkdir(parents=True, exist_ok=True)

    # Read input CSV
    with open(input_csv, 'r', newline='', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        fieldnames = reader.fieldnames
        by_lang = defaultdict(list)
        for row in reader:
            lang = row.get('language', 'unknown').lower() or 'unknown'
            by_lang[lang].append(row)

    # Write per-language files
    counts = {}
    for lang, rows in sorted(by_lang.items()):
        filename = output_dir / f'{lang}.csv'
        with open(filename, 'w', newline='', encoding='utf-8') as f:
            writer = csv.DictWriter(f, fieldnames=fieldnames)
            writer.writeheader()
            writer.writerows(rows)
        counts[lang] = len(rows)
        print(f'{lang}: {len(rows)} packages -> {filename}')

    return counts


def main():
    # Determine paths
    script_dir = Path(__file__).parent.resolve()
    root_dir = script_dir.parent

    if len(sys.argv) >= 3:
        input_csv = Path(sys.argv[1])
        output_dir = Path(sys.argv[2])
    elif len(sys.argv) == 2:
        input_csv = Path(sys.argv[1])
        output_dir = input_csv.parent / 'by_language'
    else:
        # Defaults
        input_csv = root_dir / 'output.feb2' / 'build_scripts_enriched.csv'
        output_dir = root_dir / 'output.feb2' / 'by_language'

    if not input_csv.exists():
        print(f"Error: Input file not found: {input_csv}", file=sys.stderr)
        print(f"Usage: {sys.argv[0]} input.csv [output_dir/]", file=sys.stderr)
        sys.exit(1)

    print(f"Input:  {input_csv}")
    print(f"Output: {output_dir}/")
    print()

    counts = split_by_language(input_csv, output_dir)

    print()
    print(f"Total: {sum(counts.values())} packages across {len(counts)} languages")


if __name__ == '__main__':
    main()
