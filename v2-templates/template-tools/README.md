# Build Script Migration Tools

Tools for migrating legacy build scripts to the new V2 template format.

## Overview

The migration pipeline converts old-style build scripts (where each script contains duplicated boilerplate) to the new template-based format (where scripts declare metadata and source a shared template).

The pipeline has three stages:

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│    ANALYZE      │ --> │     FILTER      │ --> │    MIGRATE      │
│                 │     │                 │     │                 │
│ Scan repository │     │ Select by       │     │ Convert scripts │
│ Detect language │     │ language/distro │     │ to new format   │
│ Assess status   │     │ Output CSV      │     │ Copy templates  │
└─────────────────┘     └─────────────────┘     └─────────────────┘
        │                       │                       │
        v                       v                       v
  migration_analysis/     filtered.csv            migrated_scripts/
```

## Quick Start

### Full Pipeline (Recommended)

Migrate all Node.js packages on UBI 9:

```bash
./build-migrate run \
    --language node \
    --release 9 \
    -b ../build-scripts \
    -d ../build-scripts-v2
```

### Step-by-Step

If you need more control, run stages individually:

```bash
# 1. Analyze the repository
./build-migrate analyze -b ../build-scripts

# 2. Filter to Node.js packages on UBI 9
./build-migrate filter --language node --release 9 -o Node.csv

# 3. Migrate the filtered scripts
./build-migrate migrate --batch Node.csv -b ../build-scripts -d ../build-scripts-v2
```

## Commands

### `build-migrate analyze`

Scans the build-scripts repository and identifies migration candidates.

```bash
./build-migrate analyze -b <build-scripts-dir> [OPTIONS]
```

**Options:**
| Option | Description |
|--------|-------------|
| `-b, --base <dir>` | Build-scripts directory to analyze |
| `-o, --output <dir>` | Output directory (default: `./migration_analysis`) |
| `-l, --language <lang>` | Filter by language during analysis |
| `-c, --csv` | Output in CSV format (recommended for pipeline) |
| `--priority` | Sort by migration priority |

**Output files:**
- `migration_analysis/migration_candidates.txt` - All candidates (CSV or table format)
- `migration_analysis/migration_summary.md` - Summary statistics
- `migration_analysis/priority_list.txt` - Priority-sorted list (if `--priority`)

### `build-migrate filter`

Filters analyzed candidates by language, distro, and/or release version.

```bash
./build-migrate filter [OPTIONS] -o <output.csv>
```

**Options:**
| Option | Description |
|--------|-------------|
| `-l, --language <lang>` | Filter by language (python, node, go, java, ruby, php, r) |
| `-d, --distro <distro>` | Filter by distro (ubi, rhel, ubuntu, debian, sles) |
| `-r, --release <ver>` | Filter by release (9, 9.3, 8, 20.04, etc.) |
| `-i, --input <file>` | Input candidates file (default: `./migration_analysis/migration_candidates.txt`) |
| `-o, --output <file>` | Output CSV file (default: stdout) |

**Examples:**
```bash
# All Python packages
./build-migrate filter --language python -o Python.csv

# Node.js on UBI 9.x
./build-migrate filter --language node --distro ubi --release 9 -o Node_UBI9.csv

# All packages on RHEL 8.3 specifically
./build-migrate filter --distro rhel --release 8.3 -o RHEL_8.3.csv
```

### `build-migrate migrate`

Converts scripts to the new template format.

```bash
./build-migrate migrate --batch <file.csv> -b <build-scripts-dir> -d <output-dir> [OPTIONS]
```

**Options:**
| Option | Description |
|--------|-------------|
| `--batch <file>` | CSV file with scripts to migrate |
| `-b, --base <dir>` | Original build-scripts directory (required with --batch) |
| `-d, --dest <dir>` | Destination for migrated scripts |
| `-n, --dry-run` | Show what would be done without making changes |
| `-f, --force` | Overwrite existing migrated scripts |
| `-v, --verbose` | Verbose output |
| `-r, --report` | Generate detailed migration report |
| `--mapping-output <file>` | Custom path for mapping CSV |

**Output:**
- Migrated scripts in `<dest>/<letter>/<package>/`
- Templates copied to `<dest>/templates/`
- `advanced_mapping.csv` - Records what was migrated

### `build-migrate run`

Executes the full pipeline (or selected stages) in one command.

```bash
./build-migrate run -b <build-scripts-dir> -d <output-dir> [OPTIONS]
```

**Options:**
| Option | Description |
|--------|-------------|
| `-b, --base <dir>` | Build-scripts directory (required) |
| `-d, --dest <dir>` | Destination directory (required) |
| `-l, --language <lang>` | Filter by language |
| `--distro <distro>` | Filter by distro |
| `-r, --release <ver>` | Filter by release version |
| `--stages <list>` | Comma-separated stages (default: `analyze,filter,migrate`) |
| `--filter-output <file>` | Name for intermediate filtered CSV |
| `--mapping-output <file>` | Name for mapping output CSV |
| `-n, --dry-run` | Dry run mode |
| `-f, --force` | Force overwrite |

**Examples:**
```bash
# Full pipeline for Python
./build-migrate run --language python -b ../build-scripts -d ../build-scripts-v2

# Skip analyze (already done), just filter and migrate Go packages
./build-migrate run --stages filter,migrate --language go -b ../build-scripts -d ../build-scripts-v2

# Dry run to see what would happen
./build-migrate run --language node --release 9 -b ../build-scripts -d ../build-scripts-v2 --dry-run
```

## CSV Format

All CSV files use a standardized column format:

| Column | Description |
|--------|-------------|
| `package_name` | Package name (e.g., `python-fire`) |
| `package_version` | Version (may be empty) |
| `language` | Detected language (python, node, go, etc.) |
| `language_version` | Language version (reserved, empty) |
| `script_path` | Relative path (e.g., `p/python-fire/python_fire_ubi_9.3.sh`) |
| `package_url` | Source repository URL (may be empty) |
| `download_url` | Download URL (reserved, empty) |
| `status` | Migration status: pending, migrated, unknown |
| `complexity` | Estimated complexity: low, medium, high |
| `priority` | Priority score (lower = higher priority) |

## CSV Normalizer

The `csv_normalizer.py` module provides intelligent column mapping to handle CSV files from various sources with inconsistent column naming conventions.

### Problem

Different tools and data sources use different column names for the same data:

```
Source A: "Package Name", "Ver", "URL"
Source B: "component", "version", "github_url"
Source C: "pkg", "release", "repository"
```

### Solution

The CSV normalizer maps all variations to our standard format automatically:

```bash
# Command line
python csv_normalizer.py messy_input.csv clean_output.csv

# With mapping details
python csv_normalizer.py input.csv output.csv --show-mapping
```

```python
# Python API
from csv_normalizer import normalize_csv, write_normalized_csv

# Read chaotic input, normalize to standard format
data, mapping = normalize_csv("messy_input.csv")

# Check what was mapped
print(f"Mapped {len(mapping.forward)} columns")
print(f"Unmapped: {mapping.unmapped}")

# Write in standard format
write_normalized_csv(data, "clean_output.csv")
```

### Recognized Column Variations

The normalizer recognizes many common variations (case-insensitive):

| Standard Column | Recognized Variations |
|-----------------|----------------------|
| `package_name` | name, pkg, package, component, artifact, module, library |
| `package_version` | version, ver, release, tag |
| `language` | lang, technology, tech, ecosystem, platform, type |
| `language_version` | lang_version, runtime_version, node_version, python_version |
| `script_path` | path, file, filepath, build_script, location |
| `package_url` | url, github_url, repo_url, repository, homepage, source_url |
| `download_url` | download, tarball_url, archive_url, dist_url |
| `status` | state, migration_status, build_status |
| `complexity` | difficulty, effort |
| `priority` | prio, rank, importance |

### Content-Based Disambiguation

When column names are ambiguous, the normalizer inspects actual data values:

- URLs starting with `pkg:` → mapped to `purl` (Package URL/SBOM format)
- URLs starting with `http://` → mapped to `package_url`
- Values matching `v1.2.3` patterns → mapped to `package_version`
- Values containing `/` or `.sh` → mapped to `script_path`

### Output Format

Normalized CSV files include tracking information:

```csv
package_name,package_version,language,language_version,script_path,package_url,download_url,status,complexity,priority
# was: Package Name,# was: Ver,# was: Lang,# (new),# was: Path,# was: URL,# (new),# (new),# (new),# (new)
express,4.18.0,node,,e/express/express.sh,https://github.com/expressjs/express,,pending,,
```

- **Row 1**: Standard column headers
- **Row 2**: Original column names (prefixed with `# was:`) for traceability
- **Row 3+**: Data rows

A companion `.mapping.json` file records the complete mapping:

```json
{
  "forward": {"Package Name": "package_name", "Ver": "package_version"},
  "reverse": {"package_name": "Package Name", "package_version": "Ver"},
  "unmapped": ["extra_column"],
  "inferred": {"mystery_url": "inferred as package_url (content-based)"}
}
```

### CLI Options

```bash
python csv_normalizer.py input.csv output.csv [OPTIONS]
```

| Option | Description |
|--------|-------------|
| `--show-mapping` | Print column mapping to stdout |
| `--no-original-headers` | Don't include "# was:" row |
| `--no-mapping` | Don't write .mapping.json file |
| `--encoding <enc>` | File encoding (default: utf-8) |

### Python API

```python
from csv_normalizer import (
    normalize_csv,           # Read and normalize a CSV file
    write_normalized_csv,    # Write normalized data
    CSVNormalizer,           # Class for more control
    create_empty_row,        # Create empty row with all standard columns
    get_standard_columns,    # Get list of standard column names
    ColumnMapping,           # Mapping data class
    NormalizedData,          # Normalized data container
)

# Quick usage
data, mapping = normalize_csv("input.csv")
write_normalized_csv(data, "output.csv")

# Building rows programmatically
from csv_normalizer import create_empty_row, write_normalized_csv

rows = []
for pkg in my_packages:
    row = create_empty_row()
    row["package_name"] = pkg.name
    row["package_version"] = pkg.version
    row["language"] = "python"
    rows.append(row)

write_normalized_csv(rows, "packages.csv", include_original_headers=False)
```

## Common Workflows

### Migrate all packages for a language

```bash
./build-migrate run --language python -b ../build-scripts -d ../build-scripts-v2
```

### Migrate specific release only

```bash
./build-migrate run --language node --release 9 -b ../build-scripts -d ../build-scripts-v2
```

### Generate filtered list without migrating

```bash
./build-migrate analyze -b ../build-scripts -c
./build-migrate filter --language java -o Java_candidates.csv
# Review Java_candidates.csv, then:
./build-migrate migrate --batch Java_candidates.csv -b ../build-scripts -d ../output
```

### Check what would be migrated (dry run)

```bash
./build-migrate run --language ruby -b ../build-scripts -d ../output --dry-run
```

### Re-run migration with force overwrite

```bash
./build-migrate migrate --batch Node.csv -b ../build-scripts -d ../output --force
```

## Directory Structure

**Input (build-scripts):**
```
build-scripts/
├── p/
│   └── python-fire/
│       ├── python_fire_ubi_9.3.sh
│       └── build_info.json
├── n/
│   └── node-fancytree/
│       └── fancytree_ubi_9.3.sh
└── ...
```

**Output (after migration):**
```
build-scripts-v2/
├── p/
│   └── python-fire/
│       ├── python-fire.sh          # Migrated script (simplified name)
│       └── build_info.json         # Copied
├── n/
│   └── node-fancytree/
│       └── node-fancytree.sh
├── templates/
│   ├── python.sh                   # Language templates
│   ├── node.sh
│   ├── go.sh
│   ├── lib/
│   │   └── common.sh               # Shared library
│   └── template-tools/
│       ├── advanced_mapping.csv    # Migration tracking
│       └── migration_report.md     # Summary report
└── ...
```

## Version Matching & Transformations

During migration, `PACKAGE_VERSION` values are validated and corrected using official registry data. Since the version is used for `git checkout`, the tool prefers GitHub tag format when available.

### Version Data Sources

| Language | Primary Registry | File |
|----------|-----------------|------|
| Python | PyPI | `pypi_versions.json` |
| Node/JavaScript | npm | `npm_versions.json` |
| Go | Go Proxy | `go_versions.json` |
| PHP | Packagist | `packagist_versions.json` |
| Java | Maven | `maven_versions.json` |
| Ruby | RubyGems | `ruby_versions.json` |
| (fallback) | GitHub Tags | `github_tags_mapping.json` |

### Version Matching Strategies

Applied in order until a match is found:

| Strategy | Input | Registry Has | Output |
|----------|-------|--------------|--------|
| Exact match | `1.2.3` | `1.2.3` | `1.2.3` |
| v-prefix normalization | `v1.2.3` | `1.2.3` | `1.2.3` |
| v-prefix normalization | `1.2.3` | `v1.2.3` | `v1.2.3` |
| Trailing zero completion | `1.2` | `1.2.0` | `1.2.0` |
| Prefix match (minor) | `1.2` | `1.2.0`, `1.2.5` | `1.2.0` (prefers .0) |
| Prefix match (major) | `1` | `1.0.0`, `1.5.0` | `1.5.0` (latest) |
| Contains match | `2024.9` | `2024.9.11` | `2024.9.11` |

### GitHub Tag Format Preference

After matching in the primary registry, the tool looks up the package in `github_tags_mapping.json` to get the actual git tag format:

```
Input:    1.2
npm has:  1.2.0
GitHub:   v1.2.0
Output:   v1.2.0  ← Prefers GitHub tag for git checkout
```

If the package isn't in GitHub tags, the registry format is used.

### Package Name Matching

The tool tries multiple strategies to find packages in registry data:

1. **Exact match** (case-insensitive)
2. **`__` to `/` conversion** for PHP packages (`abraham__twitteroauth` → `abraham/twitteroauth`)
3. **Build script path matching** via `original_input` field
4. **Repository URL matching**
5. **Common prefix stripping** (`python-fire` → `fire`, `node-fetch` → `fetch`)

### Generated Script Comments

When a version is corrected, a comment is added to the generated script:

```bash
PACKAGE_VERSION="${1:-v1.2.0}"  # PACKAGE_VERSION updated based on npm_versions.json input file
```

### Unconfirmed Versions

If a version cannot be matched, a warning comment is added:

```bash
# WARNING: VERSION NOT CONFIRMED IN PACKAGING AUTHORITY
```

And the package is logged to `version_warnings.txt`.

### Missing GitHub Tags

If a package is found in the primary registry (npm, pypi, etc.) but NOT in `github_tags_mapping.json`, it is logged to `github_tags_missing.csv`. This may indicate:

- Missing data in `github_tags_mapping.json` (needs refresh)
- Repository was archived or removed from GitHub
- Incorrect clone location or package URL

**Output format (`github_tags_missing.csv`):**
```csv
# Packages missing from github_tags_mapping.json
# Script paths are relative to --base directory: build-scripts/
#
package_name,package_version,language,language_version,script_path,package_url,download_url,status,complexity,priority
abbrev,1.1.0,node,,a/abbrev/abbrev_ubi_9.sh,https://github.com/npm/abbrev-js,,pending,,
some-pkg,2.0.0,python,,s/some-pkg/some-pkg.sh,https://github.com/org/some-pkg,,pending,,
```

Script paths are always relative to the `--base` directory (build-scripts root), never absolute paths.

This CSV format is compatible with `version_fetchers/fetch_github_tags.py --input csv --input-file`, allowing you to re-fetch GitHub tags for missing packages:

```bash
cd version_fetchers
python fetch_github_tags.py --input csv --input-file ../github_tags_missing.csv
```

These packages will use the registry version format (without `v` prefix for npm) since the actual GitHub tag format is unknown.

## GitHub Version Assessment

### The Mechanism

The tool fetches version information from GitHub using a two-step approach:

1. **Fetch Git Tags** (primary source of truth)
   - Uses GitHub Tags API: `GET /repos/{owner}/{repo}/tags`
   - Returns actual git tags that can be used with `git checkout`
   - Example: `v1.2.3`, `v1.2.2`, `v1.2.1`, ...

2. **Fetch GitHub Releases** (for metadata enrichment)
   - Uses GitHub Releases API: `GET /repos/{owner}/{repo}/releases`
   - Provides release dates, prerelease flags, and release notes
   - Each release has an associated `tag_name`

3. **Merge Results**
   - Tags are enriched with release metadata where available
   - Each entry is marked with source: `tag`, `release`, or `tag+release`

```bash
# Fetch both tags and releases for packages
cd version_fetchers
python fetch_github_tags.py --input csv --input-file packages.csv

# Re-fetch packages with suspicious tags (release-YYYY style, paths with /)
python fetch_github_tags.py --refetch-bad-tags

# Force re-fetch all packages
python fetch_github_tags.py --force-refetch
```

### Why This Approach

**Problem:** Package registries (npm, PyPI, Go modules) publish versions, but build scripts need git tags for `git checkout`. These don't always match:

| Registry | Git Tag | Difference |
|----------|---------|------------|
| `1.2.3` | `v1.2.3` | v-prefix |
| `1.2.3` | `release-2024-01-15` | Aggregate release |
| `1.2.3` | `sdk/foo/v1.2.3` | Monorepo path |

**Solution:** Fetch directly from GitHub's Tags API to get the actual git references.

**Why Tags API over Releases API:**

1. **Tags are the source of truth** - Every `git checkout` uses a tag (or commit)
2. **Not all tags have releases** - Many projects create version tags without GitHub Releases
3. **Releases can be misleading** - Some repos use aggregate releases (e.g., `release-2024-01-15`) while individual version tags exist separately

**Monorepo handling:** For repos like `aws-sdk-go-v2` or `azure-sdk-for-go`:
- Releases API returns: `release-2026-01-21` (aggregate) or `sdk/storage/v1.2.0` (per-module)
- Tags API returns: `v0.18.0`, `v1.41.1` (actual version tags)
- We fetch both and let the version matcher find the right one

### Version Substitution

When a requested version is not found in available GitHub tags (typically >5 years old), the tool automatically substitutes the newest available version:

```bash
# Original build script
PACKAGE_VERSION="v0.18.0"  # Too old, not in cache

# After migration
PACKAGE_VERSION="${1:-v1.41.1}"  # Updated from v0.18.0 (not available, >5 years old)
PACKAGE_AVAILABLE_TAGS="v1.41.1,v1.41.0,v1.40.1,v1.40.0,..."  # For fallback testing
```

**Rationale:**
- Versions >5 years old rarely build successfully (dependency rot, API changes)
- Using the latest version at least tests if the package builds at all
- `PACKAGE_AVAILABLE_TAGS` provides fallback options if latest fails
- All substitutions are tracked in `version_substitutions.csv` for investigation

### Tracking Files

| File | Purpose |
|------|---------|
| `version_substitutions.csv` | Packages where version was substituted (original too old) |
| `github_tags_missing.csv` | Packages not found in GitHub tags cache |
| `version_warnings.txt` | Versions that couldn't be confirmed in any registry |

The substitutions file includes investigation status columns (`pending`, `assigned`, `resolved`, `wont_fix`) for tracking remediation work.

### CLI Options

| Option | Description |
|--------|-------------|
| `--version-data <dir>` | Directory containing version JSON files (default: `./version_data`) |
| `--no-version-fix` | Disable automatic version correction |

## Troubleshooting

### "File not found" errors during migrate

The `script_path` in your CSV must be relative to the `--base` directory. For example, if your base is `../build-scripts`, paths should look like `p/python-fire/script.sh`, not `/full/path/to/script.sh`.

### "Templates lib directory not found"

The tool looks for templates in `../templates/` relative to the tool directory. Use `--template-dir` to specify a different location.

### "Not a file (is a directory?)"

Your CSV contains a path that points to a directory instead of a script file. Check the `script_path` column for incorrect entries.

## Project Structure

```
template-tools/
├── build-migrate.py              # Main entry point (use this)
├── lib/                          # Internal modules
│   ├── analyze_migration_candidates.py
│   ├── analyze_missing_versions.py
│   ├── csv_normalizer.py
│   ├── filter_candidates.py
│   ├── migrate_to_template.py
│   ├── version_matcher.py
│   └── version_substitution_tracker.py
├── version_fetchers/             # GitHub data fetching
│   └── fetch_github_tags.py
└── version_data/                 # Cached registry data
    ├── github_tags_mapping.json
    ├── npm_versions.json
    ├── pypi_versions.json
    └── ...
```

All functionality is accessed through `build-migrate.py`. The `lib/` modules are internal implementation details.

## Requirements

- Python 3.10+
- No external dependencies (uses only standard library)
