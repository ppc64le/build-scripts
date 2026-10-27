#!/usr/bin/env python3
"""
create_scan_summary.py — Generate a full build summary for a V2 wheel build run.

Usage:
    python3 create_scan_summary.py <v2-scan-workspace> [package_name] [package_version]

Writes v2-scan-workspace/final_summary.json and prints a human-readable summary
to stdout suitable for embedding in the GitHub Actions step summary.

Per-job build statuses are read from env vars:
    STATUS_UBI9_PY312, STATUS_UBI9_PY313, STATUS_UBI9_PY314
    STATUS_UBI10_PY312, STATUS_UBI10_PY313, STATUS_UBI10_PY314
Each may be: success | failure | skipped | cancelled
"""
import json
import os
import sys
from pathlib import Path


def sizeof_fmt(num_bytes):
    for unit in ("B", "KB", "MB", "GB"):
        if abs(num_bytes) < 1024.0:
            return f"{num_bytes:.1f} {unit}"
        num_bytes /= 1024.0
    return f"{num_bytes:.1f} TB"


def status_icon(status):
    return {
        "success": "✅",
        "failure": "❌",
        "skipped": "⊘ skipped",
        "cancelled": "⊘ cancelled",
    }.get(status or "skipped", f"⊘ {status}")


root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("v2-scan-workspace")
package_name = sys.argv[2] if len(sys.argv) > 2 else os.environ.get("PACKAGE_NAME", "unknown")
package_version = sys.argv[3] if len(sys.argv) > 3 else os.environ.get("PACKAGE_VERSION", "unknown")

# Per-job statuses injected from workflow needs context
job_statuses = {
    ("ubi9",  "3.10"): os.environ.get("STATUS_UBI9_PY310",  "skipped"),
    ("ubi9",  "3.11"): os.environ.get("STATUS_UBI9_PY311",  "skipped"),
    ("ubi9",  "3.12"): os.environ.get("STATUS_UBI9_PY312",  "skipped"),
    ("ubi9",  "3.13"): os.environ.get("STATUS_UBI9_PY313",  "skipped"),
    ("ubi9",  "3.14"): os.environ.get("STATUS_UBI9_PY314",  "skipped"),
    ("ubi10", "3.12"): os.environ.get("STATUS_UBI10_PY312", "skipped"),
    ("ubi10", "3.13"): os.environ.get("STATUS_UBI10_PY313", "skipped"),
    ("ubi10", "3.14"): os.environ.get("STATUS_UBI10_PY314", "skipped"),
}

summary = {
    "package": package_name,
    "version": package_version,
    "scan_workspace": str(root),
    "scan_types": {
        "source": root.joinpath("source").is_dir(),
        "wheel": root.joinpath("wheel").is_dir(),
        "image": root.joinpath("image", "results").is_dir(),
    },
    "build_statuses": {
        f"{ubi}-{py}": status for (ubi, py), status in job_statuses.items()
    },
    "results": {
        "wheels": [],
        "wheel_scans": [],
        "wheel_licenses": [],
        "source_scans": [],
        "metadata": [],
    },
    "files": [],
}

for path in sorted(root.rglob("*")):
    if not path.is_file() or ".git" in path.parts:
        continue
    relative_path = str(path.relative_to(root))
    size = path.stat().st_size
    summary["files"].append({"path": relative_path, "size_bytes": size})

    if path.suffix == ".whl":
        summary["results"]["wheels"].append(relative_path)
    elif path.name.endswith("_licenses.json"):
        summary["results"]["wheel_licenses"].append(relative_path)
    elif relative_path.startswith("source/"):
        summary["results"]["source_scans"].append(relative_path)
    elif relative_path.startswith("wheel/") and path.suffix == ".json":
        summary["results"]["wheel_scans"].append(relative_path)
    elif relative_path.startswith("metadata/"):
        summary["results"]["metadata"].append(relative_path)

(root / "final_summary.json").write_text(json.dumps(summary, indent=2) + "\n")

# ── Human-readable output ─────────────────────────────────────────────────────

sep = "=" * 62

print(sep)
print(f"  V2 Build Summary")
print(sep)
print(f"  Package  : {package_name}")
print(f"  Version  : {package_version}")
print()
print(f"  Scan types run:")
print(f"    Source scan : {'YES' if summary['scan_types']['source'] else 'NO'}")
print(f"    Wheel scan  : {'YES' if summary['scan_types']['wheel'] else 'NO'}")
print(sep)

# Per-job build status table
print()
print(f"  Wheel Build Status")
print("-" * 62)
print(f"  {'UBI':<8}  {'Python':<8}  Status")
print(f"  {'-'*6}  {'-'*6}  ------")
for (ubi, py), status in job_statuses.items():
    icon = status_icon(status)
    print(f"  {ubi:<8}  {py:<8}  {icon}")

# Wheels built
print()
print(f"  Wheels Built ({len(summary['results']['wheels'])})")
print("-" * 62)
if summary["results"]["wheels"]:
    for w in summary["results"]["wheels"]:
        size = next((f["size_bytes"] for f in summary["files"] if f["path"] == w), 0)
        print(f"  {sizeof_fmt(size):>8}  {Path(w).name}")
else:
    print("  (none)")

# Wheel scan results
print()
print(f"  Wheel Scan Results ({len(summary['results']['wheel_scans'])})")
print("-" * 62)
if summary["results"]["wheel_scans"]:
    for f in summary["results"]["wheel_scans"]:
        size = next((e["size_bytes"] for e in summary["files"] if e["path"] == f), 0)
        print(f"  {sizeof_fmt(size):>8}  {Path(f).name}")
else:
    print("  (none)")

# Wheel licenses
print()
print(f"  Wheel License Results ({len(summary['results']['wheel_licenses'])})")
print("-" * 62)
if summary["results"]["wheel_licenses"]:
    for lf in summary["results"]["wheel_licenses"]:
        license_path = root / lf
        try:
            data = json.loads(license_path.read_text())
            licenses = ", ".join(data.get("licenses", [])) or "(no licenses detected)"
            print(f"  {Path(lf).name}")
            print(f"    Licenses: {licenses}")
        except Exception:
            print(f"  {Path(lf).name}  (could not read)")
else:
    print("  (none)")

# Source scan results
print()
print(f"  Source Code Scan Results ({len(summary['results']['source_scans'])})")
print("-" * 62)
if summary["results"]["source_scans"]:
    for f in summary["results"]["source_scans"]:
        size = next((e["size_bytes"] for e in summary["files"] if e["path"] == f), 0)
        print(f"  {sizeof_fmt(size):>8}  {Path(f).name}")
else:
    print("  (none)")

# Metadata
print()
print(f"  Build Metadata ({len(summary['results']['metadata'])})")
print("-" * 62)
if summary["results"]["metadata"]:
    for f in summary["results"]["metadata"]:
        size = next((e["size_bytes"] for e in summary["files"] if e["path"] == f), 0)
        print(f"  {sizeof_fmt(size):>8}  {Path(f).name}")
else:
    print("  (none)")

print()
print(sep)
print(f"  COS Artifacts (powercore-builds/{package_name}/{package_version}/)")
print("-" * 62)
for (ubi, py), status in job_statuses.items():
    if status == "success":
        print(f"  {package_name}-{package_version}-v2-scan-result-{ubi}-{py}.tar.gz")
print(f"  {package_name}-{package_version}-v2-license-results.tar.gz")
print(f"  {package_name}-{package_version}-v2-final-summary.tar.gz")
print(sep)
