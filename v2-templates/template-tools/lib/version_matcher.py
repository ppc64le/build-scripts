#!/usr/bin/env python3
"""
version_matcher.py - Fuzzy version matching for build script migration

This module validates and corrects PACKAGE_VERSION values during migration
by matching against official versions from package registries.

Usage:
    from version_matcher import VersionMatcher

    matcher = VersionMatcher(Path("./version_data"))
    result = matcher.match_version(
        package_name="express",
        input_version="4.18",
        language="node",
        package_url="https://github.com/expressjs/express"
    )
    print(result.matched_version)  # "4.18.0"
"""

import json
import re
from dataclasses import dataclass, field
from pathlib import Path
from typing import Optional

# Import CSV normalizer for standardized output
from .csv_normalizer import (
    create_empty_row,
    write_normalized_csv,
    ColumnMapping,
    STANDARD_COLUMNS,
)

# Import version substitution tracker
from .version_substitution_tracker import (
    VersionSubstitutionTracker,
    SubstitutionResult,
)


# =============================================================================
# CONFIGURATION
# =============================================================================

# Map language names to version data files
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

# Fallback for packages not found in primary registry
FALLBACK_VERSION_FILE = "github_tags_mapping.json"


# =============================================================================
# DATA CLASSES
# =============================================================================

@dataclass
class VersionMatchResult:
    """Result of a version matching attempt"""
    matched_version: Optional[str] = None  # The best matching official version
    confidence: str = "none"               # "exact", "normalized", "prefix", "fuzzy", "substituted", "none"
    registry_package_name: str = ""        # Actual name in registry (may differ)
    original_version: str = ""             # The input version
    message: str = ""                      # Human-readable explanation
    available_tags: str = ""               # PACKAGE_AVAILABLE_TAGS line for build script

    @property
    def confirmed(self) -> bool:
        """Returns True if a version was successfully matched"""
        return self.matched_version is not None and self.confidence != "none"

    @property
    def was_substituted(self) -> bool:
        """Returns True if version was substituted (original not available)"""
        return self.confidence == "substituted"


@dataclass
class VersionWarning:
    """Warning for unconfirmed version"""
    package_name: str
    script_path: str
    input_version: str
    language: str
    reason: str


@dataclass
class GitHubTagsMissing:
    """Warning for package not found in github_tags_mapping.json"""
    package_name: str
    script_path: str
    language: str
    registry_version: str  # Version found in primary registry
    package_url: str       # URL if available, for debugging


# =============================================================================
# VERSION MATCHER
# =============================================================================

class VersionMatcher:
    """
    Matches package versions against official registry versions.

    Supports fuzzy matching strategies:
    1. Exact match
    2. v-prefix normalization (1.2.3 <-> v1.2.3)
    3. Trailing zero completion (1.2 -> 1.2.0)
    4. Prefix matching (1.2 -> latest 1.2.x)
    5. Major version matching (1 -> latest 1.x.x)
    """

    def __init__(self, version_data_dir: Path, base_dir: Path = None,
                 enable_substitution: bool = True, tag_separator: str = ","):
        self.version_data_dir = Path(version_data_dir)
        self.base_dir = Path(base_dir) if base_dir else None  # Base directory for relative paths
        self._cache: dict[str, dict] = {}  # Lazy-loaded version data per language
        self._build_info_index: dict[str, dict] = {}  # Index by base_dir
        self._url_index: dict[str, dict] = {}  # Index by repository URL
        self.warnings: list[VersionWarning] = []
        self.github_tags_missing: list[GitHubTagsMissing] = []  # Packages not in github_tags

        # Version substitution tracking
        self.enable_substitution = enable_substitution
        self.substitution_tracker = VersionSubstitutionTracker(
            output_dir=version_data_dir.parent if version_data_dir else Path("."),
            tag_separator=tag_separator
        ) if enable_substitution else None

    def _load_version_data(self, language: str) -> dict:
        """Load version data for a language, with caching"""
        if language in self._cache:
            return self._cache[language]

        version_file = LANGUAGE_VERSION_FILES.get(language.lower())
        if not version_file:
            return {}

        version_path = self.version_data_dir / version_file
        if not version_path.exists():
            return {}

        try:
            with open(version_path, 'r', encoding='utf-8') as f:
                data = json.load(f)
            self._cache[language] = data
            self._build_indexes(data, language)
            return data
        except (json.JSONDecodeError, IOError) as e:
            print(f"Warning: Failed to load {version_path}: {e}")
            return {}

    def _build_indexes(self, data: dict, language: str) -> None:
        """Build indexes for faster package lookup"""
        for pkg_name, pkg_data in data.items():
            # Index by build_script_info.base_dir
            if isinstance(pkg_data, dict):
                build_info = pkg_data.get('build_script_info', {})
                if build_info:
                    base_dir = build_info.get('base_dir', '')
                    if base_dir:
                        self._build_info_index[base_dir.lower()] = {
                            'package_name': pkg_name,
                            'data': pkg_data,
                            'language': language
                        }

                # Index by repository URL
                repo = pkg_data.get('repository', {})
                if isinstance(repo, dict):
                    url = repo.get('url', '')
                    if url:
                        # Normalize URL for matching
                        normalized_url = self._normalize_url(url)
                        self._url_index[normalized_url] = {
                            'package_name': pkg_name,
                            'data': pkg_data,
                            'language': language
                        }

                # Also index by github_url for Go packages
                github_url = pkg_data.get('github_url', '')
                if github_url:
                    normalized_url = self._normalize_url(github_url)
                    self._url_index[normalized_url] = {
                        'package_name': pkg_name,
                        'data': pkg_data,
                        'language': language
                    }

    def _normalize_url(self, url: str) -> str:
        """Normalize URL for comparison"""
        url = url.lower().strip()
        # Remove protocol
        url = re.sub(r'^https?://', '', url)
        # Remove .git suffix
        url = re.sub(r'\.git$', '', url)
        # Remove trailing slash
        url = url.rstrip('/')
        # Remove www.
        url = re.sub(r'^www\.', '', url)
        return url

    def _extract_versions(self, pkg_data: dict) -> list[str]:
        """Extract version list from package data (handles different formats)"""
        versions_field = pkg_data.get('versions', [])

        if not versions_field:
            return []

        # Handle list of version strings (Go format)
        if versions_field and isinstance(versions_field[0], str):
            return versions_field

        # Handle list of version objects
        if versions_field and isinstance(versions_field[0], dict):
            # npm/pypi/packagist/maven/ruby format: 'version' field
            if 'version' in versions_field[0]:
                return [v.get('version', '') for v in versions_field if v.get('version')]
            # github_tags format: 'name' field
            elif 'name' in versions_field[0]:
                return [v.get('name', '') for v in versions_field if v.get('name')]

        return []

    def _load_fallback_data(self) -> dict:
        """Load fallback version data (github_tags_mapping.json)"""
        if FALLBACK_VERSION_FILE in self._cache:
            return self._cache[FALLBACK_VERSION_FILE]

        fallback_path = self.version_data_dir / FALLBACK_VERSION_FILE
        if not fallback_path.exists():
            self._cache[FALLBACK_VERSION_FILE] = {}
            return {}

        try:
            with open(fallback_path, 'r', encoding='utf-8') as f:
                data = json.load(f)
            self._cache[FALLBACK_VERSION_FILE] = data
            return data
        except (json.JSONDecodeError, IOError):
            self._cache[FALLBACK_VERSION_FILE] = {}
            return {}

    def _find_in_data(
        self,
        data: dict,
        package_name: str,
        package_url: str = ""
    ) -> tuple[Optional[str], Optional[dict]]:
        """
        Search for package in a single data dict using all strategies.

        Returns (registry_package_name, package_data) or (None, None)
        """
        if not data:
            return None, None

        pkg_name_lower = package_name.lower()

        # Strategy 1: Exact match (case-insensitive key search)
        for key in data.keys():
            if key.lower() == pkg_name_lower:
                return key, data[key]

        # Strategy 2: Transform __ to / (for PHP-style packages)
        if '__' in package_name:
            transformed = package_name.replace('__', '/')
            for key in data.keys():
                if key.lower() == transformed.lower():
                    return key, data[key]

        # Strategy 3: Match by original_input field (contains build script path)
        for key, pkg_data in data.items():
            if not isinstance(pkg_data, dict):
                continue
            original_input = pkg_data.get('original_input', '')
            if original_input:
                # Check if package name appears in the original input path
                if f"/{package_name}/" in original_input or f"/{package_name}," in original_input:
                    return key, pkg_data
                # Also try with __ to / conversion for PHP packages
                if '__' in package_name:
                    clean_name = package_name.replace('__', '/')
                    if f"/{clean_name}/" in original_input or clean_name in original_input:
                        return key, pkg_data

        # Strategy 4: Match by build_script_info.base_dir
        if pkg_name_lower in self._build_info_index:
            entry = self._build_info_index[pkg_name_lower]
            return entry['package_name'], entry['data']

        # Strategy 5: Match by repository URL
        if package_url:
            normalized_url = self._normalize_url(package_url)
            if normalized_url in self._url_index:
                entry = self._url_index[normalized_url]
                return entry['package_name'], entry['data']
            # Also search directly in data for github_url matches
            for key, pkg_data in data.items():
                if not isinstance(pkg_data, dict):
                    continue
                github_url = pkg_data.get('github_url', '')
                if github_url and self._normalize_url(github_url) == normalized_url:
                    return key, pkg_data
                # Check source URL in version entries
                versions = pkg_data.get('versions', [])
                if versions and isinstance(versions[0], dict):
                    source = versions[0].get('source', {})
                    if isinstance(source, dict):
                        source_url = source.get('url', '')
                        if source_url and normalized_url in self._normalize_url(source_url):
                            return key, pkg_data

        # Strategy 6: Try common transformations
        transformations = [
            pkg_name_lower,
            pkg_name_lower.replace('-', '_'),
            pkg_name_lower.replace('_', '-'),
            re.sub(r'^python-', '', pkg_name_lower),
            re.sub(r'^py-', '', pkg_name_lower),
            re.sub(r'^node-', '', pkg_name_lower),
            re.sub(r'^go-', '', pkg_name_lower),
            re.sub(r'^php-', '', pkg_name_lower),
        ]

        for transformed in transformations:
            for key in data.keys():
                if key.lower() == transformed:
                    return key, data[key]

        return None, None

    def _find_package(
        self,
        package_name: str,
        language: str,
        package_url: str = ""
    ) -> tuple[Optional[str], Optional[dict]]:
        """
        Find package in version data using multiple strategies.

        First searches the language-specific version file, then falls back
        to github_tags_mapping.json if not found.

        Returns (registry_package_name, package_data) or (None, None)
        """
        # Try primary version data for this language
        data = self._load_version_data(language)
        result = self._find_in_data(data, package_name, package_url)
        if result[0] is not None:
            return result

        # Try fallback (github_tags_mapping.json)
        fallback_data = self._load_fallback_data()
        return self._find_in_data(fallback_data, package_name, package_url)

    def _normalize_version(self, version: str) -> str:
        """Normalize version string for comparison"""
        v = version.strip()
        # Remove 'v' or 'V' prefix
        if v.lower().startswith('v'):
            v = v[1:]
        return v

    def _versions_match(self, input_ver: str, registry_ver: str) -> bool:
        """Check if two versions match after normalization"""
        return self._normalize_version(input_ver) == self._normalize_version(registry_ver)

    def _version_starts_with(self, registry_ver: str, prefix: str) -> bool:
        """Check if registry version starts with prefix (after normalization)"""
        norm_reg = self._normalize_version(registry_ver)
        norm_pre = self._normalize_version(prefix)

        # Exact prefix match
        if norm_reg.startswith(norm_pre):
            # Make sure we're matching complete version components
            # e.g., "1.2" should match "1.2.0" but not "1.20.0"
            remaining = norm_reg[len(norm_pre):]
            return not remaining or remaining.startswith('.')

        return False

    def _parse_semver(self, version: str) -> tuple[int, int, int, str]:
        """Parse version into (major, minor, patch, prerelease) for sorting"""
        v = self._normalize_version(version)

        # Handle prerelease/metadata
        prerelease = ""
        if '-' in v:
            v, prerelease = v.split('-', 1)
        if '+' in v:
            v = v.split('+')[0]

        parts = v.split('.')
        try:
            major = int(parts[0]) if len(parts) > 0 and parts[0].isdigit() else 0
            minor = int(parts[1]) if len(parts) > 1 and parts[1].isdigit() else 0
            patch = int(parts[2]) if len(parts) > 2 and parts[2].isdigit() else 0
        except (ValueError, IndexError):
            major, minor, patch = 0, 0, 0

        return (major, minor, patch, prerelease)

    def _find_best_prefix_match(
        self,
        versions: list[str],
        prefix: str,
        prefer_exact_patch: bool = True
    ) -> Optional[str]:
        """
        Find the best version matching a prefix.

        For prefix "1.2", prefers "1.2.0" over "1.2.5" if prefer_exact_patch is True.
        Otherwise returns the latest matching version.
        """
        matches = [v for v in versions if self._version_starts_with(v, prefix)]
        if not matches:
            return None

        # Parse prefix to get expected patch
        norm_prefix = self._normalize_version(prefix)
        prefix_parts = norm_prefix.split('.')

        if prefer_exact_patch and len(prefix_parts) == 2:
            # Looking for x.y -> prefer x.y.0
            target = f"{prefix_parts[0]}.{prefix_parts[1]}.0"
            for v in matches:
                if self._versions_match(v, target):
                    return v

        # Sort by semver and return latest
        matches.sort(key=self._parse_semver, reverse=True)
        return matches[0]

    def _get_github_tag_version(
        self,
        package_name: str,
        matched_version: str,
        package_url: str = ""
    ) -> Optional[str]:
        """
        Look up the GitHub tag format for a matched version.

        Since PACKAGE_VERSION is used for git checkout, we prefer the actual
        GitHub tag format (which often includes 'v' prefix) over the registry
        format (which often strips it).

        Args:
            package_name: Package name
            matched_version: Version matched from registry (e.g., "1.2.0")
            package_url: Optional URL for disambiguation

        Returns:
            GitHub tag version if found (e.g., "v1.2.0"), None otherwise
        """
        github_data = self._load_fallback_data()
        if not github_data:
            return None

        # Find package in github_tags_mapping.json
        github_name, github_pkg = self._find_in_data(github_data, package_name, package_url)
        if not github_pkg:
            return None

        # Extract GitHub tag versions
        github_versions = self._extract_versions(github_pkg)
        if not github_versions:
            return None

        # Find the GitHub tag that matches our registry version
        norm_matched = self._normalize_version(matched_version)
        for gv in github_versions:
            if self._normalize_version(gv) == norm_matched:
                return gv

        return None

    def _get_available_github_tags(
        self,
        package_name: str,
        package_url: str = ""
    ) -> list[str]:
        """
        Get all available GitHub tags for a package.

        Args:
            package_name: Package name
            package_url: Optional URL for disambiguation

        Returns:
            List of available tag names (newest first), or empty list
        """
        github_data = self._load_fallback_data()
        if not github_data:
            return []

        github_name, github_pkg = self._find_in_data(github_data, package_name, package_url)
        if not github_pkg:
            return []

        return self._extract_versions(github_pkg)

    def match_version(
        self,
        package_name: str,
        input_version: str,
        language: str,
        package_url: str = "",
        script_path: str = ""
    ) -> VersionMatchResult:
        """
        Match input version against official registry versions.

        Args:
            package_name: Package name from build script
            input_version: Version string from build script (may be imprecise)
            language: Programming language (python, node, go, etc.)
            package_url: Optional GitHub/repository URL for disambiguation
            script_path: Optional script path for warning reports

        Returns:
            VersionMatchResult with matched version and confidence level
        """
        result = VersionMatchResult(
            original_version=input_version,
            message="",
        )

        if not input_version:
            result.message = "No input version provided"
            return result

        # Find package in version data
        registry_name, pkg_data = self._find_package(package_name, language, package_url)

        if not pkg_data:
            result.message = f"Package '{package_name}' not found in {language} version data"
            self._add_warning(package_name, script_path, input_version, language, result.message)
            return result

        result.registry_package_name = registry_name or package_name

        # Extract version list
        versions = self._extract_versions(pkg_data)
        if not versions:
            result.message = f"No versions found for package '{registry_name}'"
            self._add_warning(package_name, script_path, input_version, language, result.message)
            return result

        # Strategy 1: Exact match
        for v in versions:
            if v == input_version:
                result.matched_version = v
                result.confidence = "exact"
                result.message = "Exact match"
                # Try to get GitHub tag format
                result = self._apply_github_tag_format(result, package_name, package_url, script_path, language)
                return result

        # Strategy 2: v-prefix normalization
        for v in versions:
            if self._versions_match(input_version, v):
                result.matched_version = v
                result.confidence = "normalized"
                result.message = f"Normalized match (v-prefix): {input_version} -> {v}"
                # Try to get GitHub tag format
                result = self._apply_github_tag_format(result, package_name, package_url, script_path, language)
                return result

        # Strategy 3: Trailing zero completion (1.2 -> 1.2.0)
        norm_input = self._normalize_version(input_version)
        input_parts = norm_input.split('.')

        if len(input_parts) == 2:
            # Try x.y.0
            target = f"{input_parts[0]}.{input_parts[1]}.0"
            for v in versions:
                if self._versions_match(v, target):
                    result.matched_version = v
                    result.confidence = "normalized"
                    result.message = f"Trailing zero completion: {input_version} -> {v}"
                    # Try to get GitHub tag format
                    result = self._apply_github_tag_format(result, package_name, package_url, script_path, language)
                    return result

        # Strategy 4: Prefix matching (1.2 -> latest 1.2.x)
        prefix_match = self._find_best_prefix_match(versions, input_version, prefer_exact_patch=True)
        if prefix_match:
            result.matched_version = prefix_match
            result.confidence = "prefix"
            result.message = f"Prefix match: {input_version} -> {prefix_match}"
            # Try to get GitHub tag format
            result = self._apply_github_tag_format(result, package_name, package_url, script_path, language)
            return result

        # Strategy 5: Major version matching (1 -> latest 1.x.x)
        if len(input_parts) == 1 and input_parts[0].isdigit():
            major_match = self._find_best_prefix_match(versions, input_version, prefer_exact_patch=False)
            if major_match:
                result.matched_version = major_match
                result.confidence = "fuzzy"
                result.message = f"Major version match: {input_version} -> {major_match}"
                # Try to get GitHub tag format
                result = self._apply_github_tag_format(result, package_name, package_url, script_path, language)
                return result

        # Strategy 6: Find version containing input (for unusual formats)
        for v in versions:
            if norm_input in self._normalize_version(v):
                result.matched_version = v
                result.confidence = "fuzzy"
                result.message = f"Contains match: {input_version} found in {v}"
                # Try to get GitHub tag format
                result = self._apply_github_tag_format(result, package_name, package_url, script_path, language)
                return result

        # No match found
        result.message = f"No matching version found for '{input_version}' (package has {len(versions)} versions)"
        self._add_warning(package_name, script_path, input_version, language, result.message)
        return result

    def _apply_github_tag_format(
        self,
        result: VersionMatchResult,
        package_name: str,
        package_url: str = "",
        script_path: str = "",
        language: str = ""
    ) -> VersionMatchResult:
        """
        Convert matched version to GitHub tag format if available.

        Since PACKAGE_VERSION is used for git checkout, we prefer the actual
        GitHub tag format over the registry format.

        If the version is not found in available GitHub tags and substitution
        is enabled, substitutes with the newest available version.
        """
        if not result.matched_version:
            return result

        github_tag = self._get_github_tag_version(
            package_name,
            result.matched_version,
            package_url
        )

        if github_tag and github_tag != result.matched_version:
            original_match = result.matched_version
            result.matched_version = github_tag
            result.message += f" (using GitHub tag format: {original_match} -> {github_tag})"
        elif github_tag is None:
            # Version not found in github_tags_mapping.json
            # Try substitution if enabled
            available_tags = self._get_available_github_tags(package_name, package_url)

            if self.enable_substitution and self.substitution_tracker and available_tags:
                sub_result = self.substitution_tracker.check_and_substitute(
                    package_name=package_name,
                    original_version=result.matched_version,
                    available_tags=available_tags,
                    language=language,
                    script_path=script_path,
                    package_url=package_url
                )

                if sub_result.was_substituted:
                    result.matched_version = sub_result.final_version
                    result.confidence = "substituted"
                    result.message += f" {sub_result.comment}"
                    result.available_tags = sub_result.available_tags_line
                else:
                    # Version was found in available tags
                    result.available_tags = sub_result.available_tags_line
            else:
                # No substitution - log for investigation
                self.github_tags_missing.append(GitHubTagsMissing(
                    package_name=package_name,
                    script_path=script_path,
                    language=language,
                    registry_version=result.matched_version,
                    package_url=package_url,
                ))

        return result

    def _add_warning(
        self,
        package_name: str,
        script_path: str,
        input_version: str,
        language: str,
        reason: str
    ) -> None:
        """Add a warning for unconfirmed version"""
        self.warnings.append(VersionWarning(
            package_name=package_name,
            script_path=script_path or "",
            input_version=input_version,
            language=language,
            reason=reason
        ))

    def write_warnings(self, output_path: Path) -> int:
        """
        Write warnings to file.

        Returns number of warnings written.
        """
        if not self.warnings:
            return 0

        output_path.parent.mkdir(parents=True, exist_ok=True)

        with open(output_path, 'w', encoding='utf-8') as f:
            f.write("# Version Matching Warnings\n")
            f.write(f"# Total: {len(self.warnings)} unconfirmed versions\n")
            f.write("#\n")
            f.write("# Format: package_name,script_path,input_version,language,reason\n")
            f.write("#\n\n")

            for w in self.warnings:
                # Escape commas in reason
                reason = w.reason.replace(',', ';')
                f.write(f"{w.package_name},{w.script_path},{w.input_version},{w.language},{reason}\n")

        return len(self.warnings)

    def write_github_tags_missing(self, output_path: Path) -> int:
        """
        Write github_tags_missing entries to file using csv_normalizer.

        These are packages found in primary registry but NOT in github_tags_mapping.json.
        This may indicate:
        - Missing data in github_tags_mapping.json
        - Repository was archived or removed
        - Incorrect clone location

        Output format is compatible with version_fetchers/fetch_github_tags.py --input csv
        and uses the standardized CSV format from csv_normalizer.

        Returns number of entries written.
        """
        if not self.github_tags_missing:
            return 0

        output_path = Path(output_path)
        output_path.parent.mkdir(parents=True, exist_ok=True)

        # Deduplicate by package_name (same package may be processed multiple times)
        seen = set()
        unique_missing = []
        for m in self.github_tags_missing:
            if m.package_name not in seen:
                seen.add(m.package_name)
                unique_missing.append(m)

        # Build rows using csv_normalizer's standard format
        rows = []
        for m in unique_missing:
            # Make script_path relative to base_dir if possible
            script_path = self._make_relative_path(m.script_path)

            # Create row with standard columns
            row = create_empty_row()
            row["package_name"] = m.package_name
            row["package_version"] = m.registry_version
            row["language"] = m.language
            row["script_path"] = script_path
            row["package_url"] = m.package_url or ""
            row["status"] = "pending"
            rows.append(row)

        # Write header comment manually, then use normalizer for data
        with open(output_path, 'w', encoding='utf-8') as f:
            f.write("# Packages missing from github_tags_mapping.json\n")
            if self.base_dir:
                try:
                    rel_base = self.base_dir.relative_to(Path.cwd())
                except ValueError:
                    rel_base = self.base_dir.name
                f.write(f"# Script paths are relative to --base directory: {rel_base}/\n")
            f.write("#\n")

        # Use csv_normalizer to write in standard format (append mode)
        # We skip the original headers since this is generated data, not normalized input
        write_normalized_csv(
            rows,
            output_path,
            include_original_headers=False,
            include_mapping_file=False
        )

        # Prepend the comment header (read, prepend, write)
        with open(output_path, 'r', encoding='utf-8') as f:
            csv_content = f.read()

        with open(output_path, 'w', encoding='utf-8') as f:
            f.write("# Packages missing from github_tags_mapping.json\n")
            if self.base_dir:
                try:
                    rel_base = self.base_dir.relative_to(Path.cwd())
                except ValueError:
                    rel_base = self.base_dir.name
                f.write(f"# Script paths are relative to --base directory: {rel_base}/\n")
            f.write("#\n")
            f.write(csv_content)

        return len(unique_missing)

    def _make_relative_path(self, script_path: str) -> str:
        """Convert script_path to be relative to base_dir if possible."""
        if not script_path or not self.base_dir:
            return script_path or ""

        try:
            script_p = Path(script_path)
            # Handle absolute paths
            if script_p.is_absolute():
                return str(script_p.relative_to(self.base_dir))

            # Handle relative paths that might include base_dir prefix
            try:
                rel_base = str(self.base_dir.relative_to(Path.cwd()))
                if script_path.startswith(rel_base + '/'):
                    return script_path[len(rel_base) + 1:]
                elif script_path.startswith(rel_base):
                    return script_path[len(rel_base):]
            except ValueError:
                pass
        except (ValueError, TypeError):
            pass

        return script_path

    def write_substitutions(self, output_path: Path = None) -> int:
        """
        Write version substitutions tracking file.

        Args:
            output_path: Path to write CSV file (default: version_substitutions.csv in output_dir)

        Returns:
            Number of substitutions written.
        """
        if not self.substitution_tracker:
            return 0

        if output_path:
            self.substitution_tracker.output_dir = output_path.parent
            filename = output_path.name
        else:
            filename = "version_substitutions.csv"

        self.substitution_tracker.write_tracking_file(filename)
        return len(self.substitution_tracker.substitutions)

    def print_substitution_summary(self) -> None:
        """Print substitution statistics."""
        if self.substitution_tracker:
            self.substitution_tracker.print_summary()

    def clear_warnings(self) -> None:
        """Clear accumulated warnings and substitutions"""
        self.warnings = []
        self.github_tags_missing = []
        if self.substitution_tracker:
            self.substitution_tracker.substitutions = []
            self.substitution_tracker.stats = {
                "checked": 0,
                "kept_original": 0,
                "substituted": 0,
                "no_tags_available": 0,
            }


# =============================================================================
# CONVENIENCE FUNCTIONS
# =============================================================================

def match_version(
    package_name: str,
    input_version: str,
    language: str,
    version_data_dir: Path,
    package_url: str = ""
) -> VersionMatchResult:
    """
    Convenience function for one-off version matching.

    For batch operations, create a VersionMatcher instance and reuse it.
    """
    matcher = VersionMatcher(version_data_dir)
    return matcher.match_version(package_name, input_version, language, package_url)


# =============================================================================
# CLI FOR TESTING
# =============================================================================

def main():
    """Command-line interface for testing version matching"""
    import argparse

    parser = argparse.ArgumentParser(
        description="Test version matching against registry data"
    )
    parser.add_argument("package_name", help="Package name to look up")
    parser.add_argument("version", help="Version to match")
    parser.add_argument("-l", "--language", required=True,
                       help="Language (python, node, go, php, java, ruby)")
    parser.add_argument("-d", "--data-dir", type=Path,
                       default=Path(__file__).parent / "version_data",
                       help="Version data directory")
    parser.add_argument("-u", "--url", default="",
                       help="Package URL for disambiguation")

    args = parser.parse_args()

    matcher = VersionMatcher(args.data_dir)
    result = matcher.match_version(
        args.package_name,
        args.version,
        args.language,
        args.url
    )

    print(f"Package:          {args.package_name}")
    print(f"Input version:    {args.version}")
    print(f"Language:         {args.language}")
    print(f"---")
    print(f"Matched version:  {result.matched_version or '(none)'}")
    print(f"Confidence:       {result.confidence}")
    print(f"Registry name:    {result.registry_package_name or '(not found)'}")
    print(f"Message:          {result.message}")

    return 0 if result.confirmed else 1


if __name__ == "__main__":
    import sys
    sys.exit(main())
