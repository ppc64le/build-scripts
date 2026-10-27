#!/usr/bin/env python3
"""
filter_candidates.py - Filter and reformat migration candidates

Filters migration_candidates.txt by language, distro, and release version,
then outputs a sorted CSV for further processing.

Usage:
    ./filter_candidates [OPTIONS]

Options:
    -l, --language <lang>   Filter by language (python, node, go, java, etc.)
    -d, --distro <distro>   Filter by distro (rhel, ubi, ubuntu, debian, sles, centos, fedora)
    -r, --release <ver>     Filter by release version (7.3, 8, 8.3, 9.3, 9.5, 9.6, 20.04, etc.)
    -i, --input <file>      Input candidates file (default: ./migration_analysis/migration_candidates.txt)
    -o, --output <file>     Output CSV file (default: stdout)
    -h, --help              Show this help

Output CSV Columns:
    1. package_name     - GitHub package name (directory without first letter prefix)
    2. package_version  - (reserved, empty)
    3. language         - Detected language
    4. language_version - (reserved, empty)
    5. script_path      - Full relative path to script (e.g., p/python-fire/script.sh)
    6. package_url      - (reserved, empty)
    7. download_url     - (reserved, empty)
    8. status           - Migration status
    9. complexity       - Migration complexity
   10. priority         - Priority score (lower = higher priority)

Examples:
    ./filter_candidates -l python -d ubi -r 9
    ./filter_candidates -d rhel -r 8 -o rhel8_scripts.csv
    ./filter_candidates -l go --distro ubuntu --release 20.04
"""

import argparse
import csv
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Optional, TextIO


# =============================================================================
# DATA STRUCTURES
# =============================================================================

@dataclass
class CandidateRecord:
    """A migration candidate record"""
    path: str
    language: str
    lang_source: str  # May be empty for old format
    status: str
    complexity: str
    tested_on: str
    package_name: str
    priority: int


@dataclass
class OutputRecord:
    """Output CSV record format"""
    package_name: str
    package_version: str  # Reserved, empty
    language: str
    language_version: str  # Reserved, empty
    script_path: str  # Full relative path (e.g., p/python-fire/script.sh)
    package_url: str  # Reserved, empty
    download_url: str  # Reserved, empty
    status: str
    complexity: str
    priority: int


# =============================================================================
# DISTRO NORMALIZATION
# =============================================================================

DISTRO_PATTERNS = {
    # Red Hat variants
    "rhel": r"RHEL|Red\s*Hat|rhel",
    "redhat": r"RHEL|Red\s*Hat|rhel",
    "rh": r"RHEL|Red\s*Hat|rhel",
    "ubi": r"UBI|ubi",
    "ubi9": r"UBI|ubi",
    "ubi8": r"UBI|ubi",
    "ubi7": r"UBI|ubi",
    "centos": r"CentOS|centos",
    "cos": r"CentOS|centos",
    "fedora": r"Fedora|fedora",
    "fc": r"Fedora|fedora",
    # Debian variants
    "ubuntu": r"Ubuntu|ubuntu",
    "ubu": r"Ubuntu|ubuntu",
    "debian": r"Debian|debian",
    "deb": r"Debian|debian",
    # SUSE variants
    "sles": r"SLES|SUSE|openSUSE|sles|suse",
    "suse": r"SLES|SUSE|openSUSE|sles|suse",
    "opensuse": r"SLES|SUSE|openSUSE|sles|suse",
}


def normalize_distro(distro: str) -> str:
    """Convert distro alias to regex pattern"""
    distro_lower = distro.lower().strip()
    return DISTRO_PATTERNS.get(distro_lower, re.escape(distro))


def match_distro(tested_on: str, distro_filter: str) -> bool:
    """Check if tested_on matches the distro filter"""
    pattern = normalize_distro(distro_filter)
    return bool(re.search(pattern, tested_on, re.IGNORECASE))


# =============================================================================
# RELEASE VERSION MATCHING
# =============================================================================

def match_release(tested_on: str, release_filter: str) -> bool:
    """
    Flexible release matching:
    - "9" matches 9, 9.x, 9.x.x
    - "9.5" matches exactly 9.5
    """
    if not release_filter:
        return True

    # For single digit (e.g., "9"), match 9, 9.x, 9.x.x
    if re.match(r"^\d+$", release_filter):
        pattern = rf"(?<!\d){release_filter}(?:\.\d+)*(?!\d)"
    else:
        # For specific version (e.g., "9.5"), match exactly
        escaped = re.escape(release_filter)
        pattern = rf"(?<!\d){escaped}(?!\d)"

    return bool(re.search(pattern, tested_on))


# =============================================================================
# PATH EXTRACTION
# =============================================================================

def extract_package_name(path: str) -> str:
    """
    Extract package name from path.
    Path format: a/package-name/script.sh or /path/to/build-scripts/p/package-name/script.sh
    Extracts: package-name (the directory, handling first letter prefix)
    """
    path_obj = Path(path)

    # Get the parent directory (containing the script)
    pkg_dir = path_obj.parent.name

    # Check if grandparent is a single letter (first-letter prefix)
    grandparent = path_obj.parent.parent.name if path_obj.parent.parent else ""

    if len(grandparent) == 1 and grandparent.isalpha():
        # Standard layout: a/package-name/script.sh
        return pkg_dir
    else:
        # Non-standard layout or nested (e.g., Dockerfiles/redhat_ubi8/build.sh)
        # Walk up to find a meaningful package name
        parts = path_obj.parts
        for i, part in enumerate(parts):
            if len(part) == 1 and part.isalpha() and i + 1 < len(parts):
                return parts[i + 1]
        return pkg_dir


# =============================================================================
# INPUT PARSING
# =============================================================================

def detect_format(first_line: str) -> str:
    """Detect input format: 'csv' or 'table'"""
    if first_line.startswith('"path"') or first_line.startswith('path,'):
        return "csv"
    return "table"


def parse_csv_line(row: list[str]) -> Optional[CandidateRecord]:
    """Parse a CSV row into a CandidateRecord"""
    # Handle both old format (7 cols) and new format (8 cols with lang_source)
    if len(row) < 7:
        return None

    # New format: path,language,lang_source,status,complexity,tested_on,package_name,priority
    # Old format: path,language,status,complexity,tested_on,package_name,priority
    if len(row) >= 8:
        return CandidateRecord(
            path=row[0],
            language=row[1],
            lang_source=row[2],
            status=row[3],
            complexity=row[4],
            tested_on=row[5],
            package_name=row[6],
            priority=int(row[7]) if row[7].strip().lstrip('-').isdigit() else 0,
        )
    else:
        return CandidateRecord(
            path=row[0],
            language=row[1],
            lang_source="",
            status=row[2],
            complexity=row[3],
            tested_on=row[4],
            package_name=row[5],
            priority=int(row[6]) if row[6].strip().lstrip('-').isdigit() else 0,
        )


def parse_table_line(line: str) -> Optional[CandidateRecord]:
    """Parse a pipe-delimited table line into a CandidateRecord"""
    # Skip header and separator lines
    if line.startswith("Script") or line.startswith("-") or not line.strip():
        return None

    parts = [p.strip() for p in line.split("|")]
    if len(parts) < 6:
        return None

    # Table format: Script | Language | Source | Status | Cmplx | Tested On | Priority
    # Or old format: Script | Language | Status | Cmplx | Tested On | Priority
    if len(parts) >= 7:
        return CandidateRecord(
            path=parts[0],
            language=parts[1],
            lang_source=parts[2],
            status=parts[3],
            complexity=parts[4],
            tested_on=parts[5],
            package_name="",
            priority=int(parts[6]) if parts[6].strip().lstrip('-').isdigit() else 0,
        )
    else:
        return CandidateRecord(
            path=parts[0],
            language=parts[1],
            lang_source="",
            status=parts[2],
            complexity=parts[3],
            tested_on=parts[4],
            package_name="",
            priority=int(parts[5]) if parts[5].strip().lstrip('-').isdigit() else 0,
        )


def read_candidates(input_file: Path) -> list[CandidateRecord]:
    """Read and parse the candidates file"""
    records = []

    with open(input_file, "r", encoding="utf-8") as f:
        first_line = f.readline()
        f.seek(0)

        fmt = detect_format(first_line)

        if fmt == "csv":
            reader = csv.reader(f)
            header = next(reader, None)  # Skip header
            for row in reader:
                record = parse_csv_line(row)
                if record:
                    records.append(record)
        else:
            for line in f:
                record = parse_table_line(line)
                if record:
                    records.append(record)

    return records


# =============================================================================
# FILTERING
# =============================================================================

def filter_candidates(
    records: list[CandidateRecord],
    language: Optional[str] = None,
    distro: Optional[str] = None,
    release: Optional[str] = None,
) -> list[CandidateRecord]:
    """Apply filters to candidate records"""
    filtered = []

    for record in records:
        # Language filter
        if language:
            lang_lower = record.language.lower()
            filter_lower = language.lower()
            # Handle comma-separated languages
            if filter_lower not in lang_lower:
                continue

        # Distro filter
        if distro:
            if not match_distro(record.tested_on, distro):
                continue

        # Release filter
        if release:
            if not match_release(record.tested_on, release):
                continue

        filtered.append(record)

    return filtered


# =============================================================================
# OUTPUT
# =============================================================================

def convert_to_output(record: CandidateRecord) -> OutputRecord:
    """Convert a CandidateRecord to OutputRecord format"""
    # Extract package name from path if not already set
    pkg_name = extract_package_name(record.path)
    if not pkg_name and record.package_name:
        pkg_name = record.package_name

    return OutputRecord(
        package_name=pkg_name,
        package_version="",
        language=record.language,
        language_version="",
        script_path=record.path,  # Full relative path
        package_url="",
        download_url="",
        status=record.status,
        complexity=record.complexity,
        priority=record.priority,
    )


def write_output(
    records: list[CandidateRecord],
    output: TextIO,
) -> int:
    """Write filtered records as CSV, sorted by priority"""
    # Sort by priority before conversion (lower = higher priority)
    sorted_records = sorted(records, key=lambda r: r.priority)

    # Convert to output format
    output_records = [convert_to_output(r) for r in sorted_records]

    # Write CSV
    writer = csv.writer(output)
    writer.writerow([
        "package_name", "package_version", "language", "language_version",
        "script_path", "package_url", "download_url", "status", "complexity", "priority"
    ])

    for rec in output_records:
        writer.writerow([
            rec.package_name,
            rec.package_version,
            rec.language,
            rec.language_version,
            rec.script_path,
            rec.package_url,
            rec.download_url,
            rec.status,
            rec.complexity,
            rec.priority,
        ])

    return len(output_records)


# =============================================================================
# MAIN
# =============================================================================

def main() -> int:
    parser = argparse.ArgumentParser(
        description="Filter migration candidates by language, distro, and release.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Output CSV columns:
  package_name, package_version, language, language_version, script_path, package_url, download_url, status, complexity, priority

Examples:
  ./filter_candidates -l python -d ubi -r 9
  ./filter_candidates -d rhel -r 8.3 -o rhel8_scripts.csv
  ./filter_candidates -l go --distro ubuntu --release 20.04
""",
    )
    parser.add_argument(
        "-l", "--language",
        help="Filter by language (python, node, go, java, ruby, php, r)",
    )
    parser.add_argument(
        "-d", "--distro",
        help="Filter by distro (rhel, ubi, ubuntu, debian, sles, centos, fedora)",
    )
    parser.add_argument(
        "-r", "--release",
        help="Filter by release version (7, 8, 9, 9.3, 9.5, 20.04, etc.)",
    )
    parser.add_argument(
        "-i", "--input",
        type=Path,
        help="Input candidates file (default: ./migration_analysis/migration_candidates.txt)",
    )
    parser.add_argument(
        "-o", "--output",
        type=Path,
        help="Output CSV file (default: stdout)",
    )

    args = parser.parse_args()

    # Determine input file
    script_dir = Path(__file__).parent.resolve()
    if args.input:
        input_file = args.input
    else:
        input_file = script_dir / "migration_analysis" / "migration_candidates.txt"

    if not input_file.exists():
        print(f"Error: Input file not found: {input_file}", file=sys.stderr)
        print("Run analyze_migration_candidates first to generate it.", file=sys.stderr)
        return 1

    # Read and filter
    records = read_candidates(input_file)
    filtered = filter_candidates(
        records,
        language=args.language,
        distro=args.distro,
        release=args.release,
    )

    # Write output
    if args.output:
        with open(args.output, "w", encoding="utf-8", newline="") as f:
            count = write_output(filtered, f)
        print(f"Wrote {count} records to: {args.output}", file=sys.stderr)
    else:
        write_output(filtered, sys.stdout)

    return 0


if __name__ == "__main__":
    # Handle broken pipe gracefully (e.g., when piped to head)
    import signal
    signal.signal(signal.SIGPIPE, signal.SIG_DFL)
    sys.exit(main())
