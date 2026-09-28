# SBOM & CVE Output Files

## Output Location

All files are written to `${OUTPUT_DIR}/` (default: `${PWD}/output`).

## Generated Files

| Filename | Format | Description |
|----------|--------|-------------|
| `<wheel>.sbom.json` | CycloneDX 1.5 | Full SBOM with components, licenses, vulnerabilities |
| `<wheel>.summary.json` | JSON | CI/CD-friendly summary with counts and flags |
| `<wheel>.cves.json` | JSON array | CVE findings (only created if CVEs found) |

**Example** for `numpy-1.26.0-cp311-linux_ppc64le.whl`:
```
${OUTPUT_DIR}/
├── artifacts/
│   └── numpy-1.26.0-cp311-linux_ppc64le.whl
├── numpy-1.26.0-cp311-linux_ppc64le.sbom.json
├── numpy-1.26.0-cp311-linux_ppc64le.summary.json
└── numpy-1.26.0-cp311-linux_ppc64le.cves.json  (if CVEs found)
```

## Summary JSON Schema

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
    "warnings": 0,
    "requires_manual_review": false,
    "generated_at": "2026-03-30T12:00:00Z"
}
```

## Key Fields for Automation

- `requires_manual_review` - `true` if any issues need human attention
- `cves.critical` / `cves.high` - Use for release gates
- `binary_sources.unknown` - Non-zero indicates provenance gaps
- `red_flags` - Count of serious issues (missing licenses, etc.)

## See Also

- `WHEEL_SBOM_OPERATIONS.md` - Full operational guide
- `WHEEL_SBOM_STRATEGY.md` - Design rationale
