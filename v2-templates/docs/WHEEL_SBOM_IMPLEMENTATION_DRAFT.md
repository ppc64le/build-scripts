# Wheel SBOM Implementation - Complete

**Status: IMPLEMENTED - Ready for testing**

## Implementation Summary

Created `templates/lib/wheel-sbom.sh` (bash) and integrated into python.sh.

### Files Modified/Created

1. **NEW: `templates/lib/wheel-sbom.sh`** - Main SBOM generation library
2. **MODIFIED: `templates/python.sh`** - Added source and call
3. **KEPT: `templates/lib/wheel-sbom.py`** - Reference implementation (not used)

### Integration Point

```bash
# In python.sh, after auditwheel repair:
process_bundled_licenses wheelhouse/*.whl  # existing
generate_wheel_sbom wheelhouse/*.whl       # NEW
```

### Output Files

Generated in `${OUTPUT_DIR}/`:
- `<wheel_name>.sbom.json` - CycloneDX 1.5 SBOM
- `<wheel_name>.summary.json` - CI-friendly summary
- `<wheel_name>.cves.json` - CVE findings (only if CVEs found)

---

## Features Implemented

| Feature | Status | Notes |
|---------|--------|-------|
| Wheel METADATA extraction | ✅ | Name, version, license, author, homepage, Requires-Dist |
| Clear SPDX license detection | ✅ | BSD-2/3/4, AGPL versions, etc. properly distinguished |
| Full license text capture | ✅ | Extracted when SPDX is ambiguous |
| Binary inventory | ✅ | All .so files with SHA-256 hashes |
| RPM provenance | ✅ | rpm -qf lookup with license extraction |
| Artifact system check | ✅ | Checks ${ARTIFACT_DIR}/*/manifest.json |
| pip-audit integration | ✅ | Auto-installs if not present |
| cve-bin-tool integration | ✅ | Auto-installs if not present |
| CycloneDX output | ✅ | Version 1.5 format |
| Summary JSON | ✅ | CI-friendly with binary source counts |
| Red flags | ✅ | Missing licenses flagged, requires_manual_review field |
| Never-fail design | ✅ | All errors become warnings, always produces output |

---

## Red Flag Conditions

The `requires_manual_review: true` flag is set when:
- Any binary has unknown provenance
- Package has no license declared
- License is non-SPDX and no full text found
- Any CRITICAL or HIGH severity CVE found

---

## Tool Requirements

**Required (should already be in container):**
- `jq` - JSON processing
- `unzip` - Wheel extraction
- `sha256sum` - Hash computation

**Auto-installed via pip (if not present):**
- `pip-audit` - Python CVE detection
- `cve-bin-tool` - Binary CVE detection

If pip install fails for either tool, a warning is logged and that CVE check is skipped (never fails the build).

---

## Testing Checklist

- [ ] Build a package with bundled .so files (e.g., numpy)
- [ ] Verify .sbom.json is valid CycloneDX
- [ ] Verify .summary.json has correct binary counts
- [ ] Test with package that has known CVEs
- [ ] Test with package missing license
- [ ] Verify jq absence gracefully degrades
- [ ] Verify pip-audit/cve-bin-tool auto-install works

---

## Notes for Post-Processing

The summary.json structure:
```json
{
    "wheel": "numpy-1.26.0-cp311-linux_ppc64le.whl",
    "package": "numpy==1.26.0",
    "license": "BSD-3-Clause",
    "dependencies": 0,
    "bundled_binaries": 47,
    "binary_sources": {
        "rpm": 12,
        "artifact": 0,
        "source_built": 35,
        "unknown": 0
    },
    "cves": {
        "total": 0,
        "critical": 0,
        "high": 0
    },
    "red_flags": 0,
    "requires_manual_review": false,
    "generated_at": "2026-03-29T21:30:00Z"
}
```

---
*Implementation completed: 2026-03-29*
