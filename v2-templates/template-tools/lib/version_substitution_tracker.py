#!/usr/bin/env python3
"""
Version Substitution Tracker

Tracks packages where the original PACKAGE_VERSION was substituted because
it was not found in available GitHub tags (likely >5 years old).

Generates:
1. version_substitutions.csv - Tracking file for investigation
2. Updates to build scripts with PACKAGE_AVAILABLE_TAGS

Usage:
    # As a module - called from version_matcher.py or migrate_to_template.py
    from version_substitution_tracker import VersionSubstitutionTracker

    tracker = VersionSubstitutionTracker(output_dir)
    result = tracker.check_and_substitute(
        package_name="aws-sdk-go-v2",
        original_version="v0.18.0",
        available_tags=["v1.41.1", "v1.41.0", ...],
        language="go",
        script_path="path/to/script.sh",
        package_url="https://github.com/aws/aws-sdk-go-v2"
    )

    # At end of processing
    tracker.write_tracking_file()
"""

import csv
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from typing import Optional


@dataclass
class VersionSubstitution:
    """Record of a version substitution."""
    package_name: str
    original_version: str
    substituted_version: str
    language: str
    script_path: str
    package_url: str
    available_tags_count: int
    available_tags_sample: str  # First 10 tags, semicolon-separated
    substitution_reason: str
    timestamp: str = field(default_factory=lambda: datetime.now().isoformat())

    # For tracking investigation status
    investigation_status: str = "pending"  # pending, assigned, resolved, wont_fix
    assigned_to: str = ""
    notes: str = ""


@dataclass
class SubstitutionResult:
    """Result of checking/substituting a version."""
    original_version: str
    final_version: str
    was_substituted: bool
    available_tags: list
    comment: str  # Comment to add to build script
    available_tags_line: str  # PACKAGE_AVAILABLE_TAGS line for build script


class VersionSubstitutionTracker:
    """Track version substitutions for investigation."""

    def __init__(self, output_dir: Path = None, tag_separator: str = ","):
        """
        Initialize tracker.

        Args:
            output_dir: Directory for output files
            tag_separator: Separator for PACKAGE_AVAILABLE_TAGS
                          "," - comma (safer, unambiguous, CSV-friendly)
                          " " - space (bash-native: for tag in $TAGS; do...)
        """
        self.output_dir = Path(output_dir) if output_dir else Path(".")
        self.tag_separator = tag_separator
        self.substitutions: list[VersionSubstitution] = []
        self.stats = {
            "checked": 0,
            "kept_original": 0,
            "substituted": 0,
            "no_tags_available": 0,
        }

    def normalize_version(self, version: str) -> str:
        """Normalize version for comparison (strip v prefix, etc.)."""
        v = version.strip().lower()
        # Remove common suffixes that don't affect matching
        for suffix in ['+incompatible', '-incompatible']:
            if v.endswith(suffix):
                v = v[:-len(suffix)]
        return v

    def version_in_tags(self, version: str, tags: list[str]) -> bool:
        """Check if version exists in available tags."""
        norm_version = self.normalize_version(version)

        for tag in tags:
            norm_tag = self.normalize_version(tag)
            # Exact match
            if norm_tag == norm_version:
                return True
            # Match with/without 'v' prefix
            if norm_tag.lstrip('v') == norm_version.lstrip('v'):
                return True

        return False

    def find_best_substitute(self, original_version: str, tags: list[str]) -> Optional[str]:
        """
        Find the best substitute version from available tags.

        Strategy:
        1. Prefer same major version if possible
        2. Otherwise use newest available
        """
        if not tags:
            return None

        # Extract major version from original (e.g., "v1.2.3" -> "1")
        orig_norm = self.normalize_version(original_version).lstrip('v')
        orig_major = orig_norm.split('.')[0] if '.' in orig_norm else orig_norm

        # Try to find same major version
        same_major = []
        for tag in tags:
            tag_norm = self.normalize_version(tag).lstrip('v')
            tag_major = tag_norm.split('.')[0] if '.' in tag_norm else tag_norm
            if tag_major == orig_major:
                same_major.append(tag)

        if same_major:
            # Return first (newest) with same major version
            return same_major[0]

        # Otherwise return newest overall
        return tags[0]

    def check_and_substitute(
        self,
        package_name: str,
        original_version: str,
        available_tags: list[str],
        language: str,
        script_path: str,
        package_url: str = ""
    ) -> SubstitutionResult:
        """
        Check if version needs substitution and return result.

        Args:
            package_name: Package name
            original_version: Original PACKAGE_VERSION from build script
            available_tags: List of available git tags (newest first)
            language: Programming language
            script_path: Path to build script
            package_url: GitHub/repository URL

        Returns:
            SubstitutionResult with final version and build script additions
        """
        self.stats["checked"] += 1

        # Handle empty tags
        if not available_tags:
            self.stats["no_tags_available"] += 1
            return SubstitutionResult(
                original_version=original_version,
                final_version=original_version,
                was_substituted=False,
                available_tags=[],
                comment="# WARNING: No GitHub tags found for this package",
                available_tags_line=""
            )

        # Check if original version is available
        if self.version_in_tags(original_version, available_tags):
            self.stats["kept_original"] += 1

            # Still add PACKAGE_AVAILABLE_TAGS for reference
            tags_sample = available_tags[:20]
            sep = self.tag_separator
            tags_line = f'PACKAGE_AVAILABLE_TAGS="{sep.join(tags_sample)}"'
            if len(available_tags) > 20:
                tags_line = tags_line[:-1] + f'{sep}..."'

            return SubstitutionResult(
                original_version=original_version,
                final_version=original_version,
                was_substituted=False,
                available_tags=available_tags,
                comment="",
                available_tags_line=tags_line
            )

        # Version not found - substitute
        self.stats["substituted"] += 1

        substitute = self.find_best_substitute(original_version, available_tags)

        # Determine reason
        reason = f"Original version {original_version} not in available tags (likely >5 years old)"

        # Create tracking record
        tags_sample_str = ";".join(available_tags[:10])
        self.substitutions.append(VersionSubstitution(
            package_name=package_name,
            original_version=original_version,
            substituted_version=substitute,
            language=language,
            script_path=script_path,
            package_url=package_url,
            available_tags_count=len(available_tags),
            available_tags_sample=tags_sample_str,
            substitution_reason=reason,
        ))

        # Build script additions
        comment = f"# NOTE: Version updated from {original_version} (not available, >5 years old)"

        tags_sample = available_tags[:20]
        sep = self.tag_separator
        tags_line = f'PACKAGE_AVAILABLE_TAGS="{sep.join(tags_sample)}"'
        if len(available_tags) > 20:
            tags_line = tags_line[:-1] + f'{sep}..."'

        return SubstitutionResult(
            original_version=original_version,
            final_version=substitute,
            was_substituted=True,
            available_tags=available_tags,
            comment=comment,
            available_tags_line=tags_line
        )

    def write_tracking_file(self, filename: str = "version_substitutions.csv") -> Path:
        """
        Write tracking file for investigation.

        Returns path to written file.
        """
        output_path = self.output_dir / filename
        output_path.parent.mkdir(parents=True, exist_ok=True)

        fieldnames = [
            "package_name",
            "original_version",
            "substituted_version",
            "language",
            "script_path",
            "package_url",
            "available_tags_count",
            "available_tags_sample",
            "substitution_reason",
            "timestamp",
            "investigation_status",
            "assigned_to",
            "notes",
        ]

        with open(output_path, 'w', encoding='utf-8', newline='') as f:
            # Header comment
            f.write("# Version Substitutions Tracking File\n")
            f.write(f"# Generated: {datetime.now().isoformat()}\n")
            f.write(f"# Total substitutions: {len(self.substitutions)}\n")
            f.write("#\n")
            f.write("# Investigation Status Values:\n")
            f.write("#   pending   - Not yet investigated\n")
            f.write("#   assigned  - Assigned to someone for investigation\n")
            f.write("#   resolved  - Investigated and resolved\n")
            f.write("#   wont_fix  - Investigated, decided not to fix\n")
            f.write("#\n")

        # Append CSV data
        with open(output_path, 'a', encoding='utf-8', newline='') as f:
            writer = csv.DictWriter(f, fieldnames=fieldnames)
            writer.writeheader()

            for sub in self.substitutions:
                writer.writerow({
                    "package_name": sub.package_name,
                    "original_version": sub.original_version,
                    "substituted_version": sub.substituted_version,
                    "language": sub.language,
                    "script_path": sub.script_path,
                    "package_url": sub.package_url,
                    "available_tags_count": sub.available_tags_count,
                    "available_tags_sample": sub.available_tags_sample,
                    "substitution_reason": sub.substitution_reason,
                    "timestamp": sub.timestamp,
                    "investigation_status": sub.investigation_status,
                    "assigned_to": sub.assigned_to,
                    "notes": sub.notes,
                })

        return output_path

    def print_summary(self) -> None:
        """Print summary statistics."""
        print("\n" + "=" * 60)
        print("VERSION SUBSTITUTION SUMMARY")
        print("=" * 60)
        print(f"Packages checked:        {self.stats['checked']:,}")
        print(f"Kept original version:   {self.stats['kept_original']:,}")
        print(f"Substituted (too old):   {self.stats['substituted']:,}")
        print(f"No tags available:       {self.stats['no_tags_available']:,}")

        if self.substitutions:
            # Breakdown by language
            by_language = {}
            for sub in self.substitutions:
                lang = sub.language or "unknown"
                by_language[lang] = by_language.get(lang, 0) + 1

            print("\nSubstitutions by language:")
            for lang, count in sorted(by_language.items(), key=lambda x: -x[1]):
                print(f"  {lang}: {count}")


# Convenience function for one-off use
def check_version_substitution(
    package_name: str,
    original_version: str,
    available_tags: list[str],
    language: str = "",
    script_path: str = "",
    package_url: str = ""
) -> SubstitutionResult:
    """
    One-off version substitution check.

    For batch processing, use VersionSubstitutionTracker class instead.
    """
    tracker = VersionSubstitutionTracker()
    return tracker.check_and_substitute(
        package_name=package_name,
        original_version=original_version,
        available_tags=available_tags,
        language=language,
        script_path=script_path,
        package_url=package_url
    )


if __name__ == "__main__":
    # Demo usage
    tracker = VersionSubstitutionTracker(output_dir=Path("."))

    # Simulate some substitutions
    result1 = tracker.check_and_substitute(
        package_name="aws-sdk-go-v2",
        original_version="v0.18.0",
        available_tags=["v1.41.1", "v1.41.0", "v1.40.1", "v1.40.0"],
        language="go",
        script_path="g/aws-sdk-go-v2/aws-sdk-go-v2_rhel_8.3.sh",
        package_url="https://github.com/aws/aws-sdk-go-v2"
    )

    print(f"Original: {result1.original_version}")
    print(f"Final: {result1.final_version}")
    print(f"Substituted: {result1.was_substituted}")
    print(f"Comment: {result1.comment}")
    print(f"Tags line: {result1.available_tags_line}")

    result2 = tracker.check_and_substitute(
        package_name="consul",
        original_version="v1.20.0",
        available_tags=["v1.22.2", "v1.21.0", "v1.20.0", "v1.19.0"],
        language="go",
        script_path="c/consul/consul_ubi_8.5.sh",
        package_url="https://github.com/hashicorp/consul"
    )

    print(f"\nOriginal: {result2.original_version}")
    print(f"Final: {result2.final_version}")
    print(f"Substituted: {result2.was_substituted}")

    tracker.print_summary()

    output_file = tracker.write_tracking_file()
    print(f"\nTracking file written to: {output_file}")
