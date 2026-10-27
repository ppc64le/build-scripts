#!/usr/bin/env python3
"""
csv_normalizer.py - Intelligent CSV column mapping and normalization

This module provides tools for normalizing CSV files with inconsistent column
naming conventions to a standardized format. It's designed to handle the chaos
of data from multiple sources with different naming conventions.

Standard CSV Schema
-------------------
All CSV files are normalized to this column order:

    package_name      - Package/component name (e.g., "express", "requests")
    package_version   - Version string (e.g., "1.2.3", "v2.0.0")
    language          - Programming language/ecosystem (e.g., "node", "python")
    language_version  - Language runtime version (e.g., "3.11", "18.x")
    script_path       - Path to build script (e.g., "e/express/express.sh")
    package_url       - Source repository URL (e.g., "https://github.com/...")
    download_url      - Direct download/tarball URL
    status            - Migration status (e.g., "pending", "completed")
    complexity        - Estimated complexity (e.g., "low", "medium", "high")
    priority          - Priority score or label

Column Mapping
--------------
The normalizer recognizes many common variations:

    Standard Name    | Recognized Variations
    -----------------|--------------------------------------------------
    package_name     | name, pkg, package, component, artifact, module
    package_version  | version, ver, release, tag
    language         | lang, technology, tech, ecosystem, platform
    package_url      | url, github_url, repo_url, repository, homepage
    script_path      | path, file, filepath, build_script, location
    ...              | (see COLUMN_ALIASES for complete list)

Content-Based Disambiguation
----------------------------
When column names are ambiguous, the normalizer inspects actual data:

    - URLs starting with "pkg:" are mapped to 'purl' (Package URL format)
    - URLs starting with "http://" are mapped to 'package_url'
    - Values matching version patterns (v1.2.3) are mapped to 'package_version'
    - Values containing "/" or ".sh" are mapped to 'script_path'

Output Format
-------------
Normalized CSV files include:

    Row 1: Standard column headers
    Row 2: Original column names (optional, prefixed with "# was:")
    Row 3+: Data rows

A companion .mapping.json file records the complete mapping for debugging.

Examples
--------
Quick normalization::

    from csv_normalizer import normalize_csv, write_normalized_csv

    # Read chaotic input, get normalized data and mapping
    data, mapping = normalize_csv("messy_input.csv")

    # Write in standard format
    write_normalized_csv(data, "clean_output.csv", mapping)

Using the class for more control::

    from csv_normalizer import CSVNormalizer

    normalizer = CSVNormalizer()

    # Read and normalize
    data = normalizer.read_and_normalize("input.csv")

    # Check what was mapped
    print(f"Mapped: {data.mapping.forward}")
    print(f"Unmapped: {data.mapping.unmapped}")

    # Write with options
    normalizer.write(
        "output.csv",
        data,
        include_original_headers=True,  # Add "# was:" row
        include_mapping_file=True        # Write .mapping.json
    )

Creating normalized rows programmatically::

    from csv_normalizer import create_empty_row, write_normalized_csv

    rows = []
    for pkg in packages:
        row = create_empty_row()
        row["package_name"] = pkg.name
        row["package_version"] = pkg.version
        row["language"] = "python"
        rows.append(row)

    write_normalized_csv(rows, "output.csv")

Command-line usage::

    python csv_normalizer.py input.csv output.csv
    python csv_normalizer.py input.csv output.csv --show-mapping
    python csv_normalizer.py input.csv output.csv --no-original-headers

"""

import csv
import json
import re
from dataclasses import dataclass, field, asdict
from pathlib import Path
from typing import Dict, List, Optional, Tuple, Any, Union


# =============================================================================
# STANDARD SCHEMA DEFINITION
# =============================================================================

#: The canonical column order - this is THE standard format.
#: All normalized CSV files will have columns in exactly this order.
STANDARD_COLUMNS: List[str] = [
    "package_name",
    "package_version",
    "language",
    "language_version",
    "script_path",
    "package_url",
    "download_url",
    "status",
    "complexity",
    "priority",
]

#: Known column name variations mapped to standard names.
#: Keys are standard column names, values are recognized variations (case-insensitive).
#: Variations are checked in order, so put more specific matches first.
COLUMN_ALIASES: Dict[str, List[str]] = {
    "package_name": [
        # Exact/preferred
        "package_name", "package name",
        # Common variations
        "name", "pkg", "package", "component",
        # SBOM/formal formats
        "component_name", "artifact", "artifact_name",
        "artifactid", "artifact_id",
        # Other systems
        "module", "module_name", "library", "lib",
    ],
    "package_version": [
        # Exact/preferred
        "package_version", "package version",
        # Common variations
        "version", "ver", "release", "tag",
        # Formal formats
        "release_version", "artifact_version",
    ],
    "language": [
        # Exact/preferred
        "language", "lang",
        # Platform/ecosystem terms
        "technology", "tech", "stack", "platform",
        "ecosystem", "runtime", "package_type",
        # Note: "type" is ambiguous but often means language/ecosystem
        "type",
    ],
    "language_version": [
        # Exact/preferred
        "language_version", "language version",
        # Variations
        "lang_version", "lang version",
        "technology_version", "technology version",
        "tech_version", "runtime_version",
        "platform_version", "node_version", "python_version",
        # Plural form (some tools use this)
        "language_versions", "language versions",
    ],
    "script_path": [
        # Exact/preferred
        "script_path", "script path",
        # Common variations
        "path", "file", "file_path", "filepath",
        "script", "build_script", "build script",
        # Other
        "source_path", "location", "filename",
    ],
    "package_url": [
        # Exact/preferred
        "package_url", "package url",
        # GitHub-specific
        "github_url", "github url", "github",
        # Generic repository
        "url", "repo_url", "repo url", "repo",
        "repository", "repository_url",
        # Other sources
        "homepage", "home_page", "home",
        "source_url", "source",
        "git_url", "clone_url",
    ],
    "download_url": [
        # Exact/preferred
        "download_url", "download url",
        # Variations
        "download", "tarball_url", "tarball",
        "archive_url", "archive", "dist_url", "dist",
        "source_tarball",
    ],
    "status": [
        # Exact/preferred
        "status", "state",
        # Specific status types
        "migration_status", "build_status",
        "migration_state",
    ],
    "complexity": [
        # Exact/preferred
        "complexity",
        # Variations
        "difficulty", "effort",
        "migration_complexity",
    ],
    "priority": [
        # Exact/preferred
        "priority", "prio",
        # Variations
        "rank", "order", "importance",
        "migration_priority",
    ],

    # --- Extended/SBOM formats ---

    "purl": [
        # Package URL (SBOM format) - only exact match to avoid confusion
        "purl",
    ],
    "license": [
        # License information (SBOM format)
        "license", "licenses",
        "licenseexpressions", "license_expressions", "license expressions",
        "spdx", "spdx_license", "spdx_id",
    ],

    # --- Legacy/alternate formats for compatibility ---

    "base_dir": [
        # Directory paths (legacy format)
        "base_dir", "base dir", "basedir",
        "directory", "dir", "folder",
    ],
}

# Build reverse lookup table: variation -> standard name
# This is used for O(1) lookup during column mapping
_VARIATION_TO_STANDARD: Dict[str, str] = {}
for _standard, _variations in COLUMN_ALIASES.items():
    for _variation in _variations:
        _VARIATION_TO_STANDARD[_variation.lower()] = _standard


# =============================================================================
# DATA CLASSES
# =============================================================================

@dataclass
class ColumnMapping:
    """
    Tracks how columns were mapped from input to standard format.

    This class records all mapping decisions for debugging and error tracing.
    It can be serialized to JSON for persistence.

    Attributes
    ----------
    forward : dict
        Maps original column names to standard names.
        Example: {"Package Name": "package_name", "Ver": "package_version"}

    reverse : dict
        Maps standard names back to original column names.
        Example: {"package_name": "Package Name", "package_version": "Ver"}

    unmapped : list
        Column names that couldn't be mapped to any standard column.
        These columns are preserved in the data but not in standard output.

    inferred : dict
        Columns that were mapped based on content inspection rather than name.
        Records the inference reason for debugging.
        Example: {"mystery_col": "inferred as package_url (content-based)"}

    Examples
    --------
    >>> mapping = ColumnMapping()
    >>> mapping.forward["Package Name"] = "package_name"
    >>> mapping.reverse["package_name"] = "Package Name"
    >>> mapping.to_json()
    '{"forward": {"Package Name": "package_name"}, ...}'
    """
    forward: Dict[str, str] = field(default_factory=dict)
    reverse: Dict[str, str] = field(default_factory=dict)
    unmapped: List[str] = field(default_factory=list)
    inferred: Dict[str, str] = field(default_factory=dict)

    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary for serialization."""
        return asdict(self)

    def to_json(self, indent: int = 2) -> str:
        """
        Serialize to JSON string.

        Parameters
        ----------
        indent : int
            JSON indentation level (default: 2)

        Returns
        -------
        str
            JSON representation of the mapping
        """
        return json.dumps(self.to_dict(), indent=indent)

    @classmethod
    def from_dict(cls, d: Dict[str, Any]) -> "ColumnMapping":
        """Create from dictionary."""
        return cls(**d)

    @classmethod
    def from_json(cls, s: str) -> "ColumnMapping":
        """
        Deserialize from JSON string.

        Parameters
        ----------
        s : str
            JSON string from to_json()

        Returns
        -------
        ColumnMapping
            Reconstructed mapping object
        """
        return cls.from_dict(json.loads(s))


@dataclass
class NormalizedData:
    """
    Container for normalized CSV data with metadata.

    This class holds the normalized rows along with mapping information
    and metadata about the source file.

    Attributes
    ----------
    rows : list
        List of row dictionaries with standard column names as keys.

    mapping : ColumnMapping
        The column mapping used to normalize this data.

    original_headers : list
        Original column names from the source file, in order.

    source_file : str, optional
        Path to the original source file, if known.

    row_count : int
        Number of data rows (computed automatically).

    Examples
    --------
    >>> data = normalizer.read_and_normalize("input.csv")
    >>> print(f"Loaded {data.row_count} rows from {data.source_file}")
    >>> for row in data.rows:
    ...     print(row["package_name"], row["package_version"])
    """
    rows: List[Dict[str, str]]
    mapping: ColumnMapping
    original_headers: List[str]
    source_file: Optional[str] = None
    row_count: int = 0

    def __post_init__(self):
        """Compute row_count after initialization."""
        self.row_count = len(self.rows)


# =============================================================================
# CONTENT INSPECTION FUNCTIONS
# =============================================================================

def _inspect_url_content(values: List[str]) -> str:
    """
    Inspect URL-like column values to determine actual type.

    This function samples values to distinguish between Package URLs (PURLs)
    and regular HTTP/Git URLs, which are often confused in column naming.

    Parameters
    ----------
    values : list
        Sample values from the column

    Returns
    -------
    str
        One of: 'purl', 'url', or 'unknown'

    Examples
    --------
    >>> _inspect_url_content(["pkg:npm/express@4.18.0", "pkg:pypi/requests@2.28"])
    'purl'
    >>> _inspect_url_content(["https://github.com/org/repo"])
    'url'
    """
    if not values:
        return "unknown"

    purl_count = 0
    url_count = 0

    for value in values[:10]:  # Sample first 10 non-empty values
        if not value:
            continue
        value_lower = str(value).strip().lower()

        # PURL format: pkg:type/namespace/name@version
        if value_lower.startswith("pkg:"):
            purl_count += 1
        # Regular URL formats
        elif value_lower.startswith(("http://", "https://", "git://", "ssh://", "git@")):
            url_count += 1

    if purl_count > url_count:
        return "purl"
    elif url_count > purl_count:
        return "url"
    return "unknown"


def _inspect_version_content(values: List[str]) -> bool:
    """
    Check if values look like version strings.

    Parameters
    ----------
    values : list
        Sample values from the column

    Returns
    -------
    bool
        True if >50% of values match version patterns

    Examples
    --------
    >>> _inspect_version_content(["1.2.3", "v2.0.0", "3.11.4"])
    True
    >>> _inspect_version_content(["express", "requests", "flask"])
    False
    """
    if not values:
        return False

    # Match: 1.2.3, v1.2.3, 1.2, 1.2.3-beta, 2024.01.15, etc.
    version_pattern = re.compile(r'^v?\d+(\.\d+)*([._-]?\w+)*$')
    non_empty = [v for v in values[:10] if v and str(v).strip()]
    if not non_empty:
        return False

    matches = sum(1 for v in non_empty if version_pattern.match(str(v).strip()))
    return matches > len(non_empty) * 0.5


def _inspect_path_content(values: List[str]) -> bool:
    """
    Check if values look like file paths.

    Parameters
    ----------
    values : list
        Sample values from the column

    Returns
    -------
    bool
        True if >50% of values contain path indicators

    Examples
    --------
    >>> _inspect_path_content(["a/abbrev/abbrev.sh", "e/express/express.sh"])
    True
    >>> _inspect_path_content(["express", "lodash", "react"])
    False
    """
    if not values:
        return False

    path_indicators = ('/', '.sh', '.py', '.js', '.rb', '.go', '.java', '.php')
    non_empty = [v for v in values[:10] if v and str(v).strip()]
    if not non_empty:
        return False

    matches = sum(1 for v in non_empty if any(ind in str(v) for ind in path_indicators))
    return matches > len(non_empty) * 0.5


# =============================================================================
# NORMALIZER CLASS
# =============================================================================

class CSVNormalizer:
    """
    Intelligent CSV normalizer that maps chaotic column names to standard format.

    This class provides the main functionality for reading CSV files with
    inconsistent column naming and normalizing them to a standard schema.

    Features
    --------
    - Name-based column mapping using extensive alias database
    - Content-based disambiguation for ambiguous columns
    - Complete mapping tracking for debugging
    - Consistent output format with optional original header tracking

    Parameters
    ----------
    standard_columns : list, optional
        Override the default standard column order.
        Default: STANDARD_COLUMNS

    column_aliases : dict, optional
        Additional column aliases to recognize.
        These are merged with the default COLUMN_ALIASES.

    Examples
    --------
    Basic usage::

        normalizer = CSVNormalizer()
        data = normalizer.read_and_normalize("messy.csv")
        normalizer.write("clean.csv", data)

    With custom columns::

        normalizer = CSVNormalizer(
            standard_columns=["name", "version", "url"],
            column_aliases={"name": ["pkg_name", "component"]}
        )

    Checking mapping results::

        normalizer = CSVNormalizer()
        data = normalizer.read_and_normalize("input.csv")

        print("Column mappings:")
        for orig, std in data.mapping.forward.items():
            print(f"  {orig!r} -> {std!r}")

        if data.mapping.unmapped:
            print(f"Warning: unmapped columns: {data.mapping.unmapped}")

        if data.mapping.inferred:
            print("Content-based inferences:")
            for col, reason in data.mapping.inferred.items():
                print(f"  {col}: {reason}")
    """

    def __init__(self,
                 standard_columns: List[str] = None,
                 column_aliases: Dict[str, List[str]] = None):
        """
        Initialize the normalizer.

        Parameters
        ----------
        standard_columns : list, optional
            Override the default STANDARD_COLUMNS
        column_aliases : dict, optional
            Additional aliases to merge with COLUMN_ALIASES
        """
        self.standard_columns = standard_columns or STANDARD_COLUMNS.copy()

        # Build variation lookup table
        self._variation_to_standard = _VARIATION_TO_STANDARD.copy()
        if column_aliases:
            for standard, variations in column_aliases.items():
                for variation in variations:
                    self._variation_to_standard[variation.lower()] = standard

    def map_columns(self,
                    headers: List[str],
                    sample_rows: List[Dict[str, str]] = None) -> ColumnMapping:
        """
        Map input column headers to standard column names.

        This method performs two-phase mapping:
        1. Name-based: Match column names against known aliases
        2. Content-based: Inspect data to resolve ambiguous mappings

        Parameters
        ----------
        headers : list
            Original column headers from the input file

        sample_rows : list, optional
            Sample data rows for content-based disambiguation.
            If provided, ambiguous columns are resolved by inspecting values.

        Returns
        -------
        ColumnMapping
            Complete mapping information including forward/reverse maps,
            unmapped columns, and content-based inferences.

        Examples
        --------
        >>> normalizer = CSVNormalizer()
        >>> mapping = normalizer.map_columns(
        ...     ["Package Name", "Ver", "URL", "mystery"],
        ...     sample_rows=[{"URL": "https://github.com/..."}]
        ... )
        >>> mapping.forward
        {'Package Name': 'package_name', 'Ver': 'package_version', 'URL': 'package_url'}
        >>> mapping.unmapped
        ['mystery']
        """
        mapping = ColumnMapping()

        # Phase 1: Name-based mapping
        for original in headers:
            original_lower = original.lower().strip()

            if original_lower in self._variation_to_standard:
                standard = self._variation_to_standard[original_lower]
                mapping.forward[original] = standard
                mapping.reverse[standard] = original
            else:
                mapping.unmapped.append(original)

        # Phase 2: Content-based disambiguation
        if sample_rows:
            self._disambiguate_by_content(mapping, headers, sample_rows)

        return mapping

    def _disambiguate_by_content(self,
                                  mapping: ColumnMapping,
                                  headers: List[str],
                                  sample_rows: List[Dict[str, str]]) -> None:
        """
        Use content inspection to fix ambiguous mappings.

        This method is called internally by map_columns when sample data
        is available. It can remap columns based on actual content.

        Parameters
        ----------
        mapping : ColumnMapping
            Mapping to update in-place
        headers : list
            Original column headers
        sample_rows : list
            Sample data for inspection
        """
        # Check URL-type columns for PURL vs HTTP URL confusion
        url_fields = ["package_url", "purl", "download_url"]
        for std_field in url_fields:
            if std_field in mapping.reverse:
                original = mapping.reverse[std_field]
                values = [row.get(original, "") for row in sample_rows]
                actual_type = _inspect_url_content(values)

                if actual_type == "purl" and std_field != "purl":
                    # Column contains PURLs, not HTTP URLs
                    del mapping.reverse[std_field]
                    mapping.forward[original] = "purl"
                    mapping.reverse["purl"] = original
                    mapping.inferred[original] = f"remapped {std_field} -> purl (content-based)"

                elif actual_type == "url" and std_field == "purl":
                    # Column contains HTTP URLs, not PURLs
                    del mapping.reverse["purl"]
                    mapping.forward[original] = "package_url"
                    mapping.reverse["package_url"] = original
                    mapping.inferred[original] = "remapped purl -> package_url (content-based)"

        # Try to map unmapped columns by inspecting content
        for original in mapping.unmapped.copy():
            values = [row.get(original, "") for row in sample_rows]

            # Check if it looks like a version column
            if "package_version" not in mapping.reverse and _inspect_version_content(values):
                mapping.forward[original] = "package_version"
                mapping.reverse["package_version"] = original
                mapping.unmapped.remove(original)
                mapping.inferred[original] = "inferred as package_version (content-based)"

            # Check if it looks like a path column
            elif "script_path" not in mapping.reverse and _inspect_path_content(values):
                mapping.forward[original] = "script_path"
                mapping.reverse["script_path"] = original
                mapping.unmapped.remove(original)
                mapping.inferred[original] = "inferred as script_path (content-based)"

            # Check if it looks like a URL column
            elif "package_url" not in mapping.reverse:
                url_type = _inspect_url_content(values)
                if url_type == "url":
                    mapping.forward[original] = "package_url"
                    mapping.reverse["package_url"] = original
                    mapping.unmapped.remove(original)
                    mapping.inferred[original] = "inferred as package_url (content-based)"
                elif url_type == "purl":
                    mapping.forward[original] = "purl"
                    mapping.reverse["purl"] = original
                    mapping.unmapped.remove(original)
                    mapping.inferred[original] = "inferred as purl (content-based)"

    def normalize_row(self,
                      row: Dict[str, str],
                      mapping: ColumnMapping) -> Dict[str, str]:
        """
        Normalize a single row using the column mapping.

        Parameters
        ----------
        row : dict
            Original row with original column names as keys
        mapping : ColumnMapping
            Column mapping to apply

        Returns
        -------
        dict
            New row dict with standard column names as keys

        Examples
        --------
        >>> row = {"Package Name": "express", "Ver": "4.18.0"}
        >>> mapping = ColumnMapping(forward={"Package Name": "package_name", "Ver": "package_version"})
        >>> normalizer.normalize_row(row, mapping)
        {'package_name': 'express', 'package_version': '4.18.0'}
        """
        normalized = {}

        for original, value in row.items():
            if original in mapping.forward:
                standard = mapping.forward[original]
                normalized[standard] = value

        return normalized

    def read_and_normalize(self,
                           input_path: Union[str, Path],
                           encoding: str = "utf-8") -> NormalizedData:
        """
        Read a CSV file and normalize it to standard format.

        This is the main entry point for normalizing a CSV file. It reads
        the file, maps columns, and normalizes all rows.

        Parameters
        ----------
        input_path : str or Path
            Path to the input CSV file

        encoding : str
            File encoding (default: "utf-8")

        Returns
        -------
        NormalizedData
            Container with normalized rows, mapping info, and metadata

        Raises
        ------
        FileNotFoundError
            If input file doesn't exist
        csv.Error
            If file is not valid CSV

        Examples
        --------
        >>> normalizer = CSVNormalizer()
        >>> data = normalizer.read_and_normalize("packages.csv")
        >>> print(f"Normalized {data.row_count} rows")
        >>> print(f"Mapped columns: {list(data.mapping.forward.keys())}")
        """
        input_path = Path(input_path)

        with open(input_path, "r", encoding=encoding, newline="") as f:
            # Skip comment lines at the start (lines beginning with #)
            lines = []
            for line in f:
                if line.startswith("#"):
                    continue
                lines.append(line)

            # Parse CSV from non-comment lines
            from io import StringIO
            reader = csv.DictReader(StringIO("".join(lines)))
            original_headers = reader.fieldnames or []

            # Read all rows for content inspection
            all_rows = list(reader)

        # Map columns using headers and sample data
        mapping = self.map_columns(original_headers, all_rows[:20])

        # Normalize all rows
        normalized_rows = [self.normalize_row(row, mapping) for row in all_rows]

        return NormalizedData(
            rows=normalized_rows,
            mapping=mapping,
            original_headers=original_headers,
            source_file=str(input_path),
            row_count=len(normalized_rows)
        )

    def write(self,
              output_path: Union[str, Path],
              data: Union[NormalizedData, List[Dict[str, str]]],
              mapping: ColumnMapping = None,
              include_original_headers: bool = True,
              include_mapping_file: bool = True) -> Path:
        """
        Write normalized data to CSV in standard format.

        Output format:
        - Row 1: Standard column headers
        - Row 2: Original column names (optional, as "# was: OriginalName")
        - Row 3+: Data rows

        Parameters
        ----------
        output_path : str or Path
            Path for output CSV file

        data : NormalizedData or list
            Either a NormalizedData object or a list of row dicts

        mapping : ColumnMapping, optional
            Column mapping (extracted from NormalizedData if not provided)

        include_original_headers : bool
            If True, add row 2 with original column names for traceability.
            Default: True

        include_mapping_file : bool
            If True, write a .mapping.json file alongside the CSV.
            Default: True

        Returns
        -------
        Path
            Path to the written CSV file

        Examples
        --------
        >>> normalizer.write("output.csv", data)  # Full output
        >>> normalizer.write("output.csv", data, include_original_headers=False)  # Clean output
        >>> normalizer.write("output.csv", rows, mapping)  # From raw rows
        """
        output_path = Path(output_path)

        # Extract rows and mapping from NormalizedData if needed
        if isinstance(data, NormalizedData):
            rows = data.rows
            mapping = data.mapping
        else:
            rows = data
            if mapping is None:
                mapping = ColumnMapping()

        with open(output_path, "w", encoding="utf-8", newline="") as f:
            writer = csv.DictWriter(f, fieldnames=self.standard_columns, extrasaction="ignore")

            # Row 1: Standard headers
            writer.writeheader()

            # Row 2: Original column names (as tracking comments)
            if include_original_headers and mapping.reverse:
                original_row = {}
                for std_col in self.standard_columns:
                    if std_col in mapping.reverse:
                        original_row[std_col] = f"# was: {mapping.reverse[std_col]}"
                    else:
                        original_row[std_col] = "# (new)"
                writer.writerow(original_row)

            # Data rows
            for row in rows:
                # Ensure all standard columns exist (empty string if missing)
                full_row = {col: row.get(col, "") for col in self.standard_columns}
                writer.writerow(full_row)

        # Write mapping file for debugging
        if include_mapping_file:
            mapping_path = output_path.with_suffix(output_path.suffix + ".mapping.json")
            with open(mapping_path, "w", encoding="utf-8") as f:
                f.write(mapping.to_json())

        return output_path


# =============================================================================
# CONVENIENCE FUNCTIONS
# =============================================================================

def normalize_csv(input_path: Union[str, Path],
                  encoding: str = "utf-8") -> Tuple[NormalizedData, ColumnMapping]:
    """
    Read and normalize a CSV file to standard format.

    This is a convenience function that creates a CSVNormalizer and
    processes the file in one call.

    Parameters
    ----------
    input_path : str or Path
        Path to input CSV file

    encoding : str
        File encoding (default: "utf-8")

    Returns
    -------
    tuple
        (NormalizedData, ColumnMapping) - the normalized data and mapping used

    Examples
    --------
    >>> data, mapping = normalize_csv("messy_input.csv")
    >>> print(f"Normalized {data.row_count} rows")
    >>> for row in data.rows:
    ...     print(row["package_name"])
    """
    normalizer = CSVNormalizer()
    data = normalizer.read_and_normalize(input_path, encoding)
    return data, data.mapping


def write_normalized_csv(data: Union[NormalizedData, List[Dict[str, str]]],
                         output_path: Union[str, Path],
                         mapping: ColumnMapping = None,
                         include_original_headers: bool = True,
                         include_mapping_file: bool = True) -> Path:
    """
    Write normalized data to CSV in standard format.

    This is a convenience function for writing normalized data.

    Parameters
    ----------
    data : NormalizedData or list
        Normalized data to write (NormalizedData or list of row dicts)

    output_path : str or Path
        Path for output CSV file

    mapping : ColumnMapping, optional
        Column mapping (required if data is a list)

    include_original_headers : bool
        Add row with original column names (default: True)

    include_mapping_file : bool
        Write .mapping.json file (default: True)

    Returns
    -------
    Path
        Path to written CSV file

    Examples
    --------
    >>> data, mapping = normalize_csv("input.csv")
    >>> write_normalized_csv(data, "output.csv")

    >>> # Or with raw rows
    >>> rows = [{"package_name": "express", "package_version": "4.18.0"}]
    >>> write_normalized_csv(rows, "output.csv")
    """
    normalizer = CSVNormalizer()
    return normalizer.write(output_path, data, mapping,
                           include_original_headers, include_mapping_file)


def get_standard_columns() -> List[str]:
    """
    Get the standard column order.

    Returns
    -------
    list
        Copy of STANDARD_COLUMNS

    Examples
    --------
    >>> cols = get_standard_columns()
    >>> print(cols[0])  # 'package_name'
    """
    return STANDARD_COLUMNS.copy()


def create_empty_row() -> Dict[str, str]:
    """
    Create an empty row dict with all standard columns.

    This is useful when building rows programmatically.

    Returns
    -------
    dict
        Dict with all standard columns as keys, empty strings as values

    Examples
    --------
    >>> row = create_empty_row()
    >>> row["package_name"] = "express"
    >>> row["package_version"] = "4.18.0"
    >>> row["language"] = "node"
    """
    return {col: "" for col in STANDARD_COLUMNS}


# =============================================================================
# COMMAND-LINE INTERFACE
# =============================================================================

def main():
    """Command-line interface for CSV normalization."""
    import argparse
    import sys

    parser = argparse.ArgumentParser(
        description="Normalize CSV files to standard column format",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=f"""
Standard columns (in order):
  {', '.join(STANDARD_COLUMNS)}

Output files:
  <output>.csv              - Normalized CSV file
  <output>.csv.mapping.json - Column mapping details (JSON)

Examples:
  %(prog)s input.csv output.csv
  %(prog)s messy.csv clean.csv --show-mapping
  %(prog)s input.csv output.csv --no-original-headers --no-mapping
        """
    )
    parser.add_argument("input", help="Input CSV file")
    parser.add_argument("output", help="Output CSV file")
    parser.add_argument("--no-original-headers", action="store_true",
                        help="Don't include original column names as row 2")
    parser.add_argument("--no-mapping", action="store_true",
                        help="Don't write .mapping.json file")
    parser.add_argument("--show-mapping", action="store_true",
                        help="Print column mapping to stdout")
    parser.add_argument("--encoding", default="utf-8",
                        help="File encoding (default: utf-8)")

    args = parser.parse_args()

    # Check input exists
    if not Path(args.input).exists():
        print(f"Error: Input file not found: {args.input}", file=sys.stderr)
        sys.exit(1)

    # Normalize
    print(f"Reading: {args.input}")
    try:
        data, mapping = normalize_csv(args.input, args.encoding)
    except Exception as e:
        print(f"Error reading CSV: {e}", file=sys.stderr)
        sys.exit(1)

    print(f"Found {data.row_count} rows, {len(data.original_headers)} columns")
    print(f"Mapped {len(mapping.forward)} columns, {len(mapping.unmapped)} unmapped")

    if mapping.unmapped:
        print(f"Unmapped columns: {mapping.unmapped}")

    if mapping.inferred:
        print("Content-based inferences:")
        for col, reason in mapping.inferred.items():
            print(f"  {col}: {reason}")

    if args.show_mapping:
        print("\nColumn mapping (original -> standard):")
        for orig, std in sorted(mapping.forward.items()):
            print(f"  {orig!r:30} -> {std!r}")

    # Write
    print(f"\nWriting: {args.output}")
    write_normalized_csv(
        data,
        args.output,
        mapping,
        include_original_headers=not args.no_original_headers,
        include_mapping_file=not args.no_mapping
    )

    if not args.no_mapping:
        print(f"Mapping: {args.output}.mapping.json")

    print("Done!")


if __name__ == "__main__":
    main()
