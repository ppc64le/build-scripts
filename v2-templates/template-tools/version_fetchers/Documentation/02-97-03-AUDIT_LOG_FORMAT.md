# Audit Logger Output Format Specification

**Version**: 1.0  
**Date**: 2026-01-13

---

## Overview

The audit logger produces **dual-format output** for maximum flexibility:
1. **CSV** - Human-readable, spreadsheet-compatible
2. **JSON** - Machine-readable, programmatically parseable

Both formats contain identical data, allowing you to choose the best format for your use case.

---

## Output Files

### File Naming Convention

```
{ecosystem}_no_versions.csv
{ecosystem}_no_versions.json
```

**Examples**:
- `pypi_no_versions.csv` / `pypi_no_versions.json`
- `npm_no_versions.csv` / `npm_no_versions.json`
- `maven_no_versions.csv` / `maven_no_versions.json`
- `packagist_no_versions.csv` / `packagist_no_versions.json`
- `go_no_versions.csv` / `go_no_versions.json`
- `rubygems_no_versions.csv` / `rubygems_no_versions.json`

---

## CSV Format

### Structure

**Standard Fields** (always present):
```csv
timestamp,package_name,ecosystem,attempted_sources,package_url,script_path,notes
```

**Example**:
```csv
timestamp,package_name,ecosystem,attempted_sources,package_url,script_path,notes
2026-01-13T15:30:00Z,express,npm,"npm_registry",https://github.com/expressjs/express,/build-scripts/e/express/express.sh,
2026-01-13T15:31:00Z,flask,pypi,"pypi_api",https://github.com/pallets/flask,/build-scripts/f/flask/flask.sh,
```

### Field Descriptions

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `timestamp` | ISO 8601 UTC | When the package was logged | `2026-01-13T15:30:00Z` |
| `package_name` | String | Package identifier | `express`, `com.auth0:java-jwt` |
| `ecosystem` | String | Package ecosystem | `npm`, `pypi`, `maven`, `packagist`, `go`, `rubygems` |
| `attempted_sources` | Comma-separated | Sources that were tried | `npm_registry`, `pypi_api,github` |
| `package_url` | URL | Repository URL (if available) | `https://github.com/expressjs/express` |
| `script_path` | Path | Build script location | `/build-scripts/e/express/express.sh` |
| `notes` | String | Additional metadata (JSON-encoded) | `{"module_path":"github.com/..."}` |

### Machine Processing CSV

**Python Example**:
```python
import csv

with open('npm_no_versions.csv', 'r') as f:
    reader = csv.DictReader(f)
    for row in reader:
        package = row['package_name']
        sources = row['attempted_sources'].split(',')
        timestamp = row['timestamp']
        print(f"{package}: tried {sources} at {timestamp}")
```

**Bash Example**:
```bash
# Count packages with no versions per ecosystem
wc -l *_no_versions.csv

# Extract package names
cut -d',' -f2 npm_no_versions.csv | tail -n +2

# Find packages that tried multiple sources
grep -E ',[^,]+,[^,]+,' npm_no_versions.csv
```

---

## JSON Format

### Structure

**Array of Objects**:
```json
[
  {
    "timestamp": "2026-01-13T15:30:00Z",
    "package_name": "express",
    "ecosystem": "npm",
    "attempted_sources": ["npm_registry"],
    "package_url": "https://github.com/expressjs/express",
    "script_path": "/build-scripts/e/express/express.sh"
  },
  {
    "timestamp": "2026-01-13T15:31:00Z",
    "package_name": "flask",
    "ecosystem": "pypi",
    "attempted_sources": ["pypi_api"],
    "package_url": "https://github.com/pallets/flask",
    "script_path": "/build-scripts/f/flask/flask.sh"
  }
]
```

### Field Types

| Field | JSON Type | Description |
|-------|-----------|-------------|
| `timestamp` | String (ISO 8601) | UTC timestamp |
| `package_name` | String | Package identifier |
| `ecosystem` | String | Lowercase ecosystem name |
| `attempted_sources` | Array of Strings | List of sources tried |
| `package_url` | String | Repository URL (empty string if N/A) |
| `script_path` | String | Build script path (empty string if N/A) |
| **Additional fields** | Various | Ecosystem-specific metadata |

### Ecosystem-Specific Fields

#### Go Packages
```json
{
  "package_name": "github.com/gin-gonic/gin",
  "ecosystem": "go",
  "attempted_sources": ["go_proxy", "github"],
  "module_path": "github.com/gin-gonic/gin",
  "base_dir": "g/gin-gonic__gin",
  "package_version": "1.9.0",
  "language_versions": "go1.20"
}
```

#### Maven Packages
```json
{
  "package_name": "com.auth0:java-jwt",
  "ecosystem": "maven",
  "attempted_sources": ["maven_central"],
  "group_id": "com.auth0",
  "artifact_id": "java-jwt"
}
```

### Machine Processing JSON

**Python Example**:
```python
import json

# Load all audit logs
with open('npm_no_versions.json', 'r') as f:
    npm_logs = json.load(f)

# Filter by criteria
recent = [log for log in npm_logs 
          if log['timestamp'] > '2026-01-13T00:00:00Z']

# Group by attempted sources
from collections import defaultdict
by_source = defaultdict(list)
for log in npm_logs:
    sources = tuple(log['attempted_sources'])
    by_source[sources].append(log['package_name'])

# Count packages per ecosystem
print(f"npm packages with no versions: {len(npm_logs)}")
```

**jq Examples**:
```bash
# Count total packages
jq 'length' npm_no_versions.json

# Extract package names
jq '.[].package_name' npm_no_versions.json

# Filter by date
jq '.[] | select(.timestamp > "2026-01-13T00:00:00Z")' npm_no_versions.json

# Group by attempted sources
jq 'group_by(.attempted_sources) | map({sources: .[0].attempted_sources, count: length})' npm_no_versions.json

# Find packages with GitHub URLs
jq '.[] | select(.package_url | contains("github"))' npm_no_versions.json
```

**Node.js Example**:
```javascript
const fs = require('fs');

// Load audit log
const logs = JSON.parse(fs.readFileSync('npm_no_versions.json', 'utf8'));

// Analyze
const stats = {
  total: logs.length,
  withGitHub: logs.filter(l => l.package_url.includes('github')).length,
  multiSource: logs.filter(l => l.attempted_sources.length > 1).length
};

console.log(stats);
```

---

## Data Integrity

### Guarantees

1. **Thread-Safe**: Multiple processes can log simultaneously
2. **Atomic Writes**: Each log entry is written atomically
3. **No Duplicates**: Same package won't be logged twice in same run
4. **Consistent Format**: All entries follow same schema

### Validation

**Check JSON validity**:
```bash
jq empty npm_no_versions.json && echo "Valid JSON" || echo "Invalid JSON"
```

**Check CSV structure**:
```bash
# Verify header
head -1 npm_no_versions.csv

# Count fields per row (should all be same)
awk -F',' '{print NF}' npm_no_versions.csv | sort | uniq -c
```

---

## Use Cases

### 1. Security Audits

**Find packages with no versions for manual review**:
```bash
# CSV approach
cut -d',' -f2,5 npm_no_versions.csv | grep github

# JSON approach
jq '.[] | {name: .package_name, url: .package_url}' npm_no_versions.json
```

### 2. Data Quality Monitoring

**Track failure rates over time**:
```python
import json
from datetime import datetime
from collections import Counter

# Load logs
with open('npm_no_versions.json') as f:
    logs = json.load(f)

# Group by date
by_date = Counter()
for log in logs:
    date = log['timestamp'][:10]  # Extract YYYY-MM-DD
    by_date[date] += 1

# Plot trend
for date, count in sorted(by_date.items()):
    print(f"{date}: {count} packages")
```

### 3. Source Reliability Analysis

**Which sources fail most often**:
```bash
# JSON approach
jq '.[] | .attempted_sources[]' npm_no_versions.json | sort | uniq -c | sort -rn
```

### 4. Build Script Correlation

**Find build scripts with missing packages**:
```bash
# Extract script paths
jq -r '.[].script_path' npm_no_versions.json | sort | uniq

# Count by directory
jq -r '.[].script_path' npm_no_versions.json | xargs -n1 dirname | sort | uniq -c
```

---

## Integration Examples

### Database Import

**PostgreSQL**:
```sql
CREATE TABLE audit_no_versions (
    timestamp TIMESTAMPTZ,
    package_name TEXT,
    ecosystem TEXT,
    attempted_sources TEXT[],
    package_url TEXT,
    script_path TEXT,
    metadata JSONB
);

-- Import from JSON
COPY audit_no_versions FROM PROGRAM 
'jq -c ".[]" npm_no_versions.json' 
WITH (FORMAT json);
```

**SQLite**:
```bash
sqlite3 audit.db <<EOF
CREATE TABLE no_versions (
    timestamp TEXT,
    package_name TEXT,
    ecosystem TEXT,
    attempted_sources TEXT,
    package_url TEXT,
    script_path TEXT
);

.mode csv
.import npm_no_versions.csv no_versions
EOF
```

### Elasticsearch

```python
from elasticsearch import Elasticsearch
import json

es = Elasticsearch(['localhost:9200'])

with open('npm_no_versions.json') as f:
    logs = json.load(f)

for log in logs:
    es.index(index='audit-no-versions', document=log)
```

### Prometheus Metrics

```python
from prometheus_client import Gauge
import json

no_versions_gauge = Gauge(
    'package_no_versions_total',
    'Packages with no versions found',
    ['ecosystem']
)

# Update metrics
for ecosystem in ['npm', 'pypi', 'maven', 'packagist', 'go', 'rubygems']:
    try:
        with open(f'{ecosystem}_no_versions.json') as f:
            count = len(json.load(f))
            no_versions_gauge.labels(ecosystem=ecosystem).set(count)
    except FileNotFoundError:
        pass
```

---

## Summary

### Quick Reference

| Format | Best For | Tools |
|--------|----------|-------|
| **CSV** | Spreadsheets, simple scripts, human review | Excel, `awk`, `cut`, `grep` |
| **JSON** | Complex queries, APIs, databases | `jq`, Python, Node.js, databases |

### Key Features

✅ **Dual Format**: CSV + JSON for maximum flexibility  
✅ **Machine-Readable**: Structured, parseable data  
✅ **Human-Readable**: CSV can be opened in Excel  
✅ **Extensible**: Additional fields via metadata  
✅ **Thread-Safe**: Safe for concurrent access  
✅ **Timestamped**: Track when issues occurred  
✅ **Ecosystem-Specific**: Custom fields per package type

### File Locations

All audit logs are written to: `02-DatabaseAPI/scripts/version_data/`

```
version_data/
├── pypi_no_versions.csv
├── pypi_no_versions.json
├── npm_no_versions.csv
├── npm_no_versions.json
├── maven_no_versions.csv
├── maven_no_versions.json
├── packagist_no_versions.csv
├── packagist_no_versions.json
├── go_no_versions.csv
├── go_no_versions.json
├── rubygems_no_versions.csv
└── rubygems_no_versions.json