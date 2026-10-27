# Wheel SBOM & CVE Detection - Operations Guide

## Overview

The wheel SBOM system automatically generates Software Bill of Materials (SBOM) and CVE reports for every Python wheel built through the template system. This enables:

- **Legal compliance**: Track all bundled components and their licenses
- **Security posture**: Detect known vulnerabilities before release
- **Audit trail**: Machine-readable provenance for every artifact

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                        python.sh template                            │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  1. Clone & Build                                                    │
│         ↓                                                            │
│  2. python -m build --wheel                                          │
│         ↓                                                            │
│  3. auditwheel repair  ──────────────────────────────────────────┐  │
│         ↓                                                         │  │
│  4. process_bundled_licenses()  ← bundled-license-utils.sh       │  │
│         ↓                                    │                    │  │
│  5. generate_wheel_sbom()  ← wheel-sbom.sh ──┘                    │  │
│         │                                                         │  │
│         ├── Extract wheel metadata                                │  │
│         ├── Scan all .so binaries                                 │  │
│         ├── Resolve RPM/artifact provenance                       │  │
│         ├── Run pip-audit (Python CVEs)                           │  │
│         ├── Run cve-bin-tool (binary CVEs)                        │  │
│         └── Generate outputs to ${OUTPUT_DIR}/                    │  │
│                  │                                                │  │
│                  ├── <wheel>.sbom.json     (CycloneDX)           │  │
│                  ├── <wheel>.summary.json  (CI/CD)               │  │
│                  └── <wheel>.cves.json     (if CVEs found)       │  │
│                                                                      │
│  6. pip install wheel                                                │
│         ↓                                                            │
│  7. Run tests                                                        │
│         ↓                                                            │
│  8. Copy artifacts to ${OUTPUT_DIR}/artifacts/                      │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              ↓
              ┌───────────────────────────────┐
              │   External Post-Processing    │
              │   (picks up from OUTPUT_DIR)  │
              └───────────────────────────────┘
```

---

## Files Involved

| File | Purpose |
|------|---------|
| `templates/lib/wheel-sbom.sh` | Main SBOM generation library |
| `templates/lib/bundled-license-utils.sh` | License extraction (runs before SBOM) |
| `templates/python.sh` | Integration point (sources and calls both) |
| `templates/docs/WHEEL_SBOM_STRATEGY.md` | Design rationale |
| `templates/docs/CVE_REBUILD_STRATEGY.md` | CVE tracking architecture |
| `templates/lib/wheel-sbom.py` | Reference implementation (not used in production) |

---

## Output Files

### 1. CycloneDX SBOM (`<wheel>.sbom.json`)

Machine-readable SBOM in CycloneDX 1.5 format.

```json
{
    "bomFormat": "CycloneDX",
    "specVersion": "1.5",
    "serialNumber": "urn:uuid:...",
    "version": 1,
    "metadata": {
        "timestamp": "2026-03-30T12:00:00Z",
        "tools": [{"name": "wheel-sbom", "version": "1.0.0"}],
        "component": {
            "type": "library",
            "name": "numpy",
            "version": "1.26.0",
            "purl": "pkg:pypi/numpy@1.26.0"
        }
    },
    "components": [
        {
            "type": "library",
            "name": "libopenblas.so.0",
            "hashes": [{"alg": "SHA-256", "content": "abc123..."}],
            "properties": [{"name": "source", "value": "rpm"}],
            "licenses": [{"license": {"name": "BSD-3-Clause"}}]
        }
    ],
    "vulnerabilities": []
}
```

### 2. Summary JSON (`<wheel>.summary.json`)

CI/CD-friendly summary for automation decisions.

```json
{
    "wheel": "numpy-1.26.0-cp311-linux_ppc64le.whl",
    "package": "numpy==1.26.0",
    "license": "BSD-3-Clause",
    "license_expression": "",
    "dependencies": 0,
    "bundled_binaries": 47,
    "binary_sources": {
        "rpm": 12,
        "artifact": 3,
        "source_built": 32,
        "unknown": 0
    },
    "cves": {
        "total": 0,
        "critical": 0,
        "high": 0
    },
    "red_flags": 0,
    "warnings": 2,
    "requires_manual_review": false,
    "generated_at": "2026-03-30T12:00:00Z"
}
```

**Key fields for automation:**
- `requires_manual_review`: true if any red flags, unknown binaries, missing license, or high/critical CVEs
- `cves.critical` / `cves.high`: Use for go/no-go decisions
- `binary_sources.unknown`: Non-zero indicates provenance gaps

### 3. CVE Report (`<wheel>.cves.json`)

Only generated if vulnerabilities are found.

```json
[
    {
        "cve_id": "CVE-2024-12345",
        "severity": "HIGH",
        "component": "libssl",
        "component_version": "3.0.12",
        "description": "Buffer overflow in...",
        "fixed_versions": ["3.0.13"]
    }
]
```

---

## Binary Provenance Resolution

For each `.so` file found in the wheel, the system determines its source:

| Source | How Detected | Implications |
|--------|--------------|--------------|
| `rpm` | `rpm -qf` finds owning package | License from RPM metadata |
| `artifact` | Found in `${ARTIFACT_DIR}/*/` | License from manifest.json |
| `source-built` | Not found in system or artifacts | Built from source during wheel build |
| `unknown` | Detection failed | **Red flag** - requires investigation |

### Resolution Order

1. Check if library exists in system paths (`/usr/lib64`, `/usr/lib`, `/lib64`, `/lib`)
2. If found, query RPM ownership with `rpm -qf`
3. If not RPM-owned, search artifact directories
4. If not in artifacts, mark as `source-built`
5. If detection fails entirely, mark as `unknown`

---

## CVE Detection

### pip-audit (Python Packages)

Checks the package and version against Python vulnerability databases (PyPI, OSV).

```bash
# What it runs internally:
pip-audit -r <temp_requirements.txt> --format json
```

### cve-bin-tool (Binaries)

Scans bundled binaries for known vulnerable library versions.

```bash
# What it runs internally:
cve-bin-tool --format json <wheel_path>
```

### Tool Installation

Both tools are auto-installed via pip if not present:
```bash
pip install pip-audit cve-bin-tool
```

If installation fails, a warning is logged and that check is skipped (build continues).

---

## Red Flags

The system flags issues requiring manual review:

| Condition | Red Flag Message |
|-----------|------------------|
| No license in METADATA | "No license declared in package metadata" |
| Ambiguous license, no text | "License 'X' requires full text but none found" |
| Binary with no license | "No license found for binary: libfoo.so (source: X)" |
| Package name missing | "Package name not found in METADATA" |
| Package version missing | "Package version not found in METADATA" |

Red flags appear in:
- Build logs: `[SBOM RED FLAG] ...`
- Summary JSON: `"red_flags": N`
- Summary JSON: `"requires_manual_review": true`

---

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `OUTPUT_DIR` | `${PWD}/output` | Where SBOM files are written |
| `ARTIFACT_DIR` | `/opt/artifacts` | Where to look for artifact manifests |
| `SBOM_SPEC_VERSION` | `1.5` | CycloneDX spec version |

### Disabling SBOM Generation

To skip SBOM generation for a specific build, comment out or wrap the call in python.sh:

```bash
# In python.sh, around line 275:
# generate_wheel_sbom wheelhouse/*.whl  # Disabled
```

Or conditionally:
```bash
if [[ "${SKIP_SBOM:-false}" != "true" ]]; then
    generate_wheel_sbom wheelhouse/*.whl
fi
```

---

## Testing Guide

### Manual Testing

1. **Build a package with bundled binaries:**
   ```bash
   ./n/numpy/numpy.sh v1.26.0
   ```

2. **Check outputs exist:**
   ```bash
   ls -la ${OUTPUT_DIR}/*.sbom.json
   ls -la ${OUTPUT_DIR}/*.summary.json
   ```

3. **Validate CycloneDX format:**
   ```bash
   # Install validator
   pip install cyclonedx-bom

   # Validate
   cyclonedx validate --input-file ${OUTPUT_DIR}/numpy-*.sbom.json
   ```

4. **Check summary for issues:**
   ```bash
   jq '.requires_manual_review, .red_flags, .cves' ${OUTPUT_DIR}/numpy-*.summary.json
   ```

### Test Cases

| Test Case | Package | Expected Result |
|-----------|---------|-----------------|
| Package with many .so files | numpy | 40+ binaries in summary |
| Package with known CVE | pillow (old version) | CVEs in .cves.json |
| Package with clear license | requests | `requires_manual_review: false` |
| Package without license | (custom) | Red flag for missing license |
| Pure Python package | six | 0 bundled_binaries |

### Verifying CVE Detection

```bash
# Build an intentionally old package with known CVEs
./p/pillow/pillow.sh v9.0.0

# Check for CVE report
cat ${OUTPUT_DIR}/pillow-*.cves.json

# Verify summary shows CVEs
jq '.cves' ${OUTPUT_DIR}/pillow-*.summary.json
```

---

## Troubleshooting

### No SBOM files generated

**Symptoms:** Build completes but no `.sbom.json` files in OUTPUT_DIR

**Checks:**
1. Was a wheel actually built? Check for `wheelhouse/*.whl`
2. Is OUTPUT_DIR writable?
3. Check build log for `[SBOM]` messages
4. Verify wheel-sbom.sh is sourced (check python.sh line ~71)

### jq errors in logs

**Symptoms:** Warnings about jq, malformed JSON output

**Fix:** Ensure jq is installed in the container base image:
```bash
dnf install -y jq  # or apt-get install jq
```

### pip-audit/cve-bin-tool not working

**Symptoms:** Warnings about tools not available, CVE arrays empty

**Checks:**
1. Is pip available in the venv?
2. Network access for pip install?
3. Check: `pip install pip-audit cve-bin-tool` manually

**Note:** Missing CVE tools don't fail the build - they log warnings and skip.

### All binaries showing as "unknown"

**Symptoms:** `binary_sources.unknown` equals total binary count

**Likely cause:** Not running on RHEL/UBI (rpm not available)

**Fix:** This is expected on non-RPM systems. Binaries will be marked source-built or unknown. For accurate provenance, run on UBI/RHEL.

### Red flags for valid licenses

**Symptoms:** BSD-3-Clause or similar flagged as needing full text

**Check:** The `_is_clear_spdx_license()` function in wheel-sbom.sh. May need to add more recognized SPDX identifiers.

---

## Maintenance

### Adding New SPDX License Recognition

Edit `_is_clear_spdx_license()` in wheel-sbom.sh:

```bash
_is_clear_spdx_license() {
    local license="$1"
    local lic_upper="${license^^}"

    case "$lic_upper" in
        # Add new clear licenses here:
        MIT|ISC|UNLICENSE|CC0-1.0|WTFPL|0BSD)
            return 0
            ;;
        # ...
    esac
}
```

### Updating CycloneDX Version

Change the spec version in wheel-sbom.sh:
```bash
: "${SBOM_SPEC_VERSION:=1.6}"  # Update to new version
```

Ensure the generated JSON structure matches the new spec.

### Adding New Provenance Sources

To add a new source type (e.g., checking a different artifact location):

1. Add detection logic in `_scan_wheel_binaries()`
2. Add the source type to the case statement in `_generate_summary()`
3. Update documentation

---

## Integration with External Systems

### Post-Processing Pipeline

The external system should:

1. **Monitor OUTPUT_DIR** for new `.summary.json` files
2. **Parse summary** for automation decisions:
   ```python
   if summary['cves']['critical'] > 0:
       block_release()
   if summary['requires_manual_review']:
       create_review_ticket()
   ```
3. **Store SBOM** in artifact registry for later queries
4. **Index components** for CVE monitoring (see CVE_REBUILD_STRATEGY.md)

### Example: CI/CD Integration

```yaml
# In CI pipeline after build:
- name: Check SBOM results
  run: |
    SUMMARY=$(cat ${OUTPUT_DIR}/*.summary.json)
    CRITICAL=$(echo "$SUMMARY" | jq '.cves.critical')
    if [ "$CRITICAL" -gt 0 ]; then
      echo "::error::Critical CVEs found!"
      exit 1
    fi
    if [ "$(echo "$SUMMARY" | jq '.requires_manual_review')" == "true" ]; then
      echo "::warning::Manual review required"
    fi
```

---

## Related Documentation

- `WHEEL_SBOM_STRATEGY.md` - Design decisions and approach evaluation
- `CVE_REBUILD_STRATEGY.md` - Full CVE tracking and rebuild architecture
- `WHEEL_LICENSE_GAPS.md` - Known issues with license detection on non-RPM systems

---

*Last updated: 2026-03-30*
