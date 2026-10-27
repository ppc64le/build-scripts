# Version Fetchers

Fetch package versions from ecosystem registries (PyPI, npm, Maven, Packagist, Go, RubyGems).

---

## Quick Start

```bash
# Install dependencies
pip install requests

# Optional: Set GitHub token for better rate limits
export GITHUB_TOKEN=your_token_here

# Run a fetcher
python fetch_pypi_versions.py --count 10
```

---

## Available Fetchers

| Ecosystem | Script | Registry | Rate Limits |
|-----------|--------|----------|-------------|
| Python | `fetch_pypi_versions.py` | PyPI | None |
| Node.js | `fetch_npm_versions.py` | npm | None |
| Java | `fetch_maven_versions.py` | Maven Central | None |
| PHP | `fetch_packagist_versions.py` | Packagist | None |
| Go | `fetch_go_versions_enhanced.py` | Go Proxy + GitHub | None (proxy) |
| Ruby | `fetch_ruby_versions.py` | RubyGems | None |

---

## Usage

### Standard Arguments

All scripts support:
```bash
--input <file>      # Input CSV (default: ../version_data/{ecosystem}2.list)
--output <file>     # Output JSON (default: ../version_data/{ecosystem}_versions.json)
--errors <file>     # Error log (default: ../version_data/{ecosystem}_errors.json)
--start <n>         # Start index (default: 0)
--count <n>         # Number to fetch (default: all)
```

### Examples

```bash
# Fetch all Python packages
python fetch_pypi_versions.py

# Fetch first 100 npm packages
python fetch_npm_versions.py --count 100

# Custom input/output
python fetch_pypi_versions.py \
  --input custom.csv \
  --output versions.json \
  --errors errors.json
```

---

## Input Format

CSV with these columns:
```csv
base_dir,package_name,package_version,language,language_versions,script_path,package_url
```

Example:
```csv
e/express,express,4.18.0,Node,18.x 20.x,e/express/express.sh,https://github.com/expressjs/express
```

---

## Output Format

**Version Mapping** (`{ecosystem}_versions.json`):
```json
{
  "express": {
    "package_name": "express",
    "purl": "pkg:npm/express",
    "ecosystem": "node",
    "versions": ["4.18.0", "4.17.3", ...],
    "version_count": 285,
    "build_script_info": {
      "base_dir": "e/express",
      "package_version": "4.18.0",
      "script_path": "e/express/express.sh",
      "package_url": "https://github.com/expressjs/express"
    },
    "source": "npm",
    "fetched_at": "2026-01-13T10:30:00Z"
  }
}
```

**Error Log** (`{ecosystem}_errors.json`):
```json
{
  "invalid-pkg": {
    "package_name": "invalid-pkg",
    "ecosystem": "npm",
    "error_type": "not_found",
    "error_message": "Package not found",
    "timestamp": "2026-01-13T10:30:00Z"
  }
}
```

**Audit Log** (`{ecosystem}_no_versions.csv` and `.json`):
- Tracks packages with zero versions found
- See `Documentation/02-97-03-AUDIT_LOG_FORMAT.md` for details

---

## Features

✅ **Security**: Input validation, token masking, safe JSON parsing  
✅ **Audit Logging**: Tracks packages with no versions  
✅ **Error Handling**: Standardized error format with typed categories  
✅ **Statistics**: Real-time progress and success rates  
✅ **Caching**: Skips already-fetched packages  
✅ **Incremental**: Process in batches with `--start` and `--count`

---

## Documentation

- **QUICKSTART.md** - Step-by-step getting started guide
- **ARCHITECTURE.md** - Internal design and implementation details
- **Documentation/** - Comprehensive documentation (security, audit logs, data quality)

---

## Troubleshooting

**"File not found: {ecosystem}2.list"**
```bash
# Generate input files from build scripts
cd ../../97-Database-Dump
python extract_build_script_info.py \
  --input ~/src/build-scripts-v2 \
  --output build_scripts.csv

# Create ecosystem-specific lists
grep ',Python,' build_scripts.csv > ../02-DatabaseAPI/scripts/version_data/python2.list
```

**"GitHub rate limit exceeded"**
```bash
# Set token for 5000 requests/hour (vs 60 without)
export GITHUB_TOKEN=your_token_here
```

**"No versions found"**
- Check package name spelling
- Review error log for details
- Check audit log: `cat ../version_data/{ecosystem}_no_versions.csv`

---

## Security

All fetchers include:
- **Input validation** - Blocks path traversal and injection attacks
- **Token masking** - Credentials never exposed in logs
- **Safe parsing** - JSON size limits prevent memory exhaustion
- **Timeout protection** - 5-minute max per request

See `Documentation/02-97-06-SECURITY.md` for best practices.

---

## For Maintainers

### Adding New Ecosystem

1. Create fetcher class in `scripts/fetchers/`
2. Add validation rules to `scripts/utils/validation.py`
3. Create main script following existing pattern
4. Add to this README

### Running Tests

```bash
# Test with small dataset
python fetch_pypi_versions.py --count 5

# Verify security
grep -r "ghp_" . --exclude-dir=.git  # Should find nothing

# Check audit logs
ls -la ../version_data/*_no_versions.*
```

---

## Related Projects

- **extract_build_script_info.py** - Generates input CSV from build scripts
- **02-DatabaseAPI** - Database integration for version data
- **build-scripts-v2** - Source build scripts repository