# Build Script Migration Toolkit - User Guide

This guide describes the Build Script Migration Toolkit, a system for modernizing legacy shell-based build scripts by converting them to standardized, language-specific templates.

## Table of Contents

1. [Quick Reference Cheat Sheet](#quick-reference-cheat-sheet)
2. [Overview](#overview)
3. [Prerequisites](#prerequisites)
4. [Tools Overview](#tools-overview)
5. [Workflow](#workflow)
6. [Tool Reference](#tool-reference)
   - [analyze_migration_candidates](#analyze_migration_candidates)
   - [filter_candidates](#filter_candidates)
   - [migrate_to_template](#migrate_to_template)
   - [make-list.sh](#make-listsh)
7. [Output Structure](#output-structure)
8. [Template Format](#template-format)
9. [Examples](#examples)
10. [Troubleshooting](#troubleshooting)

---

## Quick Reference Cheat Sheet

### Setup

```bash
python3.12 -m venv .venv && source .venv/bin/activate
```

### Common Commands

| Task | Command |
|------|---------|
| Analyze all scripts | `./analyze_migration_candidates -b ~/build-scripts -o ./analysis` |
| Analyze with priority | `./analyze_migration_candidates -b ~/build-scripts --priority` |
| Filter by language | `./filter_candidates -l python` |
| Filter by distro | `./filter_candidates -d ubi -r 9` |
| Filter combined | `./filter_candidates -l python -d ubi -r 9 -o output.csv` |
| Migrate single script | `./migrate_to_template script.sh -d ./output` |
| Migrate batch | `./migrate_to_template -b ~/build-scripts --batch list.csv -d ./output` |
| Dry run | `./migrate_to_template --dry-run -v ...` |
| Scan only | `./migrate_to_template --scan directory/ -v` |
| Generate list from CSV | `./make-list.sh input.csv` |

### Option Quick Reference

**analyze_migration_candidates**
```
-b <dir>     Source build-scripts directory
-o <dir>     Output directory (default: ./migration_analysis)
-l <lang>    Filter by language
-s <status>  Filter by status (pending|migrated|unknown)
-c           CSV output format
--priority   Sort by priority
```

**filter_candidates**
```
-l <lang>    Language (python|node|go|java|ruby|php|r|conda)
-d <distro>  Distribution (rhel|ubi|ubuntu|debian|sles|centos|fedora)
-r <ver>     Release version (7|8|9|9.3|20.04|etc.)
-i <file>    Input file (default: ./migration_analysis/migration_candidates.txt)
-o <file>    Output file (default: stdout)
```

**migrate_to_template**
```
-b <dir>     Source build-scripts directory (required for --batch)
-d <dir>     Destination directory (default: ./migrated_scripts)
--batch <f>  Batch file (.csv or .list)
-l <lang>    Override language detection
-r           Generate migration report
-n           Dry run (no changes)
-f           Force overwrite
-v           Verbose output
--scan       Scan only, don't migrate
```

### Full Workflow (Copy-Paste Ready)

```bash
# 1. Setup
source .venv/bin/activate

# 2. Analyze
./analyze_migration_candidates -b ~/build-scripts -o ./analysis --priority

# 3. Filter (example: Python on UBI 9)
./filter_candidates -l python -d ubi -r 9 -o python_ubi9.csv

# 4. Generate list
./make-list.sh python_ubi9.csv

# 5. Preview
./migrate_to_template -b ~/build-scripts --batch python_ubi9.list --dry-run -v

# 6. Execute
./migrate_to_template -b ~/build-scripts --batch python_ubi9.list -d ./migrated -r

# 7. Review
cat ./migrated/migration_report.md
```

### Language Values

| Language | Values |
|----------|--------|
| Python | `python` |
| Node.js | `node`, `nodejs`, `javascript` |
| Go | `go`, `golang` |
| Java | `java` |
| Ruby | `ruby` |
| PHP | `php` |
| R | `r` |
| Conda | `conda` |

### Distribution Values

| Family | Values |
|--------|--------|
| Red Hat | `rhel`, `ubi`, `centos`, `fedora` |
| Debian | `ubuntu`, `debian` |
| SUSE | `sles`, `opensuse` |

### Template Callbacks

| Callback | Purpose |
|----------|---------|
| `pre_packages()` | Add repos before package install |
| `post_clone()` | Apply patches after clone |
| `pre_build()` | Set env vars before build |
| `custom_build_command()` | Replace default build |
| `custom_test_command()` | Replace default test |
| `post_install()` | Cleanup after install |

### Output Files

| File | Location | Description |
|------|----------|-------------|
| Candidates list | `./migration_analysis/migration_candidates.txt` | All analyzed scripts |
| Summary report | `./migration_analysis/migration_summary.md` | Statistics |
| Priority list | `./migration_analysis/priority_list.txt` | Sorted by priority |
| Migration report | `./migrated/migration_report.md` | Migration results |

---

## Overview

The Build Script Migration Toolkit automates the conversion of legacy build scripts into a modern V2 template-based format. The system:

- **Analyzes** existing scripts to detect language, complexity, and migration readiness
- **Filters** candidates by language, distribution, or release version
- **Migrates** scripts to use standardized templates while preserving custom logic

**Supported Languages:**
- Python
- Node.js / JavaScript
- Go
- Java
- Ruby
- PHP
- R
- Conda

**Supported Distributions:**
- Red Hat family: RHEL, UBI, CentOS, Fedora
- Debian family: Ubuntu, Debian
- SUSE family: SLES, openSUSE

---

## Prerequisites

### Python Environment

All tools require Python 3.12 or later with a virtual environment:

```bash
# Create virtual environment
python3.12 -m venv .venv

# Activate it (required before running any tool)
source .venv/bin/activate
```

### Directory Structure

Ensure you have:
- Access to the legacy build-scripts repository
- Write access to the output directory for migrated scripts
- The templates directory at `../templates/` relative to the tools

---

## Tools Overview

| Tool | Purpose |
|------|---------|
| `analyze_migration_candidates` | Scan and analyze scripts for migration readiness |
| `filter_candidates` | Filter analyzed candidates by language, distro, or version |
| `migrate_to_template` | Convert scripts to V2 template format |
| `make-list.sh` | Generate migration input lists from CSV files |

---

## Workflow

The typical migration workflow follows three phases:

```
┌──────────────────────────────────────────────────────────────────┐
│                    LEGACY BUILD SCRIPTS                          │
│  - Monolithic, copy-pasted code                                  │
│  - Distro-specific variants (rhel_8.3, ubi_9.3, ubuntu_20.04)   │
└────────────────────────────┬─────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│  PHASE 1: ANALYZE                                               │
│  ─────────────────                                              │
│  ./analyze_migration_candidates -b <build-scripts-dir>          │
│                                                                 │
│  Output:                                                        │
│  - migration_candidates.txt (all scripts with metadata)         │
│  - migration_summary.md (statistics and recommendations)        │
│  - priority_list.txt (when --priority flag used)                │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│  PHASE 2: FILTER (Optional)                                     │
│  ──────────────────────────                                     │
│  ./filter_candidates -l python -d ubi -r 9                      │
│                                                                 │
│  Output:                                                        │
│  - Filtered CSV subset for targeted migration                   │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│  PHASE 3: MIGRATE                                               │
│  ────────────────                                               │
│  ./migrate_to_template -b <build-scripts> --batch <list.csv>    │
│                                                                 │
│  Output:                                                        │
│  - migrated_scripts/ directory with V2 template-based scripts   │
│  - migration_report.md (success/failure summary)                │
└─────────────────────────────────────────────────────────────────┘
```

---

## Tool Reference

### analyze_migration_candidates

Scans a build-scripts repository to identify and analyze scripts that need migration.

#### Usage

```bash
./analyze_migration_candidates [OPTIONS]
```

#### Options

| Option | Description |
|--------|-------------|
| `-b, --base <dir>` | Build-scripts directory to analyze |
| `-o, --output <dir>` | Output directory for reports (default: `./migration_analysis`) |
| `-l, --language <lang>` | Filter results by language |
| `-s, --status <status>` | Filter by status: `pending`, `migrated`, or `unknown` |
| `-c, --csv` | Output in CSV format instead of table |
| `--priority` | Sort output by migration priority |
| `-h, --help` | Show help message |

#### Output Files

- **migration_candidates.txt** - Complete list of analyzed scripts with metadata
- **migration_summary.md** - Statistical summary with recommendations
- **priority_list.txt** - Scripts sorted by priority (when `--priority` used)

#### Language Detection

The tool uses a multi-source detection strategy:

1. **Header comment** - Explicit `# Language: <language>` in script
2. **CSV lookup** - Cross-references against known script database (confidence-weighted)
3. **Heuristics** - Pattern matching for package managers, file extensions, and commands

#### Complexity Assessment

Scripts are rated by complexity based on:

| Factor | Points |
|--------|--------|
| Contains patches | +2 |
| Uses sed/awk manipulation | +1 |
| Custom build systems (cmake, cargo) | +2 |
| Heavy env manipulation (>5 exports) | +1 |
| Long scripts (>200 lines) | +1 |

- **High complexity**: Score >= 4
- **Medium complexity**: Score >= 2
- **Low complexity**: Score < 2

#### Example

```bash
# Analyze all scripts with priority sorting
./analyze_migration_candidates -b ~/build-scripts -o ./analysis --priority

# Analyze only Python scripts
./analyze_migration_candidates -b ~/build-scripts -l python -c
```

---

### filter_candidates

Filters migration candidates by language, distribution, and release version.

#### Usage

```bash
./filter_candidates [OPTIONS]
```

#### Options

| Option | Description |
|--------|-------------|
| `-l, --language <lang>` | Filter by language (python, node, go, java, ruby, php, r, conda) |
| `-d, --distro <distro>` | Filter by distro (rhel, ubi, ubuntu, debian, sles, centos, fedora) |
| `-r, --release <ver>` | Filter by release version (7, 8, 9, 9.3, 9.5, 20.04, etc.) |
| `-i, --input <file>` | Input candidates file (default: `./migration_analysis/migration_candidates.txt`) |
| `-o, --output <file>` | Output CSV file (default: stdout) |
| `-h, --help` | Show help message |

#### Distro Matching

The tool recognizes distribution families:

| Family | Matches |
|--------|---------|
| Red Hat | RHEL, UBI, CentOS, Fedora |
| Debian | Ubuntu, Debian |
| SUSE | SLES, openSUSE |

#### Release Matching

- **Single digit** (e.g., `9`) matches all minor versions (9, 9.3, 9.5)
- **Full version** (e.g., `9.5`) matches exactly

#### Output Format

CSV with columns:
```
package_name, package_version, language, language_version, script_name, status, complexity, priority
```

#### Example

```bash
# Filter Python scripts on UBI 9
./filter_candidates -l python -d ubi -r 9 -o python_ubi9.csv

# Filter all RHEL 8 scripts
./filter_candidates -d rhel -r 8 -o rhel8_scripts.csv

# Filter Go scripts on Ubuntu 20.04
./filter_candidates -l go -d ubuntu -r 20.04
```

---

### migrate_to_template

Converts legacy build scripts to the V2 template format.

#### Usage

```bash
./migrate_to_template [OPTIONS] [SCRIPT_OR_DIRECTORY]
```

#### Options

| Option | Description |
|--------|-------------|
| `-b, --base <dir>` | Old build-scripts source tree (required for `--batch`) |
| `-d, --dest <dir>` | Destination for generated scripts (default: `./migrated_scripts`) |
| `--template-dir <dir>` | V2 templates location (default: `../templates/`) |
| `--batch <file>` | Batch file (`.csv` or `.list`) with scripts to migrate |
| `-l, --language <lang>` | Override automatic language detection |
| `-r, --report` | Generate migration report |
| `-n, --dry-run` | Show what would be done without making changes |
| `-f, --force` | Overwrite existing migrated scripts |
| `-v, --verbose` | Verbose output |
| `--scan` | Scan and report only, don't migrate |

#### Operation Modes

**Single Script:**
```bash
./migrate_to_template path/to/script.sh
```

**Directory (all scripts):**
```bash
./migrate_to_template path/to/package/
```

**Batch Migration:**
```bash
./migrate_to_template -b ~/build-scripts --batch scripts.csv -d ./output
```

**Scan Only:**
```bash
./migrate_to_template --scan path/to/package/ -v
```

#### Migration Process

1. **Analysis** - Detects language, extracts metadata, identifies custom logic
2. **Complexity Assessment** - Classifies as simple, complex, or incomplete
3. **Script Generation** - Creates V2 template with callbacks for custom logic
4. **Asset Copy** - Copies referenced patch files and templates

#### Script Selection

When multiple scripts exist for a package, the tool selects the best one:

1. Prefers highest UBI/RHEL version (9.x > 8.x > 7.x)
2. Then highest package version
3. Consults `build_info.json` if available

#### Example

```bash
# Migrate single script
./migrate_to_template ~/build-scripts/p/django/django_ubi_9.3.sh -d ./output

# Batch migrate with report
./migrate_to_template -b ~/build-scripts --batch python.csv -d ./migrated -r

# Dry run to preview changes
./migrate_to_template -b ~/build-scripts --batch scripts.list --dry-run -v
```

---

### make-list.sh

Utility script to generate migration input lists from CSV files.

#### Usage

```bash
./make-list.sh <input.csv>
```

#### Process

1. Extracts 5th column (script names) from CSV
2. Deduplicates entries
3. Cross-references against `migration_analysis/migration_candidates.txt`
4. Outputs sorted unique script paths to `<basename>.list`

#### Example

```bash
./make-list.sh python_ubi9.csv
# Creates: python_ubi9.list
```

---

## Output Structure

After migration, the output directory contains:

```
migrated_scripts/
├── a/
│   └── ansible/
│       └── ansible.sh
├── p/
│   ├── pandas/
│   │   └── pandas.sh
│   └── pytorch/
│       └── pytorch.sh
├── templates/
│   ├── python.sh
│   ├── node.sh
│   ├── go.sh
│   ├── java.sh
│   ├── ruby.sh
│   ├── php.sh
│   ├── r.sh
│   ├── conda.sh
│   ├── lib/
│   │   ├── common.sh
│   │   ├── distro-packages.sh
│   │   ├── automation-stanzas.sh
│   │   └── prereq-checks.sh
│   └── examples/
│       └── ...
├── templates/template-tools/
│   ├── analyze_migration_candidates*
│   ├── filter_candidates*
│   ├── migrate_to_template*
│   └── data/
└── migration_report.md
```

---

## Template Format

Migrated scripts follow the V2 template structure:

```bash
#!/bin/bash -e
# ----------------------------------------------------------------------------
# Package: <package-name> v<version>
# Language: <language>
# Maintainer: <maintainer>
# Tested on: <distro and version>
# ----------------------------------------------------------------------------

PACKAGE_NAME="<name>"
PACKAGE_VERSION="${1:-<version>}"
PACKAGE_URL="<url>"

# Dependencies by distribution
RH_DEP_PKGS="git gcc python3"
DEB_DEP_PKGS="git gcc python3"
SLES_DEP_PKGS="git gcc python3"

# Optional callback functions (for custom logic)

pre_packages() {
    # Add repositories before package installation
}

post_clone() {
    # Apply patches after cloning repository
}

pre_build() {
    # Set environment variables before build
}

custom_test_command() {
    # Override default test execution
}

# Determine script directory and source the template
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../templates/python.sh"
```

### Callback Functions

| Callback | When Called | Use Case |
|----------|-------------|----------|
| `pre_packages()` | Before package installation | Add custom repositories |
| `post_clone()` | After git clone | Apply patches, modify source |
| `pre_build()` | Before build starts | Set environment variables |
| `custom_build_command()` | Replaces default build | Custom build process |
| `custom_test_command()` | Replaces default test | Custom test execution |
| `post_install()` | After installation | Cleanup, verification |

---

## Examples

### Complete Workflow Example

```bash
# Step 1: Activate virtual environment
source .venv/bin/activate

# Step 2: Analyze all scripts
./analyze_migration_candidates -b ~/build-scripts -o ./analysis --priority

# Step 3: Review summary
cat ./analysis/migration_summary.md

# Step 4: Filter Python scripts for UBI 9
./filter_candidates -l python -d ubi -r 9 -i ./analysis/migration_candidates.txt -o python_ubi9.csv

# Step 5: Generate list file
./make-list.sh python_ubi9.csv

# Step 6: Preview migration (dry run)
./migrate_to_template -b ~/build-scripts --batch python_ubi9.list --dry-run -v

# Step 7: Execute migration
./migrate_to_template -b ~/build-scripts --batch python_ubi9.list -d ./migrated -r

# Step 8: Review results
cat ./migrated/migration_report.md
```

### Quick Single-Script Migration

```bash
# Migrate one script with verbose output
./migrate_to_template ~/build-scripts/p/requests/requests_ubi_9.3.sh -d ./output -v
```

### Scan Without Migrating

```bash
# See what would be migrated
./migrate_to_template --scan ~/build-scripts/p/ -v
```

---

## Troubleshooting

### Virtual Environment Not Activated

**Error:** `Python virtual environment not found`

**Solution:**
```bash
python3.12 -m venv .venv
source .venv/bin/activate
```

### Missing Input File

**Error:** `Input file not found: ./migration_analysis/migration_candidates.txt`

**Solution:** Run `analyze_migration_candidates` first to generate the candidates file.

### Language Detection Failed

**Symptom:** Script marked as `unknown` language

**Solutions:**
1. Add explicit header comment to original script: `# Language: python`
2. Use `-l` flag to override: `./migrate_to_template -l python script.sh`

### Complex Migration Warning

**Symptom:** Migrated script contains `# WARNING: Complex migration - manual review required`

**Solution:** Review the generated script and verify:
- Callback functions contain correct custom logic
- Dependencies are complete
- Unhandled lines section is addressed

### Script Selection Issues

**Symptom:** Wrong script variant selected for migration

**Solution:**
1. Check `build_info.json` in the package directory
2. Use explicit script path instead of batch mode
3. Review `advanced_mapping.csv` for mapping details

---

## Reference Data Files

| File | Description |
|------|-------------|
| `advanced_mapping.csv` | Maps original scripts to migration outputs |
| `data/build-script-index.csv` | Complete script inventory |
| `pkg-lang.csv` | Package to language mapping |

---

## Support

For issues or questions:
1. Check the `migration_report.md` for specific failure details
2. Review verbose output with `-v` flag
3. Examine the `migration_analysis/` directory for analysis data
