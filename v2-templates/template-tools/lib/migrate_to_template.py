#!/usr/bin/env python3
"""
migrate_to_template.py - Migrate existing build scripts to new template format

This tool converts old-style build scripts (copied/modified templates) to the
new V2 format where scripts invoke standardized templates via source.

Usage:
    ./migrate_to_template <script_path>                    # Migrate single script
    ./migrate_to_template <directory>                      # Migrate all scripts in dir
    ./migrate_to_template --scan <directory>               # Scan without migrating
    ./migrate_to_template -b <old_scripts> --batch <list>  # Batch migrate from list

Options:
    -b, --base <dir>         Old build-scripts source tree (required for --batch)
    -d, --dest <dir>         Destination for generated scripts (default: ./migrated_scripts)
    --template-dir <dir>     V2 templates location (default: ../templates/ relative to tool)
    --batch <file>           Batch file (.csv or .list) with scripts to migrate
    -l, --language <lang>    Override language detection
    -r, --report             Generate migration report
    -n, --dry-run            Show what would be done without making changes
    -f, --force              Overwrite existing migrated scripts
    -v, --verbose            Verbose output
    --scan                   Scan and report only, don't migrate

Examples:
    ./migrate_to_template ../p/python-fire/python_fire_ubi_9.3.sh
    ./migrate_to_template -b ~/src/build-scripts --batch pkg-lang.csv -d ./migrated
    ./migrate_to_template -b ~/src/build-scripts --batch pkg-lang.list -d ./migrated
    ./migrate_to_template --scan ../
"""

import argparse
import json
import re
import shutil
import sys
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from typing import Optional, TYPE_CHECKING

if TYPE_CHECKING:
    from .version_matcher import VersionMatcher


# =============================================================================
# CONFIGURATION
# =============================================================================

# Template mapping by language
LANGUAGE_TEMPLATES = {
    "python": "python.sh",
    "node": "node.sh",
    "nodejs": "node.sh",
    "javascript": "node.sh",
    "typescript": "node.sh",
    "js": "node.sh",
    "ts": "node.sh",
    "go": "go.sh",
    "golang": "go.sh",
    "java": "java.sh",
    "ruby": "ruby.sh",
    "php": "php.sh",
    "r": "r.sh",
    "conda": "conda.sh",
}

# Display names for languages
LANGUAGE_DISPLAY_NAMES = {
    "python": "Python",
    "py": "Python",
    "node": "Node",
    "nodejs": "Node",
    "javascript": "Node",
    "typescript": "Node",
    "js": "Node",
    "ts": "Node",
    "go": "Go",
    "golang": "Go",
    "java": "Java",
    "ruby": "Ruby",
    "rb": "Ruby",
    "php": "PHP",
    "r": "R",
    "conda": "Conda",
    "anaconda": "Conda",
}

# =============================================================================
# DATA CLASSES
# =============================================================================

@dataclass
class ScriptMetadata:
    """Metadata extracted from a build script"""
    package_name: str = ""
    package_version: str = ""
    package_url: str = ""
    maintainer: str = ""
    tested_on: str = ""
    version_unconfirmed: bool = False  # True if version couldn't be matched to registry
    version_source: str = ""  # e.g., "npm_versions.json" if version was corrected
    version_substituted: bool = False  # True if version was substituted (original too old)
    version_original: str = ""  # Original version before substitution
    available_tags: str = ""  # PACKAGE_AVAILABLE_TAGS line for build script


@dataclass
class PackageDependencies:
    """Package dependencies by distro family"""
    rh_packages: list[str] = field(default_factory=list)
    deb_packages: list[str] = field(default_factory=list)
    sles_packages: list[str] = field(default_factory=list)
    detected_distro: str = ""  # "rhel", "debian", "sles", or ""


@dataclass
class CustomLogic:
    """Custom logic extracted from script"""
    env_vars: list[str] = field(default_factory=list)
    pre_packages_commands: list[str] = field(default_factory=list)
    patch_commands: list[str] = field(default_factory=list)
    workaround_commands: list[str] = field(default_factory=list)
    custom_build_steps: list[str] = field(default_factory=list)
    custom_test_steps: list[str] = field(default_factory=list)
    has_patches: bool = False
    has_workarounds: bool = False
    has_pre_packages: bool = False
    # Lines from original that we're NOT confident about - for manual review
    unhandled_lines: list[str] = field(default_factory=list)


@dataclass
class ScriptAnalysis:
    """Complete analysis of a build script"""
    path: Path
    content: str
    language: str
    metadata: ScriptMetadata
    packages: PackageDependencies
    custom_logic: CustomLogic
    already_migrated: bool = False
    complexity: str = "simple"  # simple, complex, incomplete


# =============================================================================
# COLORS AND OUTPUT
# =============================================================================

class Colors:
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    BLUE = '\033[0;34m'
    NC = '\033[0m'


def log_info(msg: str) -> None:
    print(f"{Colors.BLUE}[INFO]{Colors.NC} {msg}")


def log_success(msg: str) -> None:
    print(f"{Colors.GREEN}[OK]{Colors.NC} {msg}")


def log_warn(msg: str) -> None:
    print(f"{Colors.YELLOW}[WARN]{Colors.NC} {msg}")


def log_error(msg: str) -> None:
    print(f"{Colors.RED}[ERROR]{Colors.NC} {msg}", file=sys.stderr)


# =============================================================================
# DISTRO DETECTION
# =============================================================================

def detect_distro_from_tested_on(tested_on: str) -> str:
    """Determine distro family from 'Tested on' header"""
    tested_lower = tested_on.lower()

    if any(x in tested_lower for x in ["ubi", "rhel", "red hat", "centos", "fedora", "rocky", "alma"]):
        return "rhel"
    elif any(x in tested_lower for x in ["ubuntu", "debian"]):
        return "debian"
    elif any(x in tested_lower for x in ["sles", "suse", "opensuse"]):
        return "sles"
    return ""


def detect_distro_from_content(content: str) -> str:
    """Determine distro family from package manager commands in script"""
    has_yum_dnf = bool(re.search(r'(yum|dnf)\s+install', content))
    has_apt = bool(re.search(r'apt-get\s+install', content))
    has_zypper = bool(re.search(r'zypper\s+install', content))

    # If only one package manager is used, that's our distro
    if has_yum_dnf and not has_apt and not has_zypper:
        return "rhel"
    elif has_apt and not has_yum_dnf and not has_zypper:
        return "debian"
    elif has_zypper and not has_yum_dnf and not has_apt:
        return "sles"

    # Multiple or none - can't determine
    return ""


# =============================================================================
# LANGUAGE DETECTION
# =============================================================================

# Pattern-based language detection (same as analyze script)
LANGUAGE_PATTERNS = [
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
        r"ant ",
    ]),
    ("ruby", [
        r"bundle ",
        r"gem ",
        r"rbenv",
        r"rvm ",
        r"Gemfile",
        r"\.rb\b",
        r"rake",
    ]),
    ("php", [
        r"composer",
        r"php ",
        r"phpunit",
        r"\.php\b",
    ]),
    ("r", [
        r"R CMD",
        r"install\.packages",
        r"r-base",
        r"R-core",
    ]),
    ("conda", [
        r"conda ",
        r"miniconda",
        r"feedstock",
    ]),
]


def detect_language(content: str, override: Optional[str] = None) -> str:
    """Detect the programming language the build script is for"""
    if override:
        return override.lower()

    # Check for Language: header comment
    match = re.search(r"^#\s*Language\s*:\s*(\w+)", content, re.MULTILINE | re.IGNORECASE)
    if match:
        return match.group(1).lower()

    # Pattern-based detection
    for lang, patterns in LANGUAGE_PATTERNS:
        for pattern in patterns:
            if re.search(pattern, content, re.IGNORECASE):
                return lang

    return "unknown"


# =============================================================================
# METADATA EXTRACTION
# =============================================================================

def normalize_package_name(name: str) -> str:
    """
    Aggressively normalize package name - extract just the package component.
    Handles formats like "org/package" or "github.com/org/package" -> "package"
    Also handles "org__package" -> "package"

    WARNING: This is aggressive normalization. For output filenames, use
    strip_distro_suffix() instead to preserve package name structure.
    """
    name = name.strip()
    if '/' in name:
        # Take the last component (the actual package name)
        name = name.rstrip('/').split('/')[-1]
    if '__' in name:
        # Handle org__package format
        name = name.split('__')[-1]
    return name


def strip_distro_suffix(filename: str) -> str:
    """
    Strip only the distro/version suffix from a filename.
    Preserves the package name structure (including org__package format).

    Examples:
        phenomnomnominal__tsquery_ubi_9.3.sh -> phenomnomnominal__tsquery.sh
        ansible_rhel_8.7.sh -> ansible.sh
        python-fire_ubuntu_22.04.sh -> python-fire.sh
    """
    import re

    base = filename
    if base.endswith('.sh'):
        base = base[:-3]

    # Remove distro suffixes - order matters (most specific first)
    # Match _ubi_9.3, _ubi9.3, _ubi_9_3, _UBI_9.3, etc.
    patterns = [
        r'_[Uu][Bb][Ii]_?\d+[._]?\d*$',
        r'_[Rr][Hh][Ee][Ll]_?\d+[._]?\d*$',
        r'_[Uu]buntu_?\d+[._]?\d*$',
        r'_[Ss][Ll][Ee][Ss]_?\d+$',
        r'_[Cc]ent[Oo][Ss]_?\d+[._]?\d*$',
    ]

    for pattern in patterns:
        base = re.sub(pattern, '', base)

    return f"{base}.sh"


def extract_version_score(filename: str, script_path: Path) -> tuple[float, float, str]:
    """
    Extract version scores from a script filename and content for comparison.
    Returns (ubi_score, pkg_version_score, filename) for sorting.
    Higher scores = newer/better.
    """
    ubi_score = 0.0
    pkg_version_score = 0.0

    # Extract UBI version from filename (e.g., _ubi_9.3.sh, _ubi8.5.sh, _ubi_8_7.sh)
    ubi_match = re.search(r'_ubi[_]?(\d+)[._]?(\d+)?', filename, re.IGNORECASE)
    if ubi_match:
        major = int(ubi_match.group(1))
        minor = int(ubi_match.group(2)) if ubi_match.group(2) else 0
        ubi_score = major + minor / 10.0

    # Also check for RHEL version in filename
    rhel_match = re.search(r'_rhel[_]?(\d+)[._]?(\d+)?', filename, re.IGNORECASE)
    if rhel_match and ubi_score == 0:
        major = int(rhel_match.group(1))
        minor = int(rhel_match.group(2)) if rhel_match.group(2) else 0
        ubi_score = major + minor / 10.0

    # Try to extract package version from filename (e.g., _v2.38.3_)
    ver_match = re.search(r'_v?(\d+)[._](\d+)(?:[._](\d+))?_', filename)
    if ver_match:
        major = int(ver_match.group(1))
        minor = int(ver_match.group(2))
        patch = int(ver_match.group(3)) if ver_match.group(3) else 0
        pkg_version_score = major * 10000 + minor * 100 + patch

    # If no version in filename, try to read from script content
    if pkg_version_score == 0 and script_path.exists():
        try:
            content = script_path.read_text(encoding='utf-8', errors='ignore')[:2000]
            # Look for PACKAGE_VERSION or Version header
            ver_line = re.search(r'(?:PACKAGE_VERSION|#\s*Version\s*:)\s*["\']?v?(\d+)[._](\d+)(?:[._](\d+))?', content)
            if ver_line:
                major = int(ver_line.group(1))
                minor = int(ver_line.group(2))
                patch = int(ver_line.group(3)) if ver_line.group(3) else 0
                pkg_version_score = major * 10000 + minor * 100 + patch
        except Exception:
            pass

    return (ubi_score, pkg_version_score, filename)


def select_best_script(scripts: list[tuple[str, Path, list]]) -> tuple[str, Path, list]:
    """
    Select the best script from a list of scripts for the same package.
    Prefers: highest UBI version, then highest package version.
    """
    if len(scripts) == 1:
        return scripts[0]

    # Score each script
    scored = []
    for script_rel_path, script_path, row in scripts:
        filename = script_path.name
        ubi_score, pkg_score, _ = extract_version_score(filename, script_path)
        scored.append((ubi_score, pkg_score, script_rel_path, script_path, row))

    # Sort by UBI score (desc), then pkg version score (desc), then filename (for determinism)
    scored.sort(key=lambda x: (-x[0], -x[1], x[2]))

    # Return the best one
    _, _, rel_path, path, row = scored[0]
    return (rel_path, path, row)


def get_primary_script_from_build_info(pkg_dir: Path) -> Optional[str]:
    """
    Check build_info.json for the primary script name.
    Returns the script filename if found, None otherwise.
    """
    build_info_path = pkg_dir / "build_info.json"
    if not build_info_path.exists():
        return None

    try:
        with open(build_info_path, "r", encoding="utf-8") as f:
            build_info = json.load(f)

        # Look for script references in common fields
        # build_info.json typically has "build_script" or similar field
        for key in ["build_script", "script", "primary_script", "main_script"]:
            if key in build_info and build_info[key]:
                script_name = build_info[key]
                if isinstance(script_name, str) and script_name.endswith(".sh"):
                    return script_name

        # Also check if there's a scripts array
        if "scripts" in build_info and isinstance(build_info["scripts"], list):
            for script in build_info["scripts"]:
                if isinstance(script, str) and script.endswith(".sh"):
                    return script
                if isinstance(script, dict) and "name" in script:
                    return script["name"]

    except (json.JSONDecodeError, IOError):
        pass

    return None


def determine_primary_script(
    scripts: list[tuple[str, Path, list]],
    pkg_dir: Path,
) -> str:
    """
    Determine which script should get the simplified name.

    Priority:
    1. Script referenced in build_info.json
    2. Highest UBI/RHEL version (9.x > 8.x > 7.x)
    3. Highest Ubuntu version (24.04 > 22.04 > ...)

    Returns the filename of the primary script.
    """
    # First check build_info.json
    primary_from_build_info = get_primary_script_from_build_info(pkg_dir)
    if primary_from_build_info:
        # Verify this script exists in our list
        for _, script_path, _ in scripts:
            if script_path.name == primary_from_build_info:
                return primary_from_build_info

    # Fall back to distro scoring
    best = select_best_script(scripts)
    return best[1].name  # Return filename


def looks_like_version(ver: str) -> bool:
    """Check if a string looks like a valid version (starts with digit or v/V followed by digit)"""
    if not ver:
        return False
    ver = ver.strip()
    if not ver:
        return False
    # Versions typically start with: digit, 'v' followed by digit, or known prefixes
    if ver[0].isdigit():
        return True
    if len(ver) > 1 and ver[0].lower() == 'v' and ver[1].isdigit():
        return True
    # Some versions like "release-1.0" or "stable-2.0"
    if re.match(r'^(release|stable|version)[-_]?\d', ver, re.IGNORECASE):
        return True
    return False


def extract_version_from_alt_vars(content: str) -> Optional[str]:
    """Try to extract version from alternative variable names like RELEASE_TAG, BUILD_VERSION, BRANCH"""
    # Allow leading whitespace since these vars are often inside if blocks
    alt_var_patterns = [
        r'^\s*RELEASE_TAG=["\'"]?([^"\'"\n$]+)["\'"]?',
        r'^\s*BUILD_VERSION=["\'"]?([^"\'"\n$]+)["\'"]?',
        r'^\s*VERSION=["\'"]?([^"\'"\n$]+)["\'"]?',  # bare VERSION=
    ]
    for pattern in alt_var_patterns:
        match = re.search(pattern, content, re.MULTILINE)
        if match:
            ver = match.group(1).strip()
            if looks_like_version(ver):
                return ver

    # BRANCH often includes "--branch " prefix, e.g., BRANCH="--branch v0.3.1"
    branch_match = re.search(r'^\s*BRANCH=["\'"]?--branch\s+([^"\'"\n$]+)["\'"]?', content, re.MULTILINE)
    if branch_match:
        ver = branch_match.group(1).strip()
        if looks_like_version(ver):
            return ver

    return None


def extract_metadata(content: str, fallback_package_name: str = "") -> ScriptMetadata:
    """Extract package metadata from script

    Args:
        content: Script content
        fallback_package_name: Package name to use if not found in script
                               (typically the directory name)
    """
    metadata = ScriptMetadata()

    # PACKAGE_NAME - try shell variable first, then fallback to directory name
    # NOTE: We intentionally do NOT use the comment header (# Package: ...)
    # because it often contains display names like "Eclipse Equinox" instead
    # of the filesystem name "eclipse-equinox"
    match = re.search(r'^PACKAGE_NAME=["\'"]?([^"\'"\n]+)["\'"]?', content, re.MULTILINE)
    if match:
        metadata.package_name = match.group(1).strip()
    elif fallback_package_name:
        metadata.package_name = fallback_package_name

    # PACKAGE_VERSION - try shell variable first
    match = re.search(r'^PACKAGE_VERSION=["\'"]?([^"\'"\n]+)["\'"]?', content, re.MULTILINE)
    if match:
        ver = match.group(1).strip()
        # Handle ${1:-default} pattern
        ver = re.sub(r'\$\{1:-([^}]+)\}', r'\1', ver)
        metadata.package_version = ver
    else:
        # Try alternative variable names (RELEASE_TAG, BUILD_VERSION, etc.)
        alt_ver = extract_version_from_alt_vars(content)
        if alt_ver:
            metadata.package_version = alt_ver
        else:
            # Try header comment format: # Version : 1.0.0
            match = re.search(r'^#\s*Version\s*:\s*(.+)$', content, re.MULTILINE | re.IGNORECASE)
            if match:
                header_ver = match.group(1).strip()
                # Check if header version looks reasonable
                if looks_like_version(header_ver):
                    metadata.package_version = header_ver
                else:
                    # Header version looks like garbage (e.g., "code-cleanups")
                    # Try to find a better version from alt vars even if we didn't find PACKAGE_VERSION
                    alt_ver = extract_version_from_alt_vars(content)
                    metadata.package_version = alt_ver if alt_ver else header_ver

    # Define the placeholder we want to get rid of
    PLACEHOLDER_URL = "https://github.com/org/repo"

    # PACKAGE_URL - try multiple sources in order of preference
    extracted_url = None

    # 1. Try Shell variable PACKAGE_URL=
    match = re.search(r'^PACKAGE_URL=["\'"]?([^"\'"\n]+)["\'"]?', content, re.MULTILINE)
    if match:
        extracted_url = match.group(1).strip()

    # 2. If #1 failed OR it returned the placeholder, try alternatives
    if not extracted_url or extracted_url == PLACEHOLDER_URL:
        # Alternative shell variables: REPO=, REPO_URL=
        match = re.search(r'^(?:REPO|REPO_URL)=["\'"]?(https?://[^"\'"\n\s]+)["\'"]?', content, re.MULTILINE)
        if match:
            extracted_url = match.group(1).strip()

    # 3. Still placeholder or empty? Try Header comments
    if not extracted_url or extracted_url == PLACEHOLDER_URL:
        match = re.search(r'^#\s*Source(?:\s+repo)?\s*:\s*(https?://\S+)', content, re.MULTILINE | re.IGNORECASE)
        if match:
            temp_url = match.group(1).strip()
            if temp_url != PLACEHOLDER_URL:
                extracted_url = temp_url

    # 4. Final Fallback: Look for actual git clone commands
    if not extracted_url or extracted_url == PLACEHOLDER_URL:
        match = re.search(r'git\s+clone\s+["\']?(https?://(?:github|gitlab)[^\s"\']+)', content, re.IGNORECASE)
        if match:
            temp_url = match.group(1).strip()
            if temp_url != PLACEHOLDER_URL:
                extracted_url = temp_url

    # Assign the final result
    metadata.package_url = extracted_url or PLACEHOLDER_URL

    # Maintainer from header
    match = re.search(r'^#.*Maintainer\s*:\s*(.+)$', content, re.MULTILINE | re.IGNORECASE)
    if match:
        metadata.maintainer = match.group(1).strip()

    # Tested on from header
    match = re.search(r'^#.*Tested on\s*:\s*(.+)$', content, re.MULTILINE | re.IGNORECASE)
    if match:
        metadata.tested_on = match.group(1).strip()

    return metadata


# =============================================================================
# PACKAGE EXTRACTION
# =============================================================================

def extract_package_name_from_rpm_url(url: str) -> Optional[str]:
    """
    Extract package name from an RPM URL or path.
    e.g., https://rpmfind.net/.../bison-3.7.4-5.el9.ppc64le.rpm -> bison
          /path/to/readline-devel-8.1-4.el9.x86_64.rpm -> readline-devel
    """
    # Get the filename
    filename = url.rstrip('/').split('/')[-1]

    if not filename.endswith('.rpm'):
        return None

    # Remove .rpm extension
    filename = filename[:-4]

    # Remove architecture suffix (.ppc64le, .x86_64, .aarch64, .i686, .noarch, .src)
    filename = re.sub(r'\.(ppc64le|x86_64|aarch64|i686|noarch|src)$', '', filename)

    # Now we have name-version-release (e.g., bison-3.7.4-5.el9)
    # Split on '-' and take everything before the version starts
    parts = filename.split('-')

    # Find where version starts (first part beginning with a digit)
    name_parts = []
    for part in parts:
        if part and part[0].isdigit():
            break
        name_parts.append(part)

    return '-'.join(name_parts) if name_parts else None


def extract_packages_from_command(content: str, pattern: str) -> list[str]:
    """
    Extract package names from install commands matching pattern.
    Handles continuation lines (backslash at end of line).
    Extracts package names from RPM URLs (assumes AppStream availability).
    """
    packages = []

    # Find install commands and handle continuation lines
    install_pattern = pattern + r'\s+install\s+-y\s+'

    for match in re.finditer(install_pattern, content):
        start_pos = match.end()

        # Collect everything until we hit a line without continuation
        lines = []
        remaining = content[start_pos:]

        for line in remaining.split('\n'):
            stripped = line.rstrip()

            # Stop at empty lines
            if not stripped:
                break

            # If line doesn't end with \, this is the last line
            if not stripped.endswith('\\'):
                # Extract up to any command separator
                for sep in ['&&', '||', ';', '|']:
                    if sep in stripped:
                        stripped = stripped[:stripped.index(sep)]
                        break
                lines.append(stripped)
                break
            else:
                # Remove trailing backslash and continue
                lines.append(stripped[:-1])

        # Join all lines and parse packages
        pkg_text = ' '.join(lines)

        # Remove comments
        pkg_text = re.sub(r'#.*', '', pkg_text)

        # Split and filter
        for pkg in pkg_text.split():
            pkg = pkg.strip()
            if not pkg:
                continue

            # Skip options and variables
            if pkg.startswith('-') or pkg.startswith('$') or '=' in pkg:
                continue

            # Extract package name from URLs (RPMs from rpmfind, etc.)
            if pkg.startswith('http://') or pkg.startswith('https://') or pkg.startswith('/'):
                extracted = extract_package_name_from_rpm_url(pkg)
                if extracted:
                    packages.append(extracted)
                continue

            packages.append(pkg)

    return sorted(set(packages))


def extract_packages(content: str, tested_on: str) -> PackageDependencies:
    """Extract package dependencies from script"""
    deps = PackageDependencies()

    # Detect distro from tested_on header first
    distro_from_header = detect_distro_from_tested_on(tested_on)

    # Detect distro from actual package manager commands
    distro_from_content = detect_distro_from_content(content)

    # Extract packages for each distro type
    rh_pkgs = extract_packages_from_command(content, r'(?:yum|dnf)')
    deb_pkgs = extract_packages_from_command(content, r'apt-get')
    sles_pkgs = extract_packages_from_command(content, r'zypper')

    # Only populate the distro that matches - NO auto-conversion
    if rh_pkgs:
        deps.rh_packages = rh_pkgs
        deps.detected_distro = "rhel"
    if deb_pkgs:
        deps.deb_packages = deb_pkgs
        deps.detected_distro = "debian"
    if sles_pkgs:
        deps.sles_packages = sles_pkgs
        deps.detected_distro = "sles"

    # If we detected packages for multiple distros, use header to disambiguate
    # (rare case where script has multi-distro support built in)
    if sum(bool(x) for x in [rh_pkgs, deb_pkgs, sles_pkgs]) > 1:
        deps.detected_distro = distro_from_header or distro_from_content or "multiple"
    elif not deps.detected_distro:
        deps.detected_distro = distro_from_header or distro_from_content or ""

    return deps


# =============================================================================
# CUSTOM LOGIC EXTRACTION
# =============================================================================

def is_handled_line(line: str) -> bool:
    """
    Check if a line is something we handle automatically and can skip.
    Returns True for lines we're confident about, False for lines needing review.
    """
    stripped = line.strip()

    # Empty lines and comments at the top are handled
    if not stripped:
        return True

    # Header comments (we extract metadata from these)
    if stripped.startswith('#'):
        # But keep non-header comments that look like inline documentation
        # Header comments are at the start; once we hit code, comments are meaningful
        return True

    # Shebang
    if stripped.startswith('#!/'):
        return True

    # Package manager commands (we extract these)
    if re.match(r'^(sudo\s+)?(yum|dnf|apt-get|apt|zypper)\s+', stripped):
        return True

    # Standard variable assignments we capture
    if re.match(r'^(PACKAGE_NAME|PACKAGE_VERSION|PACKAGE_URL|SCRIPT_DIR)=', stripped):
        return True

    # Variable assignments that reference captured vars
    if re.match(r'^(CWD|CURDIR|WORKDIR|WDIR|HOME_DIR)=', stripped):
        return True

    # cd to home/work directory (boilerplate)
    if re.match(r'^cd\s+(\$HOME|\$WORKDIR|\$CWD|~|/tmp|/root)', stripped):
        return True

    # set -e / set -x (we handle in template)
    if re.match(r'^set\s+[-+][euxo]', stripped):
        return True

    # Automation/logging echo statements (template handles these)
    # Matches: echo "---...", echo "$PACKAGE_NAME | ...", exit 0/1/2
    if re.match(r'^echo\s+["\']?-{5,}', stripped):
        return True
    if re.match(r'^echo\s+["\']?\$PACKAGE', stripped):
        return True
    if re.match(r'^exit\s+[012]', stripped):
        return True

    # Git clone/checkout of main package (template handles this)
    if re.match(r'^git\s+clone\s+\$PACKAGE_URL', stripped):
        return True
    if re.match(r'^git\s+checkout\s+\$PACKAGE_VERSION', stripped):
        return True
    if re.match(r'^cd\s+\$PACKAGE_NAME', stripped):
        return True

    # Bare control flow keywords (leftover from filtered blocks)
    if stripped in ('else', 'fi', 'done', 'esac', 'then', '{', '}'):
        return True

    # Test/build commands that templates handle
    if re.match(r'^if\s+!\s*(bundle|gem|npm|pip|go\s|mvn|gradle|pytest|ruby|python|node)', stripped):
        return True

    # Ruby/RVM setup (ruby template handles this)
    if re.match(r'^(rvm|rbenv|gem)\s+', stripped):
        return True
    if re.match(r'^source.*/rvm\.sh', stripped):
        return True
    if 'rvm.io' in stripped:
        return True

    # Redis/service installation via package manager or simple download
    # (can be added to deps instead)
    if re.match(r'^(redis-server|redis-cli)\s', stripped):
        return True
    if 'redis.io/releases' in stripped:
        return True
    if re.match(r'^(wget|curl)\s+.*redis', stripped, re.IGNORECASE):
        return True
    if re.match(r'^tar\s+.*redis', stripped, re.IGNORECASE):
        return True
    if re.match(r'^cd\s+redis', stripped, re.IGNORECASE):
        return True
    if re.match(r'^mkdir.*redis', stripped, re.IGNORECASE):
        return True
    if re.match(r'^cp\s+.*redis', stripped, re.IGNORECASE):
        return True

    # Bare make commands (often orphaned from filtered builds)
    if stripped in ('make', 'make install', 'make clean', 'make test', 'make check'):
        return True

    # Everything else needs review
    return False


def extract_unhandled_lines(content: str) -> list[str]:
    """
    Extract lines from the original script that we're NOT confident
    we handled correctly. These go into a review section.
    """
    lines = content.split('\n')
    unhandled = []
    in_header = True
    in_package_install = False

    for line in lines:
        stripped = line.strip()

        # Track when we exit the header section
        if in_header and stripped and not stripped.startswith('#'):
            in_header = False

        # Skip header comments
        if in_header and stripped.startswith('#'):
            continue

        # Track multi-line package installs (continuation lines)
        if re.search(r'(yum|dnf|apt-get|zypper)\s+install', line):
            in_package_install = True
        if in_package_install:
            if not stripped.endswith('\\'):
                in_package_install = False
            continue

        # Check if this line is handled
        if is_handled_line(line):
            continue

        # This line needs review
        unhandled.append(line.rstrip())

    # Remove leading/trailing empty lines from unhandled
    while unhandled and not unhandled[0].strip():
        unhandled.pop(0)
    while unhandled and not unhandled[-1].strip():
        unhandled.pop()

    return unhandled


def extract_custom_logic(content: str) -> CustomLogic:
    """Extract custom logic that needs special handling"""
    logic = CustomLogic()

    # Pre-packages commands (repo configuration)
    repo_patterns = [
        r'^.*yum-config-manager.*$',
        r'^.*dnf config-manager.*$',
    ]
    for pattern in repo_patterns:
        for match in re.finditer(pattern, content, re.MULTILINE):
            logic.pre_packages_commands.append(match.group(0).strip())
    logic.has_pre_packages = bool(logic.pre_packages_commands)

    # Patch commands
    patch_patterns = [
        r'^.*\bpatch\s+.*$',
        r'^.*\.patch.*$',
        r'^.*git\s+apply.*$',
    ]
    for pattern in patch_patterns:
        for match in re.finditer(pattern, content, re.MULTILINE):
            line = match.group(0).strip()
            if line and not line.startswith('#'):
                logic.patch_commands.append(line)
    logic.has_patches = bool(logic.patch_commands)

    # Workarounds (sed/awk modifications)
    workaround_patterns = [
        r'^.*sed\s+-i.*$',
        r'^.*awk.*>.*$',
        r'^.*perl\s+-pi.*$',
    ]
    for pattern in workaround_patterns:
        for match in re.finditer(pattern, content, re.MULTILINE):
            line = match.group(0).strip()
            if line and not line.startswith('#'):
                logic.workaround_commands.append(line)
    logic.has_workarounds = bool(logic.workaround_commands)

    # Custom environment variables (beyond standard ones)
    standard_vars = {
        'PATH', 'GOROOT', 'GOPATH', 'JAVA_HOME', 'HOME', 'LC_ALL',
        'LANG', 'LANGUAGE', 'NVM_DIR', 'GRADLE_HOME', 'M2_HOME',
    }
    for match in re.finditer(r'^export\s+([A-Z_]+)=(.+)$', content, re.MULTILINE):
        var_name = match.group(1)
        if var_name not in standard_vars:
            logic.env_vars.append(match.group(0))

    # Custom build commands
    build_patterns = [r'cmake', r'meson', r'ninja', r'cargo', r'rustc', r'make\s+install']
    for pattern in build_patterns:
        if re.search(pattern, content):
            for match in re.finditer(rf'^.*{pattern}.*$', content, re.MULTILINE):
                line = match.group(0).strip()
                if line and not line.startswith('#'):
                    logic.custom_build_steps.append(line)

    # Custom test commands
    test_patterns = [r'nosetests', r'unittest', r'coverage', r'tox\s+-e', r'nox\s+-s']
    for pattern in test_patterns:
        if re.search(pattern, content):
            for match in re.finditer(rf'^.*{pattern}.*$', content, re.MULTILINE):
                line = match.group(0).strip()
                if line and not line.startswith('#'):
                    logic.custom_test_steps.append(line)

    # Extract unhandled lines for manual review
    logic.unhandled_lines = extract_unhandled_lines(content)

    return logic


# =============================================================================
# SCRIPT ANALYSIS
# =============================================================================

def is_shell_script(content: str) -> bool:
    """Check if content appears to be a shell script"""
    first_line = content.split('\n')[0] if content else ""
    return first_line.startswith('#')


def is_already_migrated(content: str) -> bool:
    """Check if script already uses new template format"""
    return bool(re.search(r'source.*lib/common\.sh', content))


def analyze_script(
    script_path: Path,
    language_override: Optional[str] = None,
    verbose: bool = False,
) -> Optional[ScriptAnalysis]:
    """Analyze a build script for migration"""
    try:
        content = script_path.read_text(encoding="utf-8", errors="replace")
    except Exception as e:
        log_error(f"Failed to read {script_path}: {e}")
        return None

    if not is_shell_script(content):
        if verbose:
            log_warn(f"Not a shell script: {script_path}")
        return None

    # Check if already migrated
    already_migrated = is_already_migrated(content)

    # Detect language
    language = detect_language(content, language_override)

    # Extract metadata (use directory name as fallback for PACKAGE_NAME)
    fallback_pkg_name = script_path.parent.name
    metadata = extract_metadata(content, fallback_pkg_name)

    # Extract packages
    packages = extract_packages(content, metadata.tested_on)

    # Extract custom logic
    custom_logic = extract_custom_logic(content)

    # Determine complexity
    if custom_logic.has_patches or custom_logic.has_workarounds or custom_logic.custom_build_steps:
        complexity = "complex"
    elif not metadata.package_name or not metadata.package_url:
        complexity = "incomplete"
    else:
        complexity = "simple"

    return ScriptAnalysis(
        path=script_path,
        content=content,
        language=language,
        metadata=metadata,
        packages=packages,
        custom_logic=custom_logic,
        already_migrated=already_migrated,
        complexity=complexity,
    )


# =============================================================================
# SCRIPT GENERATION
# =============================================================================

def generate_migrated_script(analysis: ScriptAnalysis, templates_dir: Path) -> str:
    """Generate the migrated script content"""

    lang_display = LANGUAGE_DISPLAY_NAMES.get(analysis.language, "Unknown")
    template_name = LANGUAGE_TEMPLATES.get(analysis.language, "")
    meta = analysis.metadata
    pkg = analysis.packages
    logic = analysis.custom_logic

    # 1. URL Validation
    placeholder = "https://github.com/org/repo"
    is_placeholder = (meta.package_url == placeholder or not meta.package_url)
    source_url = meta.package_url if not is_placeholder else placeholder

    lines = []

    # Header
    lines.append("#!/bin/bash -e")
    lines.append("# -----------------------------------------------------------------------------")
    lines.append(f"# Package       : {meta.package_name or 'PACKAGE_NAME'}")
    lines.append(f"# Version       : {meta.package_version or 'v1.0.0'}")
    lines.append(f"# Source repo   : {source_url}")
    lines.append(f"# Tested on     : {meta.tested_on or 'UBI:9.6'}")
    lines.append(f"# Language      : {lang_display}")
    lines.append("# Script License: Apache License, Version 2 or later")
    lines.append(f"# Maintainer    : {meta.maintainer or 'Maintainer <maintainer@example.com>'}")
    lines.append("# -----------------------------------------------------------------------------")

    # Complexity warning for complex migrations
    if is_placeholder or analysis.complexity == "complex" or logic.has_pre_packages:
        lines.append("# WARNING: Auto-migrated script - REVIEW REQUIRED")
        lines.append(f"#   - Original: {analysis.path.name}")
        if is_placeholder:
            lines.append("# FIXME: Placeholder PACKAGE_URL detected. Verify upstream repo.")
        if logic.has_pre_packages:
            lines.append("#   - Has pre_packages callback")
        if logic.has_patches:
            lines.append("#   - Has patch commands")
        if logic.has_workarounds:
            lines.append("#   - Has workaround commands")
        lines.append("# -----------------------------------------------------------------------------")

    # Version unconfirmed warning
    if getattr(meta, 'version_unconfirmed', False):
        lines.append("# WARNING: VERSION NOT CONFIRMED IN PACKAGING AUTHORITY")
        lines.append("# -----------------------------------------------------------------------------")

    lines.append("")
    lines.append('SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"')
    lines.append("")

    # Package metadata
    lines.append("# =============================================================================")
    lines.append("# REQUIRED: Package metadata")
    lines.append("# =============================================================================")
    lines.append(f'PACKAGE_NAME="{meta.package_name or "PACKAGE_NAME"}"')

    # Version line with optional substitution comment
    version_line = f'PACKAGE_VERSION="${{1:-{meta.package_version or "v1.0.0"}}}"'
    if getattr(meta, 'version_substituted', False) and getattr(meta, 'version_original', ''):
        version_line += f'  # Updated from {meta.version_original} (not available, >5 years old)'
    elif getattr(meta, 'version_source', ''):
        version_line += f'  # PACKAGE_VERSION updated based on {meta.version_source} input file'
    lines.append(version_line)

    lines.append(f'PACKAGE_URL="{meta.package_url or "https://github.com/org/repo"}"')

    # Available tags for fallback testing (if version was looked up)
    if getattr(meta, 'available_tags', ''):
        lines.append(f'{meta.available_tags}  # Available git tags for fallback testing')

    lines.append("")

    # Dependencies - ONLY populate the detected distro, leave others empty
    lines.append("# =============================================================================")
    lines.append("# REQUIRED: Dependencies")
    lines.append("# =============================================================================")

    if pkg.rh_packages:
        lines.append(f'RH_DEP_PKGS="{" ".join(pkg.rh_packages)}"')
    else:
        lines.append('RH_DEP_PKGS=""')

    if pkg.deb_packages:
        lines.append(f'DEB_DEP_PKGS="{" ".join(pkg.deb_packages)}"')
    else:
        lines.append('DEB_DEP_PKGS=""')

    if pkg.sles_packages:
        lines.append(f'SLES_DEP_PKGS="{" ".join(pkg.sles_packages)}"')
    else:
        lines.append('SLES_DEP_PKGS=""')

    # Custom environment variables
    if logic.env_vars:
        lines.append("")
        lines.append("# =============================================================================")
        lines.append("# OPTIONAL: Custom environment variables (from original script)")
        lines.append("# =============================================================================")
        lines.extend(logic.env_vars)

    # Callback functions
    if logic.has_pre_packages or logic.has_patches or logic.has_workarounds:
        lines.append("")
        lines.append("# =============================================================================")
        lines.append("# OPTIONAL: Callback functions for custom logic")
        lines.append("# =============================================================================")

    if logic.has_pre_packages:
        lines.append("")
        lines.append("# Add extra repos before package install (extracted from original script)")
        lines.append("pre_packages() {")
        for cmd in logic.pre_packages_commands[:5]:  # Limit to first 5
            lines.append(f"    {cmd}")
        lines.append("}")

    if logic.has_patches:
        lines.append("")
        lines.append("# Apply patches after cloning (extracted from original script)")
        lines.append("post_clone() {")
        lines.append("    # TODO: Review and update patch commands from original script")
        for cmd in logic.patch_commands[:5]:  # Limit to first 5
            lines.append(f"    {cmd}")
        lines.append("}")

    if logic.has_workarounds:
        lines.append("")
        lines.append("# Apply workarounds after cloning (extracted from original script)")
        lines.append("# TODO: Merge with post_clone if both exist")
        lines.append("_apply_workarounds() {")
        for cmd in logic.workaround_commands[:5]:  # Limit to first 5
            lines.append(f"    {cmd}")
        lines.append("}")

    if logic.custom_test_steps:
        lines.append("")
        lines.append("# Custom test command (extracted from original script)")
        lines.append("custom_test_command() {")
        lines.append("    # TODO: Review and update test commands")
        for cmd in logic.custom_test_steps[:3]:  # Limit to first 3
            lines.append(f"    {cmd}")
        lines.append("}")

    # Add unhandled lines as a review section
    if logic.unhandled_lines:
        lines.append("")
        lines.append("# REVIEW - following code was not auto-migrated. See PORTING-NOTES.md for details.")
        for line in logic.unhandled_lines:
            if line.strip():
                lines.append(f"# {line}")
            else:
                lines.append("#")

    # Source the template
    lines.append("")
    lines.append("# =============================================================================")
    lines.append(f"# Execute the build (invokes the {lang_display} template)")
    lines.append("# =============================================================================")
    lines.append(f'source "${{SCRIPT_DIR}}/../../templates/{template_name}"')
    lines.append("")

    return "\n".join(lines)


# =============================================================================
# MIGRATION
# =============================================================================

@dataclass
class MigrationStats:
    """Statistics for migration run"""
    total: int = 0
    migrated: int = 0
    skipped: int = 0
    failed: int = 0
    assets_copied: int = 0
    build_info_updated: int = 0


# =============================================================================
# PACKAGE ASSET HANDLING (build_info.json, LICENSE, patches)
# =============================================================================

def process_build_info(
    source_pkg_dir: Path,
    dest_pkg_dir: Path,
    rename_map: dict[str, str],
    dry_run: bool = False,
    verbose: bool = False,
) -> tuple[bool, list[Path]]:
    """
    Process build_info.json for a package:
    - Update script name references based on rename_map
    - Return list of referenced files to copy (.patch files, etc.)

    Returns (was_updated, list_of_referenced_files)
    """
    build_info_path = source_pkg_dir / "build_info.json"
    if not build_info_path.exists():
        return False, []

    try:
        with open(build_info_path, "r", encoding="utf-8") as f:
            build_info = json.load(f)
    except (json.JSONDecodeError, IOError) as e:
        log_warn(f"Failed to read build_info.json: {e}")
        return False, []

    # Track if we made any changes
    original_content = json.dumps(build_info, sort_keys=True)

    # Collect referenced files (patches, etc.)
    referenced_files: list[Path] = []

    # Update script references and collect referenced files
    def process_value(obj):
        """Recursively process JSON values to update script names and find file references."""
        if isinstance(obj, dict):
            return {k: process_value(v) for k, v in obj.items()}
        elif isinstance(obj, list):
            return [process_value(item) for item in obj]
        elif isinstance(obj, str):
            # Check if this is a script name that needs renaming
            for old_name, new_name in rename_map.items():
                if old_name in obj:
                    obj = obj.replace(old_name, new_name)
            # Check if this looks like a file reference (.patch, .diff, etc.)
            if obj.endswith(('.patch', '.diff', '.sed', '.txt')):
                ref_path = source_pkg_dir / obj
                if ref_path.exists():
                    referenced_files.append(ref_path)
            return obj
        return obj

    updated_build_info = process_value(build_info)
    updated_content = json.dumps(updated_build_info, sort_keys=True)
    was_updated = original_content != updated_content

    # Write updated build_info.json to destination
    if not dry_run:
        dest_pkg_dir.mkdir(parents=True, exist_ok=True)
        dest_build_info = dest_pkg_dir / "build_info.json"
        with open(dest_build_info, "w", encoding="utf-8") as f:
            json.dump(updated_build_info, f, indent=2)

    if verbose:
        if was_updated:
            log_info(f"Updated build_info.json: {source_pkg_dir.name}")
        else:
            log_info(f"Copied build_info.json: {source_pkg_dir.name}")

    return was_updated, referenced_files


def copy_package_assets(
    source_pkg_dir: Path,
    dest_pkg_dir: Path,
    rename_map: dict[str, str],
    stats: "MigrationStats",
    dry_run: bool = False,
    verbose: bool = False,
) -> None:
    """
    Copy non-script assets for a package:
    - LICENSE file
    - build_info.json (with script name updates)
    - Any files referenced in build_info.json (.patch files, etc.)
    """
    if not source_pkg_dir.exists():
        return

    # Process build_info.json first (to get list of referenced files)
    was_updated, referenced_files = process_build_info(
        source_pkg_dir, dest_pkg_dir, rename_map, dry_run, verbose
    )
    if was_updated:
        stats.build_info_updated += 1
        stats.assets_copied += 1
    elif (source_pkg_dir / "build_info.json").exists():
        stats.assets_copied += 1

    # Copy LICENSE if present
    license_path = source_pkg_dir / "LICENSE"
    if license_path.exists():
        if not dry_run:
            dest_pkg_dir.mkdir(parents=True, exist_ok=True)
            shutil.copy2(license_path, dest_pkg_dir / "LICENSE")
        stats.assets_copied += 1
        if verbose:
            log_info(f"Copied LICENSE: {source_pkg_dir.name}")

    # Copy referenced files (.patch, etc.)
    for ref_file in referenced_files:
        if not dry_run:
            dest_pkg_dir.mkdir(parents=True, exist_ok=True)
            shutil.copy2(ref_file, dest_pkg_dir / ref_file.name)
        stats.assets_copied += 1
        if verbose:
            log_info(f"Copied {ref_file.name}: {source_pkg_dir.name}")


def copy_templates_to_dest(
    templates_dir: Path,
    dest_dir: Path,
    dry_run: bool = False,
    verbose: bool = False,
) -> int:
    """
    Copy entire templates directory to destination.
    Includes: template scripts, lib/, examples/, LICENSE, README, etc.
    Returns count of files copied.
    """
    dest_templates = dest_dir / "templates"
    copied = 0

    if not templates_dir.exists():
        log_error(f"Templates directory not found: {templates_dir}")
        return 0

    log_info(f"Copying templates to: {dest_templates}")

    if not dry_run:
        # Remove existing templates dir if present (to ensure clean copy)
        if dest_templates.exists():
            shutil.rmtree(dest_templates)

        # Copy entire templates directory
        shutil.copytree(templates_dir, dest_templates)

    # Count files for reporting
    all_files = list(templates_dir.rglob("*"))
    copied = len([f for f in all_files if f.is_file()])

    if verbose:
        for item in sorted(templates_dir.iterdir()):
            if item.is_dir():
                log_info(f"  Copied directory: {item.name}/")
            else:
                log_info(f"  Copied file: {item.name}")

    log_success(f"Copied templates directory ({copied} files) to {dest_templates}")
    return copied


def copy_template_tools_to_dest(
    script_dir: Path,
    dest_dir: Path,
    dry_run: bool = False,
    verbose: bool = False,
) -> int:
    """
    Copy template-tools directory to destination (inside templates/).
    Returns count of files copied.
    """
    dest_tools = dest_dir / "templates" / "template-tools"
    copied = 0

    if not script_dir.exists():
        log_error(f"Template-tools directory not found: {script_dir}")
        return 0

    log_info(f"Copying template-tools to: {dest_tools}")

    # Files and directories to copy (active tools)
    items_to_copy = [
        "migrate_to_template.py",
        "migrate_to_template",
        "analyze_migration_candidates.py",
        "analyze_migration_candidates",
        "filter_candidates.py",
        "filter_candidates",
        "make-list.sh",
        "data",
    ]

    if not dry_run:
        dest_tools.mkdir(parents=True, exist_ok=True)

    for item_name in items_to_copy:
        item_path = script_dir / item_name
        if not item_path.exists():
            continue

        dest_path = dest_tools / item_name
        if not dry_run:
            if item_path.is_dir():
                if dest_path.exists():
                    shutil.rmtree(dest_path)
                shutil.copytree(item_path, dest_path)
            else:
                shutil.copy2(item_path, dest_path)

        if item_path.is_dir():
            dir_files = list(item_path.rglob("*"))
            copied += len([f for f in dir_files if f.is_file()])
        else:
            copied += 1

        if verbose:
            suffix = "/" if item_path.is_dir() else ""
            log_info(f"  Copied: {item_name}{suffix}")

    log_success(f"Copied template-tools ({copied} files) to {dest_tools}")
    return copied


def migrate_script(
    script_path: Path,
    output_path: Path,
    templates_dir: Path,
    language_override: Optional[str] = None,
    dry_run: bool = False,
    force: bool = False,
    verbose: bool = False,
    version_matcher: Optional["VersionMatcher"] = None,
) -> tuple[bool, str]:
    """
    Migrate a single script.
    Returns (success, message)
    """
    log_info(f"Migrating: {script_path.name}")

    # Analyze
    analysis = analyze_script(script_path, language_override, verbose)
    if analysis is None:
        return False, "Analysis failed"

    if analysis.already_migrated:
        log_warn(f"Already migrated: {script_path}")
        return False, "Already migrated"

    # Apply version matching if matcher is provided
    if version_matcher and analysis.metadata.package_version:
        from .version_matcher import VersionMatchResult, LANGUAGE_VERSION_FILES
        match_result = version_matcher.match_version(
            package_name=analysis.metadata.package_name,
            input_version=analysis.metadata.package_version,
            language=analysis.language,
            package_url=analysis.metadata.package_url,
            script_path=str(script_path),
        )

        if match_result.matched_version:
            if match_result.confidence == "substituted":
                log_info(f"Version substituted: {analysis.metadata.package_version} -> {match_result.matched_version} (original too old)")
                analysis.metadata.version_substituted = True
                analysis.metadata.version_original = analysis.metadata.package_version
                version_file = "github_tags_mapping.json"
                analysis.metadata.version_source = version_file
            elif match_result.confidence != "exact":
                log_info(f"Version corrected: {analysis.metadata.package_version} -> {match_result.matched_version}")
                # Track the source file for the comment
                version_file = LANGUAGE_VERSION_FILES.get(analysis.language.lower(), "github_tags_mapping.json")
                analysis.metadata.version_source = version_file
            analysis.metadata.package_version = match_result.matched_version
            # Store available tags for build script
            if match_result.available_tags:
                analysis.metadata.available_tags = match_result.available_tags
        else:
            # Version couldn't be confirmed
            analysis.metadata.version_unconfirmed = True
            if verbose:
                log_warn(f"Version not confirmed: {analysis.metadata.package_version} ({match_result.message})")

    # Check template exists
    template_name = LANGUAGE_TEMPLATES.get(analysis.language)
    if not template_name:
        log_error(f"{script_path}: No template for language '{analysis.language}'")
        return False, f"No template for {analysis.language}"

    template_path = templates_dir / template_name
    if not template_path.exists():
        log_error(f"Template not found: {template_path}")
        return False, f"Template not found: {template_name}"

    # Check output
    if output_path.exists() and not force:
        log_warn(f"Output exists (use -f to overwrite): {output_path}")
        return False, "Output exists"

    # Generate
    if dry_run:
        log_info(f"[DRY-RUN] Would generate: {output_path}")
        log_info(f"  Language: {analysis.language}")
        log_info(f"  Package: {analysis.metadata.package_name}")
        log_info(f"  Complexity: {analysis.complexity}")
        log_info(f"  Detected distro: {analysis.packages.detected_distro}")
        return True, "Dry run"

    # Create output directory and write
    output_path.parent.mkdir(parents=True, exist_ok=True)
    content = generate_migrated_script(analysis, templates_dir)
    output_path.write_text(content, encoding="utf-8")
    output_path.chmod(0o755)

    log_success(f"Generated: {output_path}")
    return True, "Migrated"


def scan_script(
    script_path: Path,
    language_override: Optional[str] = None,
    verbose: bool = False,
) -> Optional[ScriptAnalysis]:
    """Scan a script and return its analysis"""
    return analyze_script(script_path, language_override, verbose)


# =============================================================================
# BATCH PROCESSING
# =============================================================================

def process_directory(
    dir_path: Path,
    output_dir: Path,
    templates_dir: Path,
    stats: MigrationStats,
    scan_only: bool = False,
    language_override: Optional[str] = None,
    dry_run: bool = False,
    force: bool = False,
    verbose: bool = False,
    version_matcher: Optional["VersionMatcher"] = None,
) -> list[ScriptAnalysis]:
    """Process all scripts in a directory"""
    results = []

    for script_path in sorted(dir_path.rglob("*.sh")):
        # Skip templates and tools
        rel_str = str(script_path)
        if "/templates/" in rel_str or "/template-tools/" in rel_str:
            continue

        stats.total += 1

        if scan_only:
            analysis = scan_script(script_path, language_override, verbose)
            if analysis:
                results.append(analysis)
        else:
            rel_path = script_path.relative_to(dir_path)
            output_path = output_dir / rel_path

            success, msg = migrate_script(
                script_path, output_path, templates_dir,
                language_override, dry_run, force, verbose,
                version_matcher,
            )
            if success:
                stats.migrated += 1
            elif msg in ["Already migrated", "Output exists"]:
                stats.skipped += 1
            else:
                stats.failed += 1

    return results


def process_batch_file(
    batch_file: Path,
    base_dir: Path,
    output_dir: Path,
    templates_dir: Path,
    stats: MigrationStats,
    language_override: Optional[str] = None,
    dry_run: bool = False,
    force: bool = False,
    verbose: bool = False,
    version_matcher: Optional["VersionMatcher"] = None,
) -> list[dict]:
    """Process scripts listed in a batch file (supports CSV format)

    Returns list of mapping entries for advanced_mapping.csv
    """
    import csv

    log_info(f"Processing batch file: {batch_file}")
    log_info(f"Base directory: {base_dir}")

    # Collect mapping info for advanced_mapping.csv
    mapping_entries: list[dict] = []

    with open(batch_file, "r", encoding="utf-8") as f:
        # Detect if it's a CSV (has quotes or commas in first line)
        first_line = f.readline()
        f.seek(0)

        is_csv = ',' in first_line and ('"' in first_line or first_line.count(',') >= 2)

        if is_csv:
            # First pass: collect all scripts grouped by package
            from collections import defaultdict
            package_scripts: dict[str, list[tuple[str, Path, str]]] = defaultdict(list)

            reader = csv.reader(f)
            for row in reader:
                if not row or row[0].startswith('#') or row[0] == 'package_name':
                    continue

                # CSV format: package_name, package_version, language, language_version, script_path, ...
                if len(row) < 5:
                    continue

                package_name = row[0].strip()
                script_rel_path = row[4].strip()

                # Strip "build-scripts/" prefix if present
                if script_rel_path.startswith("build-scripts/"):
                    script_rel_path = script_rel_path[len("build-scripts/"):]

                # Resolve path relative to base_dir
                if script_rel_path.startswith('/'):
                    script_path = Path(script_rel_path)
                else:
                    script_path = base_dir / script_rel_path

                if not script_path.exists():
                    log_warn(f"File not found: {script_path}")
                    continue

                if not script_path.is_file():
                    log_warn(f"Not a file (is a directory?): {script_path}")
                    continue

                package_scripts[package_name].append((script_rel_path, script_path, row))

            # Second pass: for each package, migrate ALL scripts
            # Primary script gets simplified name, others keep their names
            for package_name, scripts in package_scripts.items():
                # Determine output directory from first script's path
                first_rel_path = scripts[0][0]
                rel_parts = first_rel_path.split('/')
                if len(rel_parts) >= 2:
                    out_subdir = output_dir / rel_parts[0] / rel_parts[1]
                else:
                    out_subdir = output_dir

                if not dry_run:
                    out_subdir.mkdir(parents=True, exist_ok=True)

                # Determine which script is primary (gets simplified name)
                source_pkg_dir = scripts[0][1].parent
                primary_script_name = determine_primary_script(scripts, source_pkg_dir)

                # Build rename map for all scripts
                rename_map = {}
                aggressive_name = normalize_package_name(package_name)

                # Migrate each script
                for script_rel_path, script_path, row in scripts:
                    stats.total += 1

                    # Primary script gets simplified name, others keep original
                    if script_path.name == primary_script_name:
                        output_filename = strip_distro_suffix(script_path.name)
                    else:
                        output_filename = script_path.name  # Keep original name

                    output_path = out_subdir / output_filename
                    rename_map[script_path.name] = output_filename

                    success, msg = migrate_script(
                        script_path, output_path, templates_dir,
                        language_override, dry_run, force, verbose,
                        version_matcher,
                    )
                    if success:
                        stats.migrated += 1

                        # Collect mapping info for advanced_mapping.csv
                        try:
                            content = script_path.read_text(encoding='utf-8', errors='replace')
                            meta = extract_metadata(content, script_path.parent.name)
                            lang = detect_language(content, language_override)
                        except Exception:
                            meta = ScriptMetadata()
                            lang = "unknown"

                        is_primary = "PRIMARY" if script_path.name == primary_script_name else ""
                        mapping_entries.append({
                            # Standard columns
                            'package_name': package_name,
                            'package_version': meta.package_version or "",
                            'language': lang,
                            'language_version': "",
                            'script_path': script_rel_path,
                            'package_url': meta.package_url or "",
                            'download_url': "",
                            # Additional columns
                            'output_filename': output_filename,
                            'output_dir': str(out_subdir.relative_to(output_dir)) if out_subdir != output_dir else "",
                            'is_primary': is_primary,
                        })
                    elif msg in ["Already migrated", "Output exists"]:
                        stats.skipped += 1
                    else:
                        stats.failed += 1

                # Copy package assets ONCE per package (after all scripts migrated)
                copy_package_assets(
                    source_pkg_dir, out_subdir, rename_map,
                    stats, dry_run, verbose
                )
        else:
            # Plain text file, one path per line
            for line in f:
                line = line.strip()
                if not line or line.startswith('#'):
                    continue

                script_rel_path = line

                # Strip "build-scripts/" prefix if present
                if script_rel_path.startswith("build-scripts/"):
                    script_rel_path = script_rel_path[len("build-scripts/"):]

                # Resolve path relative to base_dir
                if script_rel_path.startswith('/'):
                    script_path = Path(script_rel_path)
                else:
                    script_path = base_dir / script_rel_path

                if not script_path.exists():
                    log_warn(f"File not found: {script_path}")
                    continue

                if not script_path.is_file():
                    log_warn(f"Not a file (is a directory?): {script_path}")
                    continue

                stats.total += 1

                # Preserve directory structure in output (same as CSV processing)
                rel_parts = script_rel_path.split('/')
                if len(rel_parts) >= 2:
                    # Use first-letter/package-name structure
                    out_subdir = output_dir / rel_parts[0] / rel_parts[1]
                else:
                    out_subdir = output_dir

                if not dry_run:
                    out_subdir.mkdir(parents=True, exist_ok=True)

                # Output filename: strip distro suffix (same as CSV processing)
                output_filename = strip_distro_suffix(script_path.name)
                output_path = out_subdir / output_filename

                success, msg = migrate_script(
                    script_path, output_path, templates_dir,
                    language_override, dry_run, force, verbose,
                    version_matcher,
                )
                if success:
                    stats.migrated += 1

                    # Copy package assets (build_info.json, LICENSE, patches)
                    source_pkg_dir = script_path.parent
                    rename_map = {script_path.name: output_filename}
                    copy_package_assets(
                        source_pkg_dir, out_subdir, rename_map,
                        stats, dry_run, verbose
                    )

                    # Collect mapping info
                    try:
                        content = script_path.read_text(encoding='utf-8', errors='replace')
                        meta = extract_metadata(content, script_path.parent.name)
                        lang = detect_language(content, language_override)
                    except Exception:
                        meta = ScriptMetadata()
                        lang = "unknown"

                    # Derive package name from directory
                    pkg_name = rel_parts[1] if len(rel_parts) >= 2 else script_path.stem
                    mapping_entries.append({
                        # Standard columns
                        'package_name': pkg_name,
                        'package_version': meta.package_version or "",
                        'language': lang,
                        'language_version': "",
                        'script_path': script_rel_path,
                        'package_url': meta.package_url or "",
                        'download_url': "",
                        # Additional columns
                        'output_filename': output_filename,
                        'output_dir': str(out_subdir.relative_to(output_dir)) if out_subdir != output_dir else "",
                        'is_primary': "PRIMARY",  # .list files have one script per entry
                    })
                elif msg in ["Already migrated", "Output exists"]:
                    stats.skipped += 1
                else:
                    stats.failed += 1

    return mapping_entries


# =============================================================================
# REPORT GENERATION
# =============================================================================

def generate_report(
    report_path: Path,
    stats: MigrationStats,
    scan_results: Optional[list[ScriptAnalysis]] = None,
    output_dir: Path = None,
) -> None:
    """Generate migration report"""
    log_info(f"Generating report: {report_path}")

    report_path.parent.mkdir(parents=True, exist_ok=True)

    with open(report_path, "w", encoding="utf-8") as f:
        f.write("# Migration Report\n\n")
        f.write(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n")

        f.write("## Summary\n\n")
        f.write("| Metric | Count |\n")
        f.write("|--------|-------|\n")
        f.write(f"| Total Scripts | {stats.total} |\n")
        f.write(f"| Migrated | {stats.migrated} |\n")
        f.write(f"| Skipped | {stats.skipped} |\n")
        f.write(f"| Failed | {stats.failed} |\n\n")

        if scan_results:
            f.write("## Scan Results\n\n")
            f.write("| Script | Language | Complexity | Status | Distro |\n")
            f.write("|--------|----------|------------|--------|--------|\n")
            for analysis in scan_results:
                status = "migrated" if analysis.already_migrated else "pending"
                f.write(f"| {analysis.path.name} | {analysis.language} | "
                       f"{analysis.complexity} | {status} | {analysis.packages.detected_distro} |\n")

        f.write("""
## Recommendations

1. **Simple migrations**: Can be applied automatically
2. **Complex migrations**: Require manual review for:
   - Patch files
   - sed/awk workarounds
   - Custom build steps
3. **Incomplete metadata**: Missing PACKAGE_NAME or PACKAGE_URL

## Next Steps

1. Review migrated scripts in the output directory
2. Test migrated scripts in development environment
3. Compare output with original scripts
4. Deploy approved migrations to production
""")

    log_success(f"Report generated: {report_path}")


def write_advanced_mapping(
    mapping_path: Path,
    mapping_entries: list[dict],
) -> None:
    """Write advanced_mapping.csv with detailed mapping information.

    Columns (standard columns first, then additional):
        package_name, package_version, language, language_version, script_path,
        package_url, download_url, output_filename, output_dir, is_primary
    """
    import csv

    log_info(f"Writing advanced mapping: {mapping_path}")

    mapping_path.parent.mkdir(parents=True, exist_ok=True)

    fieldnames = [
        # Standard columns (match filter_candidates.py output)
        'package_name',
        'package_version',
        'language',
        'language_version',
        'script_path',
        'package_url',
        'download_url',
        # Additional columns specific to migration mapping
        'output_filename',
        'output_dir',
        'is_primary',
    ]

    with open(mapping_path, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames, quoting=csv.QUOTE_ALL)
        writer.writeheader()
        writer.writerows(mapping_entries)

    log_success(f"Advanced mapping written: {mapping_path} ({len(mapping_entries)} entries)")


# =============================================================================
# MAIN
# =============================================================================

def main() -> int:
    parser = argparse.ArgumentParser(
        description="Migrate existing build scripts to use the standardized template format.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "target",
        nargs="?",
        type=Path,
        help="Script or directory to migrate",
    )
    parser.add_argument(
        "-b", "--base",
        type=Path,
        help="Old build-scripts source tree (required for --batch)",
    )
    parser.add_argument(
        "-d", "--dest",
        type=Path,
        default=Path("./migrated_scripts"),
        help="Destination for generated scripts (default: ./migrated_scripts)",
    )
    parser.add_argument(
        "--template-dir",
        type=Path,
        help="V2 templates location (default: ../templates/ relative to tool)",
    )
    parser.add_argument(
        "-l", "--language",
        help="Override language detection",
    )
    parser.add_argument(
        "-r", "--report",
        action="store_true",
        help="Generate detailed migration report",
    )
    parser.add_argument(
        "-n", "--dry-run",
        action="store_true",
        help="Show what would be done without making changes",
    )
    parser.add_argument(
        "-f", "--force",
        action="store_true",
        help="Overwrite existing migrated scripts",
    )
    parser.add_argument(
        "-v", "--verbose",
        action="store_true",
        help="Verbose output",
    )
    parser.add_argument(
        "--scan",
        action="store_true",
        help="Scan and report only, don't migrate",
    )
    parser.add_argument(
        "--batch",
        type=Path,
        help="Batch file (.csv or .list) with scripts to migrate (paths relative to --base)",
    )
    parser.add_argument(
        "--mapping-output",
        type=Path,
        help="Output path for advanced_mapping.csv (default: {dest}/templates/template-tools/advanced_mapping.csv)",
    )
    parser.add_argument(
        "--version-data",
        type=Path,
        help="Directory containing version data JSON files (default: ./version_data)",
    )
    parser.add_argument(
        "--no-version-fix",
        action="store_true",
        help="Disable automatic version correction from registry data",
    )

    args = parser.parse_args()

    # Validate arguments
    if not args.target and not args.batch:
        log_error("No target path or batch file specified")
        parser.print_help()
        return 1

    if args.batch and not args.base:
        log_error("--base is required when using --batch")
        return 1

    # Resolve directories
    script_dir = Path(__file__).parent.resolve()

    # Templates directory: --template-dir or auto-detect based on directory structure
    # Supports both:
    #   - Current: template-tools/ as sibling of templates/ (../templates/)
    #   - Future:  template-tools/ inside templates/       (../)
    if args.template_dir:
        templates_dir = args.template_dir.resolve()
    else:
        # Try sibling structure first (current)
        sibling_templates = (script_dir / ".." / "templates").resolve()
        # Try parent structure (future, when template-tools is inside templates/)
        parent_templates = script_dir.parent.resolve()

        if sibling_templates.exists() and (sibling_templates / "lib").exists():
            templates_dir = sibling_templates
        elif (parent_templates / "lib").exists():
            templates_dir = parent_templates
        else:
            templates_dir = sibling_templates  # Fall back for error message

    if not templates_dir.exists() or not (templates_dir / "lib").exists():
        log_error(f"Templates lib directory not found: {templates_dir}/lib")
        log_error("Use --template-dir to specify the V2 templates directory")
        return 1

    # Base directory for old scripts (required for batch mode)
    base_dir = args.base.resolve() if args.base else None

    # Initialize version matcher (if enabled)
    version_matcher = None
    if not args.no_version_fix:
        from .version_matcher import VersionMatcher
        version_data_dir = args.version_data if args.version_data else script_dir / "version_data"
        if version_data_dir.exists():
            version_matcher = VersionMatcher(version_data_dir, base_dir=base_dir)
            log_info(f"Version matching enabled (data: {version_data_dir})")
        else:
            log_warn(f"Version data directory not found: {version_data_dir}")
            log_warn("Version matching disabled (use --version-data to specify)")

    # Initialize stats
    stats = MigrationStats()
    scan_results = []
    mapping_entries = []

    # Print scan header
    if args.scan:
        print()
        print(f"{'Script':<60} | {'Language':<8} | {'Complexity':<10} | {'Status':<10} | Distro")
        print("-" * 110)

    # Copy templates and template-tools to destination for batch mode
    if args.batch and not args.scan:
        copy_templates_to_dest(templates_dir, args.dest, args.dry_run, args.verbose)
        copy_template_tools_to_dest(script_dir, args.dest, args.dry_run, args.verbose)

    # Process based on input type
    if args.batch:
        mapping_entries = process_batch_file(
            args.batch, base_dir, args.dest, templates_dir, stats,
            args.language, args.dry_run, args.force, args.verbose,
            version_matcher,
        )
    elif args.target.is_dir():
        scan_results = process_directory(
            args.target, args.dest, templates_dir, stats,
            args.scan, args.language, args.dry_run, args.force, args.verbose,
            version_matcher,
        )
        # Print scan results
        if args.scan:
            for analysis in scan_results:
                status = "migrated" if analysis.already_migrated else "pending"
                print(f"{analysis.path.name:<60} | {analysis.language:<8} | "
                      f"{analysis.complexity:<10} | {status:<10} | {analysis.packages.detected_distro}")
    elif args.target.is_file():
        stats.total = 1
        if args.scan:
            analysis = scan_script(args.target, args.language, args.verbose)
            if analysis:
                scan_results.append(analysis)
                status = "migrated" if analysis.already_migrated else "pending"
                print(f"{analysis.path.name:<60} | {analysis.language:<8} | "
                      f"{analysis.complexity:<10} | {status:<10} | {analysis.packages.detected_distro}")
        else:
            output_path = args.dest / args.target.name
            success, msg = migrate_script(
                args.target, output_path, templates_dir,
                args.language, args.dry_run, args.force, args.verbose,
                version_matcher,
            )
            if success:
                stats.migrated += 1
            elif msg in ["Already migrated", "Output exists"]:
                stats.skipped += 1
            else:
                stats.failed += 1
    else:
        log_error(f"Target not found: {args.target}")
        return 1

    # Print summary
    print()
    log_info("=== Migration Summary ===")
    log_info(f"Total scripts:      {stats.total}")
    log_info(f"Migrated:           {stats.migrated}")
    log_info(f"Skipped:            {stats.skipped}")
    log_info(f"Failed:             {stats.failed}")
    log_info(f"Assets copied:      {stats.assets_copied}")
    log_info(f"build_info updated: {stats.build_info_updated}")

    # Generate report if requested
    if args.report:
        if args.dry_run:
            # In dry-run mode, put report in current directory
            report_path = Path("./migration_report.md")
        else:
            report_path = args.dest / "templates" / "template-tools" / "migration_report.md"
        generate_report(report_path, stats, scan_results if args.scan else None, args.dest)

    # Write advanced mapping CSV (always, for batch mode)
    if mapping_entries:
        if args.mapping_output:
            mapping_path = args.mapping_output
        elif args.dry_run:
            mapping_path = Path("./advanced_mapping.csv")
        else:
            mapping_path = args.dest / "templates" / "template-tools" / "advanced_mapping.csv"
        write_advanced_mapping(mapping_path, mapping_entries)

    # Write version warnings file if there are any
    if version_matcher and version_matcher.warnings:
        if args.dry_run:
            warnings_path = Path("./version_warnings.txt")
        else:
            warnings_path = args.dest / "templates" / "template-tools" / "version_warnings.txt"
        warnings_count = version_matcher.write_warnings(warnings_path)
        log_warn(f"Version warnings: {warnings_count} unconfirmed versions (see {warnings_path})")

    # Write github_tags_missing file if there are any
    if version_matcher and version_matcher.github_tags_missing:
        if args.dry_run:
            missing_path = Path("./github_tags_missing.csv")
        else:
            missing_path = args.dest / "templates" / "template-tools" / "github_tags_missing.csv"
        missing_count = version_matcher.write_github_tags_missing(missing_path)
        log_warn(f"GitHub tags missing: {missing_count} packages not in github_tags_mapping.json (see {missing_path})")

    return 1 if stats.failed > 0 else 0


if __name__ == "__main__":
    sys.exit(main())
