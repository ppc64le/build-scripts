#!/usr/bin/env python3
"""
analyze_migration_candidates.py - Analyze repository for migration candidates

This tool scans the build-scripts repository to identify scripts that need
to be migrated to the new template format.

Usage:
    ./analyze_migration_candidates.py [OPTIONS]

Options:
    -b, --base <dir>      Build-scripts directory to analyze (required or use default)
    -o, --output <dir>    Output directory for reports (default: ./migration_analysis)
    -l, --language <lang> Filter by language (python, node, go, java, ruby, php, r, conda)
    -s, --status <status> Filter by status (pending, migrated, unknown)
    -c, --csv             Output in CSV format
    --priority            Sort by migration priority
    -h, --help            Show this help

Output:
    - migration_candidates.txt   List of scripts to migrate
    - migration_summary.md       Summary report with statistics
    - priority_list.txt          Prioritized migration order

All paths in output are relative to the base directory.
"""

import argparse
import csv
import re
import sys
from collections import defaultdict
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Optional


# =============================================================================
# CONFIGURATION
# =============================================================================

# Confidence threshold: below this, we cross-check with heuristics
CONFIDENCE_THRESHOLD_LOW = 30.0
CONFIDENCE_THRESHOLD_HIGH = 60.0

# Language normalization map
LANGUAGE_ALIASES = {
    "go": "go",
    "golang": "go",
    "python": "python",
    "py": "python",
    "node": "node",
    "nodejs": "node",
    "javascript": "node",
    "typescript": "node",
    "js": "node",
    "ts": "node",
    "java": "java",
    "ruby": "ruby",
    "rb": "ruby",
    "php": "php",
    "r": "r",
    "conda": "conda",
    "anaconda": "conda",
}


# =============================================================================
# DATA CLASSES
# =============================================================================

@dataclass
class LanguageCSVEntry:
    """Entry from pkg-lang.csv"""
    package_name: str
    script_path: str
    language: str
    template: str
    confidence_score: float
    confidence_label: str


@dataclass
class ScriptInfo:
    """Analysis results for a single script"""
    path: Path
    relative_path: str
    language: str
    language_source: str  # "header", "csv_high", "csv_confirmed", "csv_low", "heuristic"
    status: str
    complexity: str
    tested_on: str
    package_name: str
    priority: int


# =============================================================================
# LANGUAGE CSV LOADING
# =============================================================================

class LanguageLookup:
    """Handles loading and querying the pkg-lang.csv file"""

    def __init__(self, csv_path: Optional[Path] = None):
        self.entries: dict[str, LanguageCSVEntry] = {}
        self.loaded = False

        if csv_path and csv_path.exists():
            self._load(csv_path)

    def _load(self, csv_path: Path) -> None:
        """Load the CSV file into memory"""
        try:
            with open(csv_path, "r", newline="", encoding="utf-8") as f:
                reader = csv.reader(f)
                for row in reader:
                    if len(row) < 6:
                        continue

                    entry = LanguageCSVEntry(
                        package_name=row[0],
                        script_path=row[1],
                        language=row[2].lower(),
                        template=row[3],
                        confidence_score=float(row[4]) if row[4] else 0.0,
                        confidence_label=row[5],
                    )

                    # Normalize path: remove "build-scripts/" prefix
                    normalized_path = entry.script_path
                    if normalized_path.startswith("build-scripts/"):
                        normalized_path = normalized_path[len("build-scripts/"):]

                    self.entries[normalized_path] = entry

            self.loaded = True
            print(f"\033[0;34mLoaded language data for {len(self.entries)} scripts from CSV\033[0m",
                  file=sys.stderr)

        except Exception as e:
            print(f"\033[1;33mWarning: Failed to load CSV: {e}\033[0m", file=sys.stderr)

    def lookup(self, relative_path: str) -> Optional[LanguageCSVEntry]:
        """Look up a script by its relative path"""
        return self.entries.get(relative_path)


# =============================================================================
# LANGUAGE DETECTION
# =============================================================================

class LanguageDetector:
    """Detects the programming language a build script is for"""

    # Patterns for heuristic detection (order matters - checked sequentially)
    HEURISTIC_PATTERNS = [
        ("python", [
            r"pip install",
            r"python3 -m",
            r"pytest",
            r"\.py\b",
            r"setup\.py",
            r"pyproject\.toml",
            r"requirements\.txt",
        ]),
        ("node", [
            r"npm install",
            r"nvm ",
            r"node ",
            r"yarn ",
            r"package\.json",
            r"\.js\b",
            r"\.ts\b",
            r"typescript",
        ]),
        ("go", [
            r"go build",
            r"go test",
            r"go mod",
            r"GOROOT",
            r"GOPATH",
            r"\.go\b",
        ]),
        ("java", [
            r"mvn ",
            r"maven",
            r"gradle",
            r"JAVA_HOME",
            r"\.jar\b",
            r"pom\.xml",
        ]),
        ("ruby", [
            r"bundle ",
            r"gem ",
            r"rbenv",
            r"Gemfile",
            r"\.rb\b",
        ]),
        ("php", [
            r"composer",
            r"php ",
            r"\.php\b",
        ]),
        ("r", [
            r"R CMD",
            r"R-core",
            r"Rscript",
            r"\.R\b",
        ]),
        ("conda", [
            r"conda ",
            r"miniconda",
            r"anaconda",
        ]),
    ]

    def __init__(self, csv_lookup: LanguageLookup):
        self.csv_lookup = csv_lookup
        # Compile regex patterns for efficiency
        self.compiled_patterns = [
            (lang, [re.compile(p, re.IGNORECASE) for p in patterns])
            for lang, patterns in self.HEURISTIC_PATTERNS
        ]

    def detect(self, script_path: Path, relative_path: str) -> tuple[str, str]:
        """
        Detect language for a script.

        Returns: (language, source) where source indicates how we determined it:
            - "header": Found # Language: X comment in script
            - "csv_high": CSV lookup with high confidence
            - "csv_confirmed": CSV lookup confirmed by heuristics
            - "csv_override": Heuristics disagreed with low-confidence CSV, using heuristics
            - "heuristic": Determined by heuristics alone
            - "unknown": Could not determine
        """
        try:
            content = script_path.read_text(encoding="utf-8", errors="replace")
        except Exception:
            return "unknown", "error"

        # 1. Check for explicit header comment (highest priority)
        header_lang = self._detect_from_header(content)
        if header_lang:
            return header_lang, "header"

        # 2. Check CSV lookup
        csv_entry = self.csv_lookup.lookup(relative_path)

        # 3. Run heuristics
        heuristic_lang = self._detect_from_heuristics(content, script_path)

        # 4. Decision logic based on CSV confidence and heuristic agreement
        if csv_entry:
            csv_lang = self._normalize_language(csv_entry.language)
            confidence = csv_entry.confidence_score

            if confidence >= CONFIDENCE_THRESHOLD_HIGH:
                # High confidence: trust CSV
                return csv_lang, "csv_high"

            elif confidence >= CONFIDENCE_THRESHOLD_LOW:
                # Moderate confidence: prefer CSV but note if heuristics agree
                if heuristic_lang and heuristic_lang == csv_lang:
                    return csv_lang, "csv_confirmed"
                else:
                    # CSV moderate confidence, heuristics disagree or unknown
                    return csv_lang, "csv_moderate"

            else:
                # Low confidence: cross-check with heuristics
                if heuristic_lang:
                    if heuristic_lang == csv_lang:
                        return csv_lang, "csv_confirmed"
                    else:
                        # Heuristics disagree - prefer heuristics for low-confidence CSV
                        return heuristic_lang, "csv_override"
                else:
                    # No heuristic match, use CSV even with low confidence
                    return csv_lang, "csv_low"

        # 5. No CSV entry - use heuristics
        if heuristic_lang:
            return heuristic_lang, "heuristic"

        return "unknown", "unknown"

    def _detect_from_header(self, content: str) -> Optional[str]:
        """Look for # Language: X comment in script header"""
        # Check first 50 lines for header comment
        lines = content.split("\n")[:50]
        for line in lines:
            # Match patterns like "# Language: Python" or "#  Language:  node"
            match = re.match(r"^#\s*Language\s*:\s*(\w+)", line, re.IGNORECASE)
            if match:
                return self._normalize_language(match.group(1))
        return None

    def _detect_from_heuristics(self, content: str, script_path: Path) -> Optional[str]:
        """Apply pattern-based heuristics to detect language"""

        # Special case: check if filename/path contains "js" patterns suggesting Node
        path_str = str(script_path).lower()
        if any(p in path_str for p in ["-js/", "_js/", "-js_", "_js_", "/js-", "/js_"]):
            return "node"

        # Check content against patterns
        for lang, patterns in self.compiled_patterns:
            for pattern in patterns:
                if pattern.search(content):
                    return lang

        return None

    def _normalize_language(self, lang: str) -> str:
        """Normalize language name to canonical form"""
        lang_lower = lang.lower().strip()
        return LANGUAGE_ALIASES.get(lang_lower, lang_lower)


# =============================================================================
# STATUS AND COMPLEXITY DETECTION
# =============================================================================

def detect_status(content: str) -> str:
    """Detect migration status of a script"""
    if re.search(r"source.*lib/common\.sh", content):
        return "migrated"
    elif re.search(r"^PACKAGE_NAME=", content, re.MULTILINE):
        return "pending"
    return "unknown"


def detect_complexity(content: str) -> str:
    """Estimate migration complexity based on script characteristics"""
    complexity = 0

    # Check for patches
    if re.search(r"patch |\.patch|git apply", content):
        complexity += 2

    # Check for workarounds/sed manipulation
    if re.search(r"sed -i|awk.*>", content):
        complexity += 1

    # Check for custom build systems
    if re.search(r"cmake|meson|cargo|rustc", content):
        complexity += 2

    # Check for heavy environment manipulation
    export_count = len(re.findall(r"^export ", content, re.MULTILINE))
    if export_count > 5:
        complexity += 1

    # Check script length
    line_count = content.count("\n")
    if line_count > 200:
        complexity += 1

    if complexity >= 4:
        return "high"
    elif complexity >= 2:
        return "medium"
    return "low"


def get_tested_on(content: str) -> str:
    """Extract 'Tested on' from script header"""
    match = re.search(r"^#.*Tested on\s*:\s*(.+)$", content, re.MULTILINE | re.IGNORECASE)
    if match:
        return match.group(1).strip()
    return "unknown"


def get_package_name(content: str) -> str:
    """Extract PACKAGE_NAME variable from script"""
    match = re.search(r'^PACKAGE_NAME=["\'"]?([^"\'"\n]+)["\'"]?', content, re.MULTILINE)
    if match:
        return match.group(1).strip()
    return ""


# =============================================================================
# SCRIPT ANALYSIS
# =============================================================================

def is_shell_script(path: Path) -> bool:
    """Check if file appears to be a shell script"""
    try:
        with open(path, "r", encoding="utf-8", errors="replace") as f:
            first_line = f.readline()
        # Accept shebang or comment header
        return first_line.startswith("#")
    except Exception:
        return False


def calculate_priority(status: str, complexity: str, language: str, tested_on: str) -> int:
    """Calculate migration priority score (lower = higher priority)"""
    priority = 50

    # Status-based priority
    if status == "pending":
        priority -= 20
    elif status == "unknown":
        priority -= 10

    # Complexity-based priority
    if complexity == "low":
        priority -= 10
    elif complexity == "medium":
        priority -= 5

    # Language-based priority (common languages first)
    if language == "python":
        priority -= 5
    elif language == "node":
        priority -= 3

    # Newer UBI versions get higher priority
    if "9." in tested_on:
        priority -= 5

    return priority


def analyze_script(
    script_path: Path,
    base_dir: Path,
    detector: LanguageDetector,
) -> Optional[ScriptInfo]:
    """Analyze a single script and return its info"""

    if not is_shell_script(script_path):
        return None

    try:
        content = script_path.read_text(encoding="utf-8", errors="replace")
    except Exception:
        return None

    relative_path = str(script_path.relative_to(base_dir))
    language, lang_source = detector.detect(script_path, relative_path)
    status = detect_status(content)
    complexity = detect_complexity(content)
    tested_on = get_tested_on(content)
    package_name = get_package_name(content)
    priority = calculate_priority(status, complexity, language, tested_on)

    return ScriptInfo(
        path=script_path,
        relative_path=relative_path,
        language=language,
        language_source=lang_source,
        status=status,
        complexity=complexity,
        tested_on=tested_on,
        package_name=package_name,
        priority=priority,
    )


# =============================================================================
# OUTPUT GENERATION
# =============================================================================

def write_candidates_file(
    scripts: list[ScriptInfo],
    output_path: Path,
    csv_format: bool,
) -> None:
    """Write the migration candidates file"""

    with open(output_path, "w", encoding="utf-8") as f:
        if csv_format:
            writer = csv.writer(f)
            writer.writerow(["path", "language", "lang_source", "status", "complexity",
                           "tested_on", "package_name", "priority"])
            for s in scripts:
                writer.writerow([
                    s.relative_path, s.language, s.language_source, s.status,
                    s.complexity, s.tested_on, s.package_name, s.priority
                ])
        else:
            # Table format
            header = f"{'Script':<60} | {'Language':<8} | {'Source':<12} | {'Status':<8} | {'Cmplx':<6} | {'Tested On':<15} | Priority"
            f.write(header + "\n")
            f.write("-" * 130 + "\n")
            for s in scripts:
                line = f"{s.relative_path:<60} | {s.language:<8} | {s.language_source:<12} | {s.status:<8} | {s.complexity:<6} | {s.tested_on[:15]:<15} | {s.priority}"
                f.write(line + "\n")


def write_priority_file(scripts: list[ScriptInfo], output_path: Path) -> None:
    """Write priority-sorted list"""
    sorted_scripts = sorted(scripts, key=lambda s: s.priority)
    with open(output_path, "w", encoding="utf-8") as f:
        for s in sorted_scripts:
            f.write(f"{s.priority:3d} | {s.relative_path}\n")


def write_summary_file(
    scripts: list[ScriptInfo],
    output_path: Path,
    base_dir: Path,
) -> None:
    """Write the markdown summary report"""

    total = len(scripts)
    lang_counts: dict[str, int] = defaultdict(int)
    status_counts: dict[str, int] = defaultdict(int)
    source_counts: dict[str, int] = defaultdict(int)

    for s in scripts:
        lang_counts[s.language] += 1
        status_counts[s.status] += 1
        source_counts[s.language_source] += 1

    with open(output_path, "w", encoding="utf-8") as f:
        f.write("# Migration Analysis Summary\n\n")
        f.write(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
        f.write(f"Base Directory: {base_dir}\n\n")

        f.write("## Overview\n\n")
        f.write("| Metric | Count |\n")
        f.write("|--------|-------|\n")
        f.write(f"| Total Scripts Analyzed | {total} |\n\n")

        f.write("## By Language\n\n")
        f.write("| Language | Count | Percentage |\n")
        f.write("|----------|-------|------------|\n")
        for lang, count in sorted(lang_counts.items(), key=lambda x: -x[1]):
            pct = count * 100 // total if total > 0 else 0
            f.write(f"| {lang} | {count} | {pct}% |\n")

        f.write("\n## By Detection Source\n\n")
        f.write("| Source | Count | Description |\n")
        f.write("|--------|-------|-------------|\n")
        source_descriptions = {
            "header": "Found # Language: comment",
            "csv_high": "CSV with high confidence (>=60)",
            "csv_moderate": "CSV with moderate confidence (30-60)",
            "csv_confirmed": "CSV confirmed by heuristics",
            "csv_low": "CSV with low confidence, no heuristic match",
            "csv_override": "Heuristics overrode low-confidence CSV",
            "heuristic": "Heuristics only (no CSV entry)",
            "unknown": "Could not determine",
        }
        for source, count in sorted(source_counts.items(), key=lambda x: -x[1]):
            desc = source_descriptions.get(source, "")
            f.write(f"| {source} | {count} | {desc} |\n")

        f.write("\n## By Status\n\n")
        f.write("| Status | Count | Percentage |\n")
        f.write("|--------|-------|------------|\n")
        for status, count in sorted(status_counts.items(), key=lambda x: -x[1]):
            pct = count * 100 // total if total > 0 else 0
            f.write(f"| {status} | {count} | {pct}% |\n")

        f.write("""
## Recommendations

### High Priority (Migrate First)
1. Scripts with status "pending" and complexity "low"
2. Python and Node.js scripts (most common)
3. Scripts already on UBI 9.x

### Medium Priority
1. Scripts with complexity "medium"
2. Go and Java scripts
3. Scripts on UBI 8.x (need platform upgrade too)

### Low Priority
1. Scripts with complexity "high" (need manual review)
2. Scripts with unknown language
3. Already migrated scripts (verify only)

## Next Steps

1. Run migration tool on high-priority scripts:
   ```bash
   ./migrate_to_template.sh -o ./migrated --batch high_priority.txt
   ```

2. Review migrated scripts
3. Test in development environment
4. Deploy to production

## Files Generated

- `migration_candidates.txt` - All analyzed scripts
- `priority_list.txt` - Sorted by migration priority
- `migration_summary.md` - This summary report
""")


# =============================================================================
# MAIN
# =============================================================================

def main() -> int:
    parser = argparse.ArgumentParser(
        description="Analyze repository for scripts that need migration to new template format.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "-b", "--base",
        type=Path,
        help="Build-scripts directory to analyze (default: parent of script dir)",
    )
    parser.add_argument(
        "-o", "--output",
        type=Path,
        default=Path("./migration_analysis"),
        help="Output directory (default: ./migration_analysis)",
    )
    parser.add_argument(
        "-l", "--language",
        help="Filter by language",
    )
    parser.add_argument(
        "-s", "--status",
        choices=["pending", "migrated", "unknown"],
        help="Filter by status",
    )
    parser.add_argument(
        "-c", "--csv",
        action="store_true",
        help="Output in CSV format",
    )
    parser.add_argument(
        "--priority",
        action="store_true",
        help="Sort by migration priority",
    )

    args = parser.parse_args()

    # Resolve base directory
    script_dir = Path(__file__).parent.resolve()
    if args.base:
        base_dir = args.base.resolve()
    else:
        base_dir = script_dir.parent

    if not base_dir.is_dir():
        print(f"\033[0;31mError: Directory not found: {base_dir}\033[0m", file=sys.stderr)
        return 1

    # Create output directory
    args.output.mkdir(parents=True, exist_ok=True)

    # Load language CSV
    csv_path = script_dir / "pkg-lang.csv"
    lang_lookup = LanguageLookup(csv_path)
    detector = LanguageDetector(lang_lookup)

    print(f"\033[0;34mAnalyzing build scripts in: {base_dir}\033[0m")
    print()

    # Find and analyze scripts
    scripts: list[ScriptInfo] = []

    for script_path in sorted(base_dir.rglob("*.sh")):
        # Skip template directories
        rel_path = str(script_path.relative_to(base_dir))
        if "/templates/" in rel_path or "/template-tools/" in rel_path:
            continue

        info = analyze_script(script_path, base_dir, detector)
        if info is None:
            continue

        # Apply filters
        if args.language and info.language != args.language.lower():
            continue
        if args.status and info.status != args.status:
            continue

        scripts.append(info)

        # Print progress
        print(f"{info.relative_path:<60} | {info.language:<8} | {info.language_source:<12} | {info.status:<8}")

    # Sort by priority if requested
    if args.priority:
        scripts.sort(key=lambda s: s.priority)

    # Write output files
    candidates_file = args.output / "migration_candidates.txt"
    write_candidates_file(scripts, candidates_file, args.csv)

    if args.priority:
        priority_file = args.output / "priority_list.txt"
        write_priority_file(scripts, priority_file)
        print(f"\nPriority list saved to: {priority_file}")

    summary_file = args.output / "migration_summary.md"
    write_summary_file(scripts, summary_file, base_dir)

    print()
    print(f"\033[0;32m=== Analysis Complete ===\033[0m")
    print(f"Base directory: {base_dir}")
    print(f"Total scripts: {len(scripts)}")
    print(f"Output directory: {args.output}")
    print(f"\033[0;32mSummary saved to: {summary_file}\033[0m")

    return 0


if __name__ == "__main__":
    sys.exit(main())
