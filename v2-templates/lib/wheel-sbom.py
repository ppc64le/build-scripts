#!/usr/bin/env python3
"""
wheel-sbom.py - Generate CycloneDX SBOM for Python wheels

This tool scans Python wheels and generates:
1. CycloneDX SBOM (machine-readable)
2. Summary JSON (CI/CD integration)
3. CVE report (if vulnerabilities found)

Usage:
    python wheel-sbom.py <wheel_path> [--output-dir <dir>] [--skip-cve]

Components tracked:
    - Wheel package identity (name, version, license)
    - Python dependencies (Requires-Dist)
    - Bundled shared libraries (.so files)
    - RPM provenance for system libraries
    - SHA-256 hashes for all binaries

See templates/docs/WHEEL_SBOM_STRATEGY.md for design details.
"""

import argparse
import hashlib
import json
import os
import re
import subprocess
import sys
import tempfile
import zipfile
from dataclasses import dataclass, field, asdict
from datetime import datetime, timezone
from email.parser import Parser
from pathlib import Path
from typing import Optional
from uuid import uuid4


# =============================================================================
# DATA STRUCTURES
# =============================================================================

@dataclass
class BinaryComponent:
    """Represents a bundled binary (.so file)"""
    filename: str
    normalized_name: str
    sha256: str
    size: int
    path_in_wheel: str
    source: str = "unknown"  # 'rpm', 'artifact', 'source-built'
    rpm_package: Optional[str] = None
    rpm_version: Optional[str] = None
    license: Optional[str] = None


@dataclass
class PythonDependency:
    """Represents a Python dependency from Requires-Dist"""
    name: str
    version_spec: Optional[str] = None
    extras: list = field(default_factory=list)
    environment_marker: Optional[str] = None


@dataclass
class WheelMetadata:
    """Extracted wheel metadata"""
    name: str
    version: str
    license: Optional[str] = None
    license_expression: Optional[str] = None
    author: Optional[str] = None
    homepage: Optional[str] = None
    summary: Optional[str] = None
    dependencies: list = field(default_factory=list)
    license_files: list = field(default_factory=list)


@dataclass
class CVEFinding:
    """A CVE found in the wheel"""
    cve_id: str
    severity: str
    component: str
    component_version: str
    description: Optional[str] = None
    fixed_version: Optional[str] = None


@dataclass
class SBOMResult:
    """Complete SBOM analysis result"""
    wheel_file: str
    metadata: WheelMetadata
    binaries: list = field(default_factory=list)
    cves: list = field(default_factory=list)
    generated_at: str = field(default_factory=lambda: datetime.now(timezone.utc).isoformat())
    tool_version: str = "1.0.0"


# =============================================================================
# WHEEL EXTRACTION AND METADATA PARSING
# =============================================================================

def extract_wheel(wheel_path: Path, extract_dir: Path) -> Path:
    """Extract wheel to temporary directory"""
    with zipfile.ZipFile(wheel_path, 'r') as zf:
        zf.extractall(extract_dir)
    return extract_dir


def find_dist_info(extract_dir: Path) -> Optional[Path]:
    """Find the .dist-info directory in extracted wheel"""
    for item in extract_dir.iterdir():
        if item.is_dir() and item.name.endswith('.dist-info'):
            return item
    return None


def parse_metadata(dist_info: Path) -> WheelMetadata:
    """Parse METADATA file from .dist-info"""
    metadata_file = dist_info / "METADATA"
    if not metadata_file.exists():
        raise ValueError(f"METADATA not found in {dist_info}")

    with open(metadata_file, 'r', encoding='utf-8') as f:
        content = f.read()

    # Parse email-style headers
    parser = Parser()
    msg = parser.parsestr(content)

    # Extract basic fields
    metadata = WheelMetadata(
        name=msg.get('Name', 'unknown'),
        version=msg.get('Version', 'unknown'),
        license=msg.get('License'),
        license_expression=msg.get('License-Expression'),
        author=msg.get('Author') or msg.get('Author-email'),
        homepage=msg.get('Home-page') or msg.get('Project-URL', '').split(',')[0] if msg.get('Project-URL') else None,
        summary=msg.get('Summary'),
    )

    # Parse Requires-Dist
    requires = msg.get_all('Requires-Dist') or []
    for req in requires:
        dep = parse_requirement(req)
        if dep:
            metadata.dependencies.append(dep)

    # Find license files
    for item in dist_info.iterdir():
        if item.name.upper().startswith(('LICENSE', 'COPYING', 'NOTICE')):
            metadata.license_files.append(item.name)

    return metadata


def parse_requirement(req_string: str) -> Optional[PythonDependency]:
    """Parse a Requires-Dist string into PythonDependency"""
    # Basic pattern: name[extras] (version_spec) ; marker
    # Examples:
    #   numpy>=1.20
    #   requests[security]>=2.25.0
    #   typing-extensions>=3.7; python_version < "3.8"

    # Extract environment marker
    marker = None
    if ';' in req_string:
        req_string, marker = req_string.split(';', 1)
        marker = marker.strip()

    # Extract extras
    extras = []
    if '[' in req_string:
        match = re.match(r'^([^\[]+)\[([^\]]+)\](.*)$', req_string)
        if match:
            name = match.group(1).strip()
            extras = [e.strip() for e in match.group(2).split(',')]
            version_spec = match.group(3).strip() or None
        else:
            return None
    else:
        # No extras - split on version specifier
        match = re.match(r'^([a-zA-Z0-9_-]+)(.*)$', req_string.strip())
        if match:
            name = match.group(1)
            version_spec = match.group(2).strip() or None
        else:
            return None

    return PythonDependency(
        name=name,
        version_spec=version_spec if version_spec else None,
        extras=extras,
        environment_marker=marker,
    )


# =============================================================================
# BINARY SCANNING
# =============================================================================

def normalize_so_name(filename: str) -> str:
    """Remove auditwheel hash from library filename

    Example: libgfortran-37ae8338.so.5.0.0 -> libgfortran.so.5.0.0
    """
    return re.sub(r'-[0-9a-f]{8,}(\.so)', r'\1', filename)


def compute_sha256(file_path: Path) -> str:
    """Compute SHA-256 hash of a file"""
    sha256 = hashlib.sha256()
    with open(file_path, 'rb') as f:
        for chunk in iter(lambda: f.read(8192), b''):
            sha256.update(chunk)
    return sha256.hexdigest()


def find_binaries(extract_dir: Path) -> list[BinaryComponent]:
    """Find all binary files (.so) in the extracted wheel"""
    binaries = []

    for root, dirs, files in os.walk(extract_dir):
        for filename in files:
            # Match .so files (shared libraries)
            if '.so' in filename:
                file_path = Path(root) / filename
                rel_path = file_path.relative_to(extract_dir)

                binary = BinaryComponent(
                    filename=filename,
                    normalized_name=normalize_so_name(filename),
                    sha256=compute_sha256(file_path),
                    size=file_path.stat().st_size,
                    path_in_wheel=str(rel_path),
                )

                # Try to determine provenance
                resolve_binary_provenance(binary)

                binaries.append(binary)

    return binaries


def resolve_binary_provenance(binary: BinaryComponent) -> None:
    """Try to determine where a binary came from (RPM, artifact, etc.)"""
    # Check if RPM is available
    if not is_rpm_available():
        binary.source = "unknown"
        return

    # Search for the library on the filesystem
    normalized = binary.normalized_name
    search_paths = ['/usr/lib64', '/usr/lib', '/lib64', '/lib']

    lib_path = None
    for search_dir in search_paths:
        candidate = Path(search_dir) / normalized
        if candidate.exists():
            lib_path = candidate
            break

    if not lib_path:
        # Try find command
        try:
            result = subprocess.run(
                ['find'] + search_paths + ['-name', normalized, '-type', 'f'],
                capture_output=True, text=True, timeout=10
            )
            if result.stdout.strip():
                lib_path = Path(result.stdout.strip().split('\n')[0])
        except (subprocess.TimeoutExpired, subprocess.SubprocessError):
            pass

    if not lib_path:
        binary.source = "source-built"
        return

    # Check RPM ownership
    try:
        result = subprocess.run(
            ['rpm', '-qf', str(lib_path)],
            capture_output=True, text=True, timeout=10
        )
        if result.returncode == 0 and 'not owned' not in result.stdout:
            rpm_name = result.stdout.strip()
            binary.rpm_package = rpm_name
            binary.source = "rpm"

            # Get RPM license
            result = subprocess.run(
                ['rpm', '-q', '--qf', '%{LICENSE}', rpm_name],
                capture_output=True, text=True, timeout=10
            )
            if result.returncode == 0:
                binary.license = result.stdout.strip()

            # Extract version from RPM name
            # Pattern: name-version-release.arch
            match = re.match(r'^(.+)-([^-]+)-([^-]+)\.[^.]+$', rpm_name)
            if match:
                binary.rpm_version = match.group(2)

    except (subprocess.TimeoutExpired, subprocess.SubprocessError):
        binary.source = "unknown"


def is_rpm_available() -> bool:
    """Check if RPM is available on this system"""
    return (
        Path('/etc/redhat-release').exists() and
        subprocess.run(['which', 'rpm'], capture_output=True).returncode == 0
    )


# =============================================================================
# CVE DETECTION
# =============================================================================

def run_cve_detection(wheel_path: Path, metadata: WheelMetadata, binaries: list[BinaryComponent]) -> list[CVEFinding]:
    """Run CVE detection tools and aggregate results"""
    cves = []

    # Try pip-audit for Python CVEs
    cves.extend(run_pip_audit(metadata))

    # Try cve-bin-tool for binary CVEs
    cves.extend(run_cve_bin_tool(wheel_path))

    return cves


def run_pip_audit(metadata: WheelMetadata) -> list[CVEFinding]:
    """Run pip-audit to check for Python package CVEs"""
    cves = []

    # Check if pip-audit is available
    if subprocess.run(['which', 'pip-audit'], capture_output=True).returncode != 0:
        return cves

    try:
        # Create a temporary requirements file with just this package
        with tempfile.NamedTemporaryFile(mode='w', suffix='.txt', delete=False) as f:
            f.write(f"{metadata.name}=={metadata.version}\n")
            req_file = f.name

        result = subprocess.run(
            ['pip-audit', '-r', req_file, '--format', 'json'],
            capture_output=True, text=True, timeout=120
        )

        os.unlink(req_file)

        if result.returncode == 0 or result.stdout:
            try:
                audit_result = json.loads(result.stdout)
                for vuln in audit_result.get('dependencies', []):
                    for v in vuln.get('vulns', []):
                        cves.append(CVEFinding(
                            cve_id=v.get('id', 'UNKNOWN'),
                            severity=v.get('severity', 'UNKNOWN'),
                            component=vuln.get('name', metadata.name),
                            component_version=vuln.get('version', metadata.version),
                            description=v.get('description'),
                            fixed_version=v.get('fix_versions', [None])[0] if v.get('fix_versions') else None,
                        ))
            except json.JSONDecodeError:
                pass

    except (subprocess.TimeoutExpired, subprocess.SubprocessError):
        pass

    return cves


def run_cve_bin_tool(wheel_path: Path) -> list[CVEFinding]:
    """Run cve-bin-tool to check for binary CVEs"""
    cves = []

    # Check if cve-bin-tool is available
    if subprocess.run(['which', 'cve-bin-tool'], capture_output=True).returncode != 0:
        return cves

    try:
        result = subprocess.run(
            ['cve-bin-tool', '--format', 'json', str(wheel_path)],
            capture_output=True, text=True, timeout=300
        )

        if result.stdout:
            try:
                bin_result = json.loads(result.stdout)
                for item in bin_result:
                    if isinstance(item, dict) and 'cve_number' in item:
                        cves.append(CVEFinding(
                            cve_id=item.get('cve_number', 'UNKNOWN'),
                            severity=item.get('severity', 'UNKNOWN'),
                            component=item.get('product', 'unknown'),
                            component_version=item.get('version', 'unknown'),
                            description=item.get('description'),
                        ))
            except json.JSONDecodeError:
                pass

    except (subprocess.TimeoutExpired, subprocess.SubprocessError):
        pass

    return cves


# =============================================================================
# CYCLONEDX SBOM GENERATION
# =============================================================================

def generate_cyclonedx(result: SBOMResult) -> dict:
    """Generate CycloneDX SBOM format"""
    sbom = {
        "bomFormat": "CycloneDX",
        "specVersion": "1.5",
        "serialNumber": f"urn:uuid:{uuid4()}",
        "version": 1,
        "metadata": {
            "timestamp": result.generated_at,
            "tools": [{
                "name": "wheel-sbom",
                "version": result.tool_version,
            }],
            "component": {
                "type": "library",
                "name": result.metadata.name,
                "version": result.metadata.version,
                "purl": f"pkg:pypi/{result.metadata.name}@{result.metadata.version}",
            }
        },
        "components": [],
        "dependencies": [],
        "vulnerabilities": [],
    }

    # Add the main package
    main_component = {
        "type": "library",
        "bom-ref": f"pkg:pypi/{result.metadata.name}@{result.metadata.version}",
        "name": result.metadata.name,
        "version": result.metadata.version,
        "purl": f"pkg:pypi/{result.metadata.name}@{result.metadata.version}",
    }

    if result.metadata.license:
        main_component["licenses"] = [{"license": {"name": result.metadata.license}}]
    if result.metadata.summary:
        main_component["description"] = result.metadata.summary

    sbom["components"].append(main_component)

    # Add Python dependencies
    dep_refs = []
    for dep in result.metadata.dependencies:
        purl = f"pkg:pypi/{dep.name}"
        if dep.version_spec:
            # Extract version from spec for purl (simplified)
            version_match = re.search(r'[\d.]+', dep.version_spec)
            if version_match:
                purl += f"@{version_match.group()}"

        comp = {
            "type": "library",
            "bom-ref": purl,
            "name": dep.name,
        }
        if dep.version_spec:
            comp["version"] = dep.version_spec

        sbom["components"].append(comp)
        dep_refs.append(purl)

    # Add binary components
    for binary in result.binaries:
        bom_ref = f"pkg:generic/{binary.normalized_name}"
        if binary.rpm_version:
            bom_ref += f"@{binary.rpm_version}"

        comp = {
            "type": "library",
            "bom-ref": bom_ref,
            "name": binary.normalized_name,
            "hashes": [{"alg": "SHA-256", "content": binary.sha256}],
            "properties": [
                {"name": "source", "value": binary.source},
                {"name": "original-filename", "value": binary.filename},
                {"name": "path-in-wheel", "value": binary.path_in_wheel},
            ],
        }

        if binary.rpm_package:
            comp["properties"].append({"name": "rpm-package", "value": binary.rpm_package})
        if binary.license:
            comp["licenses"] = [{"license": {"name": binary.license}}]

        sbom["components"].append(comp)
        dep_refs.append(bom_ref)

    # Add dependency relationship
    sbom["dependencies"].append({
        "ref": f"pkg:pypi/{result.metadata.name}@{result.metadata.version}",
        "dependsOn": dep_refs,
    })

    # Add vulnerabilities
    for cve in result.cves:
        vuln = {
            "id": cve.cve_id,
            "ratings": [{"severity": cve.severity.lower()}],
            "affects": [{
                "ref": f"pkg:generic/{cve.component}@{cve.component_version}",
            }],
        }
        if cve.description:
            vuln["description"] = cve.description
        if cve.fixed_version:
            vuln["recommendation"] = f"Upgrade to version {cve.fixed_version}"

        sbom["vulnerabilities"].append(vuln)

    return sbom


# =============================================================================
# SUMMARY GENERATION
# =============================================================================

def generate_summary(result: SBOMResult) -> dict:
    """Generate CI-friendly summary JSON"""
    rpm_sourced = sum(1 for b in result.binaries if b.source == "rpm")
    source_built = sum(1 for b in result.binaries if b.source == "source-built")
    unknown_source = sum(1 for b in result.binaries if b.source == "unknown")

    # Determine if manual review is needed
    requires_review = (
        unknown_source > 0 or  # Unknown provenance
        not result.metadata.license or  # No license declared
        any(cve.severity.upper() in ('CRITICAL', 'HIGH') for cve in result.cves)  # High-severity CVEs
    )

    return {
        "wheel": result.wheel_file,
        "package": f"{result.metadata.name}=={result.metadata.version}",
        "license": result.metadata.license,
        "dependencies": len(result.metadata.dependencies),
        "bundled_binaries": len(result.binaries),
        "rpm_sourced": rpm_sourced,
        "source_built": source_built,
        "unknown_source": unknown_source,
        "cves_found": len(result.cves),
        "cves_critical": sum(1 for c in result.cves if c.severity.upper() == "CRITICAL"),
        "cves_high": sum(1 for c in result.cves if c.severity.upper() == "HIGH"),
        "requires_manual_review": requires_review,
        "generated_at": result.generated_at,
    }


# =============================================================================
# MAIN ENTRY POINT
# =============================================================================

def analyze_wheel(wheel_path: Path, skip_cve: bool = False) -> SBOMResult:
    """Main analysis function - extract and analyze a wheel"""
    if not wheel_path.exists():
        raise FileNotFoundError(f"Wheel not found: {wheel_path}")

    with tempfile.TemporaryDirectory() as temp_dir:
        temp_path = Path(temp_dir)

        # Extract wheel
        extract_wheel(wheel_path, temp_path)

        # Find dist-info
        dist_info = find_dist_info(temp_path)
        if not dist_info:
            raise ValueError(f"No .dist-info directory found in wheel")

        # Parse metadata
        metadata = parse_metadata(dist_info)

        # Find binaries
        binaries = find_binaries(temp_path)

        # Run CVE detection
        cves = []
        if not skip_cve:
            cves = run_cve_detection(wheel_path, metadata, binaries)

        return SBOMResult(
            wheel_file=wheel_path.name,
            metadata=metadata,
            binaries=binaries,
            cves=cves,
        )


def main():
    parser = argparse.ArgumentParser(
        description="Generate CycloneDX SBOM for Python wheels"
    )
    parser.add_argument("wheel", help="Path to wheel file")
    parser.add_argument("--output-dir", "-o", default=".", help="Output directory for SBOM files")
    parser.add_argument("--skip-cve", action="store_true", help="Skip CVE detection")
    parser.add_argument("--quiet", "-q", action="store_true", help="Suppress progress output")

    args = parser.parse_args()

    wheel_path = Path(args.wheel)
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    if not args.quiet:
        print(f"Analyzing wheel: {wheel_path.name}")

    try:
        result = analyze_wheel(wheel_path, skip_cve=args.skip_cve)

        # Generate outputs
        base_name = wheel_path.stem

        # CycloneDX SBOM
        sbom = generate_cyclonedx(result)
        sbom_path = output_dir / f"{base_name}.sbom.json"
        with open(sbom_path, 'w') as f:
            json.dump(sbom, f, indent=2)
        if not args.quiet:
            print(f"  SBOM: {sbom_path}")

        # Summary JSON
        summary = generate_summary(result)
        summary_path = output_dir / f"{base_name}.summary.json"
        with open(summary_path, 'w') as f:
            json.dump(summary, f, indent=2)
        if not args.quiet:
            print(f"  Summary: {summary_path}")

        # CVE report (if any found)
        if result.cves:
            cve_path = output_dir / f"{base_name}.cves.json"
            with open(cve_path, 'w') as f:
                json.dump([asdict(c) for c in result.cves], f, indent=2)
            if not args.quiet:
                print(f"  CVEs: {cve_path} ({len(result.cves)} found)")

        # Print summary
        if not args.quiet:
            print(f"\nSummary:")
            print(f"  Package: {summary['package']}")
            print(f"  License: {summary['license'] or 'NOT SPECIFIED'}")
            print(f"  Dependencies: {summary['dependencies']}")
            print(f"  Bundled binaries: {summary['bundled_binaries']}")
            print(f"    RPM-sourced: {summary['rpm_sourced']}")
            print(f"    Source-built: {summary['source_built']}")
            print(f"    Unknown: {summary['unknown_source']}")
            print(f"  CVEs found: {summary['cves_found']}")
            if summary['requires_manual_review']:
                print(f"  *** REQUIRES MANUAL REVIEW ***")

        # Exit with error if critical CVEs found
        if summary['cves_critical'] > 0:
            sys.exit(2)
        elif summary['cves_high'] > 0:
            sys.exit(1)

    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(3)


if __name__ == "__main__":
    main()
