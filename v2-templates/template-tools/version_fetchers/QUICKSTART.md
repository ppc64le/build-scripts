# Version Fetchers - Quick Start

Get package versions in 3 steps.

---

## Prerequisites

```bash
pip install requests

# Optional: Better GitHub rate limits
export GITHUB_TOKEN=your_token_here
```

---

## 3-Step Workflow

### Step 1: Extract Package Info

```bash
cd 97-Database-Dump
python extract_build_script_info.py \
  --input ~/src/build-scripts-v2 \
  --output build_scripts.csv

# Create ecosystem lists
grep ',Python,' build_scripts.csv > ../02-DatabaseAPI/scripts/version_data/python2.list
grep ',Node,' build_scripts.csv > ../02-DatabaseAPI/scripts/version_data/node2.list
grep ',Java,' build_scripts.csv > ../02-DatabaseAPI/scripts/version_data/java2.list
grep ',PHP,' build_scripts.csv > ../02-DatabaseAPI/scripts/version_data/php2.list
grep ',Go,' build_scripts.csv > ../02-DatabaseAPI/scripts/version_data/go2.list
grep ',Ruby,' build_scripts.csv > ../02-DatabaseAPI/scripts/version_data/ruby2.list
```

### Step 2: Fetch Versions

```bash
cd ../02-DatabaseAPI/scripts/version_fetchers

# Run fetchers (fast, no rate limits)
python fetch_pypi_versions.py
python fetch_npm_versions.py
python fetch_maven_versions.py
python fetch_packagist_versions.py
python fetch_go_versions_enhanced.py
python fetch_ruby_versions.py
```

### Step 3: View Results

```bash
# Check version counts
jq '.express.version_count' ../version_data/npm_versions.json

# Check errors
jq 'keys | length' ../version_data/npm_errors.json

# View audit logs (packages with no versions)
cat ../version_data/npm_no_versions.csv
```

---

## Common Patterns

### Process in Batches

```bash
# First 100 packages
python fetch_npm_versions.py --start 0 --count 100

# Next 100
python fetch_npm_versions.py --start 100 --count 100
```

### Custom Files

```bash
python fetch_pypi_versions.py \
  --input custom.csv \
  --output versions.json \
  --errors errors.json
```

### Test Run

```bash
# Test with 5 packages
python fetch_npm_versions.py --count 5
```

---

## Output Files

Each fetcher creates 3 files:

1. **Versions**: `{ecosystem}_versions.json` - All package versions
2. **Errors**: `{ecosystem}_errors.json` - Failed packages
3. **Audit**: `{ecosystem}_no_versions.csv` + `.json` - Packages with no versions

---

## Troubleshooting

**"File not found"**
```bash
# Run Step 1 first to generate input files
cd 97-Database-Dump
python extract_build_script_info.py --input ~/src/build-scripts-v2 --output build_scripts.csv
```

**"Rate limit exceeded"**
```bash
# Set GitHub token (5000 req/hr vs 60)
export GITHUB_TOKEN=your_token_here
```

**"No versions found"**
- Check package name spelling
- Review error log: `jq '.' {ecosystem}_errors.json`
- Check audit log: `cat {ecosystem}_no_versions.csv`

---

## Next Steps

- **Full docs**: See [README.md](README.md)
- **Architecture**: See [ARCHITECTURE.md](ARCHITECTURE.md)
- **Security**: See [Documentation/02-97-06-SECURITY.md](Documentation/02-97-06-SECURITY.md)
