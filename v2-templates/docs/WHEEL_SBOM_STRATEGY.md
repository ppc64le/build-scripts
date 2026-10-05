# Wheel SBOM Strategy Discussion

## Problem Statement

Python wheels on ppc64le often bundle shared libraries (`.so` files) that come from:
1. System RPMs (copied into the wheel)
2. Source-built dependencies (compiled during wheel build)
3. Vendored third-party code

For legal compliance and customer confidence, we need complete provenance tracking for ALL components.

## Evaluation of Approaches

### Approach 1: Custom RPM-focused Script

A custom Python script that:
1. Scans `.libs/` directory for `.so` files
2. Uses `find` to locate matching system files
3. Uses `rpm -qf` to find owning RPM package
4. Generates CycloneDX SBOM

**Strengths:**
- RPM provenance tracking (knows exactly which RPM provided each .so)
- Simple, focused implementation
- Works offline

**Critical Gaps:**
- Does NOT scan wheel METADATA (missing package identity!)
- Does NOT capture Python dependencies (Requires-Dist)
- Does NOT detect CVEs
- Does NOT scan extension modules outside `.libs/`
- Does NOT capture license text
- No file hashes for integrity verification

### Approach 2: Toolchain (cve-bin-tool + syft + grype)

Uses multiple tools:
- `pip-audit` for Python CVEs
- `cve-bin-tool` for binary CVE detection
- `syft` + `grype` for SBOM generation and scanning

**Strengths:**
- CVE detection for both Python packages and binaries
- Industry-standard tooling
- Active maintenance and vulnerability DB updates

**Critical Gaps:**
- No RPM provenance tracking
- `syft` doesn't understand wheel structure well
- May miss connection between wheel and its bundled libs
- License detection is incomplete

## Recommended Hybrid Approach

Combine both approaches:

```
┌─────────────────────────────────────────────────────────────┐
│                     WHEEL FILE (.whl)                        │
├─────────────────────────────────────────────────────────────┤
│  1. METADATA Extraction (wheel identity)                     │
│     ├── Name, Version, License                               │
│     ├── Requires-Dist (dependencies)                         │
│     └── Author, Homepage                                     │
├─────────────────────────────────────────────────────────────┤
│  2. LICENSE File Capture                                     │
│     └── Full text for legal compliance                       │
├─────────────────────────────────────────────────────────────┤
│  3. Binary Inventory (ALL .so files)                         │
│     ├── Extension modules (*.cpython-*.so)                   │
│     ├── Bundled libs (*.libs/*.so)                          │
│     └── SHA-256 hashes for each                              │
├─────────────────────────────────────────────────────────────┤
│  4. RPM Provenance (for each .so)                           │
│     ├── rpm -qf lookup                                       │
│     ├── RPM name, version, license                           │
│     └── Flag if NOT from RPM (source-built)                  │
├─────────────────────────────────────────────────────────────┤
│  5. CVE Detection                                            │
│     ├── cve-bin-tool on binaries                            │
│     ├── pip-audit on Python deps                            │
│     └── Aggregate results                                    │
├─────────────────────────────────────────────────────────────┤
│  6. Output                                                   │
│     ├── CycloneDX SBOM (machine-readable)                   │
│     ├── Summary JSON (CI/CD integration)                    │
│     └── "Needs Manual Review" flag                          │
└─────────────────────────────────────────────────────────────┘
```

## Component Coverage Matrix

| Component Type | Approach 1 | Approach 2 | Hybrid |
|----------------|-----------|-----------|--------|
| Wheel package identity | ❌ | ✅ | ✅ |
| Python dependencies | ❌ | ✅ | ✅ |
| Python CVEs | ❌ | ✅ | ✅ |
| Extension modules (.cpython-*.so) | ❌ | ⚠️ | ✅ |
| Bundled libs in .libs/ | ✅ | ✅ | ✅ |
| RPM provenance chain | ✅ | ❌ | ✅ |
| Binary CVEs | ❌ | ✅ | ✅ |
| License text capture | ❌ | ⚠️ | ✅ |
| File hashes (integrity) | ❌ | ⚠️ | ✅ |
| "Needs manual review" flag | ❌ | ❌ | ✅ |

## Implementation Location

The hybrid script should be integrated into the Python build template:

```
templates/
├── python.sh                    # Main Python template
├── lib/
│   ├── common.sh
│   └── wheel-sbom.py           # <-- New: SBOM generator
└── docs/
    └── WHEEL_SBOM_STRATEGY.md  # This document
```

## Output Artifacts

For each wheel built, produce:

```
output/
├── package-1.0.0-cp311-cp311-linux_ppc64le.whl
├── package-1.0.0.sbom.json      # Full CycloneDX SBOM
├── package-1.0.0.summary.json   # CI-friendly summary
└── package-1.0.0.cves.json      # CVE report (if any found)
```

## CI/CD Integration

The summary JSON enables automated decisions:

```json
{
  "wheel": "numpy-1.26.0-cp311-cp311-linux_ppc64le.whl",
  "package": "numpy==1.26.0",
  "license": "BSD-3-Clause",
  "dependencies": 0,
  "bundled_binaries": 47,
  "rpm_sourced": 12,
  "source_built": 35,
  "cves_found": 0,
  "requires_manual_review": true
}
```

CI can then:
- Fail build if `cves_found > 0` with severity >= HIGH
- Flag for legal review if `requires_manual_review: true`
- Track `source_built` count for compliance reporting

## Open Questions

1. **Version detection for source-built libs**: How do we determine the version of a statically-linked library? Options:
   - Parse `strings` output for version patterns
   - Maintain a mapping of wheel versions to known lib versions
   - Require build scripts to declare bundled versions

2. **License compatibility checking**: Should we integrate license compatibility analysis (e.g., GPL + BSD mixing)?

3. **SBOM signing**: Should we sign SBOMs for tamper detection?

4. **Storage and indexing**: Where do SBOMs live long-term for customer queries?

---
*Document created: 2024 | Status: DRAFT for discussion*
