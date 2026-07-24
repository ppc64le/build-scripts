#!/usr/bin/env python3
"""
Generalized Wheel CVE Scanner
Scans any Python wheel for CVEs including bundled .so files

Usage:
    python generalized_wheel_scanner.py <wheel_file.whl> [build_script.sh]

    build_script.sh is optional — required for Lane 3 (source-built libs).
    When provided, the scanner parses git clone/checkout lines to extract
    source-built library names and versions, then queries NVD CPE + CVE APIs.
"""

import sys
import json
import os
import re
import subprocess
import tempfile
import time
import urllib.request
import urllib.parse
import zipfile
from pathlib import Path
from datetime import datetime, timezone
from typing import Dict, List, Optional, Set, Tuple
import shutil


NVD_API_BASE = "https://services.nvd.nist.gov/rest/json"


class WheelCVEScanner:
    """Generalized scanner for any Python wheel"""

    def __init__(self, wheel_path: str, build_script_path: str = ""):
        self.wheel_path = Path(wheel_path)
        self.wheel_name = self.wheel_path.name
        self.build_script_path = Path(build_script_path) if build_script_path else None
        self.results = {
            'wheel_file': self.wheel_name,
            'scan_date': datetime.now(timezone.utc).isoformat(),
            'steps': {}
        }
        
    # Grype install URL
    _GRYPE_INSTALL_URL = (
        "https://raw.githubusercontent.com/anchore/grype/main/install.sh"
    )

    def _ensure_grype(self, retries: int = 3, retry_delay: int = 10) -> bool:
        """
        Ensure grype is available on PATH.  If not found, attempt to install it
        via the official install script into /usr/local/bin.

        Non-blocking — if all retries fail, prints a warning and returns False.
        The caller skips grype-dependent steps but continues with Lane 3 (NVD).

        Args:
            retries:     number of install attempts (default 3)
            retry_delay: seconds to wait between attempts (default 10)

        Returns True if grype is available after this call, False otherwise.
        """
        if shutil.which('grype'):
            print("  grype already installed.")
            return True

        print(f"  grype not found — attempting installation "
              f"(up to {retries} tries, {retry_delay}s between retries)...")

        for attempt in range(1, retries + 1):
            try:
                print(f"  Install attempt {attempt}/{retries}...")
                result = subprocess.run(
                    ['sh', '-c',
                     f'curl -sSfL {self._GRYPE_INSTALL_URL} | sh -s -- -b /usr/local/bin'],
                    capture_output=True, text=True, timeout=120
                )
                if result.returncode == 0 and shutil.which('grype'):
                    print("  grype installed successfully.")
                    return True
                print(f"  Attempt {attempt} failed: {result.stderr.strip()[:200]}")
            except Exception as e:
                print(f"  Attempt {attempt} error: {e}")

            if attempt < retries:
                print(f"  Retrying in {retry_delay}s...")
                time.sleep(retry_delay)

        print("  WARNING: grype installation failed after all retries. "
              "Lane 1, Lane 2 and Phase 1 (wheel direct scan) will be skipped. "
              "Lane 3 (NVD) will still run.")
        return False

    def scan(self) -> Dict:
        """Main scanning workflow"""
        print(f"\n{'='*70}")
        print(f"Scanning Wheel: {self.wheel_name}")
        print(f"{'='*70}\n")

        # Step 0: Ensure grype is available (install if needed, with retries)
        print("Step 0: Checking grype availability...")
        grype_available = self._ensure_grype()
        self.results['grype_available'] = grype_available

        # Step 1: Create system library inventory
        print("\nStep 1: Creating system library inventory...")
        self.results['steps']['inventory'] = self._create_system_inventory()

        # Step 2: Extract wheel + Phase 1 grype scan on extracted wheel dir
        print("\nStep 2: Extracting wheel...")
        with tempfile.TemporaryDirectory() as tmpdir:
            extract_dir = Path(tmpdir) / "wheel_contents"
            self._extract_wheel(extract_dir)

            # Step 2b: Phase 1 — grype scan directly on extracted wheel
            print("\nStep 2b: Phase 1 — grype scan on extracted wheel...")
            self.results['steps']['wheel_direct_scan'] = (
                self._scan_wheel_direct(extract_dir) if grype_available
                else {'skipped': True, 'reason': 'grype not available', 'matches': []}
            )

            # Step 3: Find bundled libraries
            print("\nStep 3: Finding bundled libraries...")
            self.results['steps']['bundled_libs'] = self._find_bundled_libraries(extract_dir)

            # Step 4: Map bundled libraries to source packages (Lane 2)
            print("\nStep 4: Mapping bundled libraries to source packages...")
            self.results['steps']['library_mapping'] = self._map_libraries_to_packages(
                self.results['steps']['bundled_libs'],
                self.results['steps']['inventory']
            )

        # Step 5: Get Python runtime dependencies (Lane 1)
        print("\nStep 5: Getting Python runtime dependencies...")
        self.results['steps']['python_deps'] = self._get_python_runtime_deps()

        # Step 6: Scan for CVEs (Lane 1 + Lane 2 via Grype on system)
        print("\nStep 6: Scanning for CVEs (Lane 1 + Lane 2)...")
        self.results['steps']['cve_scan'] = (
            self._scan_for_cves() if grype_available
            else {'skipped': True, 'reason': 'grype not available', 'packages_with_cves': {}}
        )

        # Step 7: Scan source-built libraries (Lane 3 via NVD CPE/CVE API)
        print("\nStep 7: Scanning source-built libraries via NVD...")
        self.results['steps']['source_built_scan'] = self._scan_source_built_libs()

        # Step 8: Generate final report
        print("\nStep 8: Generating final report...")
        self.results['final_report'] = self._generate_final_report()

        return self.results
    
    def _create_system_inventory(self) -> Dict:
        """Create inventory of system libraries"""
        inventory = {
            'timestamp': datetime.now(timezone.utc).isoformat(),
            'packages': {}
        }
        
        # Check if RPM-based system
        if shutil.which('rpm'):
            print("  Detected RPM-based system")
            inventory['packages'] = self._get_rpm_packages()
        # Check if DEB-based system
        elif shutil.which('dpkg'):
            print("  Detected DEB-based system")
            inventory['packages'] = self._get_dpkg_packages()
        else:
            print("  Warning: Could not detect package manager")
        
        print(f"  Found {len(inventory['packages'])} packages with libraries")
        return inventory
    
    def _get_rpm_packages(self) -> Dict:
        """Get library information from RPM packages.

        Uses two bulk rpm queries — no per-package subprocess calls:
          1. rpm -qa --queryformat  → all package names + versions
          2. rpm -q --filesbypkg -a → all files for all packages at once
             Output: "pkgname   /path/to/file"  (one line per file)

        Avoids [%{FILENAMES}] array iterator which fails on some RPM versions
        when packages have mismatched array tag sizes.
        """
        packages = {}

        try:
            # Step 1: one call — all package names + versions
            meta_result = subprocess.run(
                ['rpm', '-qa', '--queryformat', '%{NAME}|%{VERSION}-%{RELEASE}\n'],
                capture_output=True, text=True, timeout=30
            )

            name_to_version: Dict[str, str] = {}
            for line in meta_result.stdout.strip().splitlines():
                if '|' not in line:
                    continue
                pkg_name, version = line.split('|', 1)
                name_to_version[pkg_name] = version

            if not name_to_version:
                return packages

            # Step 2: one call — all files for all packages
            # Output format: "pkgname                   /path/to/file"
            files_result = subprocess.run(
                ['rpm', '-q', '--filesbypkg', '-a'],
                capture_output=True, text=True, timeout=120
            )

            for line in files_result.stdout.strip().splitlines():
                # Split on whitespace — pkgname is first token, filepath is last
                parts = line.split()
                if len(parts) < 2:
                    continue
                pkg_name  = parts[0]
                file_path = parts[-1]

                if pkg_name not in name_to_version:
                    continue
                if '.so' not in file_path:
                    continue

                p = Path(file_path)
                if not p.exists():
                    continue

                try:
                    so_entry = {
                        'path': file_path,
                        'realpath': str(p.resolve()),
                        'basename': p.name
                    }
                except Exception:
                    continue

                if pkg_name not in packages:
                    packages[pkg_name] = {
                        'version': name_to_version[pkg_name],
                        'so_files': []
                    }
                packages[pkg_name]['so_files'].append(so_entry)

        except Exception as e:
            print(f"  Warning: Error getting RPM packages: {e}")

        return packages
    
    def _get_dpkg_packages(self) -> Dict:
        """Get library information from DEB packages"""
        packages = {}
        
        try:
            # Get all packages
            result = subprocess.run(
                ['dpkg-query', '-W', '-f=${Package}|${Version}\n'],
                capture_output=True,
                text=True,
                timeout=30
            )
            
            for line in result.stdout.strip().split('\n'):
                if '|' not in line:
                    continue
                
                pkg_name, version = line.split('|', 1)
                
                # Get files in package
                files_result = subprocess.run(
                    ['dpkg', '-L', pkg_name],
                    capture_output=True,
                    text=True,
                    timeout=10
                )
                
                # Find .so files
                so_files = []
                for file_path in files_result.stdout.strip().split('\n'):
                    if '.so' in file_path and Path(file_path).exists():
                        try:
                            so_files.append({
                                'path': file_path,
                                'realpath': str(Path(file_path).resolve()),
                                'basename': Path(file_path).name
                            })
                        except:
                            pass
                
                if so_files:
                    packages[pkg_name] = {
                        'version': version,
                        'so_files': so_files
                    }
        
        except Exception as e:
            print(f"  Warning: Error getting DEB packages: {e}")
        
        return packages
    
    def _extract_wheel(self, extract_dir: Path):
        """Extract wheel contents"""
        extract_dir.mkdir(parents=True, exist_ok=True)
        
        with zipfile.ZipFile(self.wheel_path, 'r') as zip_ref:
            zip_ref.extractall(extract_dir)
        
        print(f"  Extracted to: {extract_dir}")
    
    def _find_bundled_libraries(self, extract_dir: Path) -> List[Dict]:
        """Find bundled .so files in wheel"""
        bundled_libs = []
        
        # Find .libs directories (created by auditwheel)
        libs_dirs = list(extract_dir.glob('**/*.libs'))
        
        if not libs_dirs:
            print("  No .libs directory found (no bundled libraries)")
            return bundled_libs
        
        for libs_dir in libs_dirs:
            print(f"  Found bundled libraries in: {libs_dir.name}")
            
            for so_file in libs_dir.glob('*.so*'):
                bundled_libs.append({
                    'bundled_filename': so_file.name,
                    'bundled_path': str(so_file.relative_to(extract_dir)),
                    'size': so_file.stat().st_size
                })
                print(f"    - {so_file.name}")
        
        print(f"  Total bundled libraries: {len(bundled_libs)}")
        return bundled_libs
    
    def _get_python_runtime_deps(self) -> Dict:
        """
        Get all Python runtime dependencies (direct + transitive) for the wheel
        by recursively walking dist-info/METADATA and egg-info/requires.txt files
        in the build environment's site-packages.

        Handles:
          - pip installs  → <pkg>-<ver>.dist-info/METADATA  (Requires-Dist lines)
          - setup.py installs → <pkg>-<ver>.egg-info/requires.txt (plain name lines)

        Excludes:
          - Optional extras  (lines with 'extra ==' marker)
          - Section headers  ([extras], [section]) in requires.txt
        """
        result = {
            'packages': {},   # name -> version
            'unknown': []     # deps found in chain but not installed
        }

        # Derive wheel package name from wheel filename
        # e.g. numpy-2.2.5-cp312-... -> numpy
        wheel_pkg_name = self.wheel_name.split('-')[0].lower().replace('_', '-')
        print(f"  Starting recursive dep walk from: {wheel_pkg_name}")

        # Find all site-packages directories on this system
        site_packages_dirs = self._find_site_packages()
        if not site_packages_dirs:
            print("  Warning: No site-packages directories found")
            return result

        print(f"  Found site-packages dirs: {[str(d) for d in site_packages_dirs]}")

        # Recursive walk
        visited: Set[str] = set()
        queue = [wheel_pkg_name]

        while queue:
            pkg = queue.pop(0)
            # Normalise name for consistent comparison
            norm = self._normalise_pkg_name(pkg)
            if norm in visited:
                continue
            visited.add(norm)

            # Find metadata for this package across all site-packages dirs
            meta = self._find_package_metadata(pkg, site_packages_dirs)
            if meta is None:
                if norm != self._normalise_pkg_name(wheel_pkg_name):
                    result['unknown'].append(pkg)
                continue

            name, version, deps = meta
            result['packages'][name] = version

            for dep in deps:
                if self._normalise_pkg_name(dep) not in visited:
                    queue.append(dep)

        print(f"  Found {len(result['packages'])} Python runtime packages")
        if result['unknown']:
            print(f"  {len(result['unknown'])} deps not found in site-packages: {result['unknown']}")

        return result

    def _find_site_packages(self) -> List[Path]:
        """Find all site-packages directories on the system"""
        site_dirs = []
        try:
            result = subprocess.run(
                ['find', '/', '-name', 'site-packages', '-type', 'd',
                 '-not', '-path', '*/proc/*'],
                capture_output=True,
                text=True,
                timeout=60
            )
            for line in result.stdout.strip().splitlines():
                p = Path(line.strip())
                if p.is_dir():
                    site_dirs.append(p)
        except Exception as e:
            print(f"  Warning: Error finding site-packages: {e}")
        return site_dirs

    def _normalise_pkg_name(self, name: str) -> str:
        """Normalise package name for comparison (PEP 503)"""
        # Strip version specifier and extras bracket first
        name = re.split(r'[>=<!;\[]', name)[0].strip()
        return re.sub(r'[-_.]+', '-', name).lower()

    def _find_package_metadata(
        self, pkg_name: str, site_dirs: List[Path]
    ) -> Optional[tuple]:
        """
        Find metadata for a package and return (name, version, runtime_deps).
        Looks for dist-info/METADATA first, then egg-info/requires.txt.
        Returns None if the package is not found.
        """
        norm = self._normalise_pkg_name(pkg_name)

        for site_dir in site_dirs:
            # --- Format 1: dist-info/METADATA (pip install) ---
            for dist_info in site_dir.glob('*.dist-info'):
                folder_norm = self._normalise_pkg_name(dist_info.name.split('-')[0])
                if folder_norm != norm:
                    continue
                metadata_file = dist_info / 'METADATA'
                if not metadata_file.exists():
                    continue
                # Read version from METADATA file directly — folder name parsing
                # e.g. "filelock-3.29.6.dist-info" splits incorrectly on '-'
                version = 'unknown'
                for line in metadata_file.read_text(errors='ignore').splitlines():
                    if line.startswith('Version:'):
                        version = line.split(':', 1)[1].strip()
                        break
                deps = self._parse_metadata_requires(metadata_file)
                return (dist_info.name.split('-')[0], version, deps)

            # --- Format 2: egg-info/requires.txt (setup.py install) ---
            for egg_info in site_dir.glob('*.egg-info'):
                folder_norm = self._normalise_pkg_name(egg_info.name.split('-')[0])
                if folder_norm != norm:
                    continue
                requires_file = egg_info / 'requires.txt'
                pkg_info_file = egg_info / 'PKG-INFO'
                # Get version from PKG-INFO
                version = 'unknown'
                if pkg_info_file.exists():
                    for line in pkg_info_file.read_text(errors='ignore').splitlines():
                        if line.startswith('Version:'):
                            version = line.split(':', 1)[1].strip()
                            break
                deps = []
                if requires_file.exists():
                    deps = self._parse_egg_requires(requires_file)
                return (egg_info.name.split('-')[0], version, deps)

        return None

    def _parse_metadata_requires(self, metadata_file: Path) -> List[str]:
        """
        Parse Requires-Dist lines from dist-info/METADATA.
        Excludes optional extras and evaluates environment markers.
        """
        deps = []
        try:
            for line in metadata_file.read_text(errors='ignore').splitlines():
                if not line.startswith('Requires-Dist:'):
                    continue
                dep_str = line[len('Requires-Dist:'):].strip()

                # Skip optional extras: "pkg; extra == 'something'"
                if 'extra ==' in dep_str or "extra==" in dep_str:
                    continue

                # Strip environment markers (keep only the package name+version spec)
                # e.g. "importlib-metadata; python_version < '3.10'" -> "importlib-metadata"
                dep_name = dep_str.split(';')[0].strip()

                # Strip version specifier and extras bracket to get bare name
                dep_name = re.split(r'[>=<!;\[ ]', dep_name)[0].strip()

                if dep_name:
                    deps.append(dep_name)
        except Exception as e:
            print(f"  Warning: Error parsing {metadata_file}: {e}")
        return deps

    def _parse_egg_requires(self, requires_file: Path) -> List[str]:
        """
        Parse deps from egg-info/requires.txt.
        Only reads lines before the first [section] marker (extras/conditionals).
        """
        deps = []
        try:
            for line in requires_file.read_text(errors='ignore').splitlines():
                line = line.strip()
                if not line:
                    continue
                # Stop at any [section] marker — these are extras or conditionals
                if line.startswith('['):
                    break
                # Strip version specifier to get bare name
                dep_name = re.split(r'[>=<!;\[ ]', line)[0].strip()
                if dep_name:
                    deps.append(dep_name)
        except Exception as e:
            print(f"  Warning: Error parsing {requires_file}: {e}")
        return deps

    def _map_libraries_to_packages(self, bundled_libs: List[Dict], inventory: Dict) -> List[Dict]:
        """Map bundled libraries to their source packages"""
        mapping = []
        
        for bundled_lib in bundled_libs:
            bundled_name = bundled_lib['bundled_filename']
            
            # Extract base library name — strip auditwheel hash and all version info
            # Works generically for any library naming convention:
            #   libgfortran-2758a8fd.so.5.0.0    -> libgfortran
            #   libopenblasp-r0-a8f83a82.3.32.so -> libopenblasp-r0
            #   libabsl_base-eb206faa.so.2401.0.0 -> libabsl_base
            base_name = re.sub(r'-[a-f0-9]{8,}', '', bundled_name)  # Remove hex hash
            base_name = re.sub(r'(\.so|\.so\.).*$', '', base_name)  # Remove .so and after
            base_name = re.sub(r'\.\d+.*$', '', base_name)          # Remove any remaining .N.N version
            
            print(f"  Mapping {bundled_name} (base: {base_name})...")
            
            # Find matching package in inventory
            matched_package = None
            matched_so_file = None
            
            for pkg_name, pkg_info in inventory['packages'].items():
                for so_file in pkg_info['so_files']:
                    so_basename = so_file['basename']

                    # Strip .so and version suffix from inventory filename for comparison
                    # e.g. libgfortran.so.5.0.0 -> libgfortran
                    so_base = re.sub(r'\.so.*', '', so_basename.lower())

                    # Require exact match after normalisation — prevents libabsl_log_entry
                    # matching libquadmath due to broad substring logic
                    if base_name.lower() == so_base:
                        matched_package = pkg_name
                        matched_so_file = so_file
                        break

                if matched_package:
                    break
            
            if matched_package and matched_so_file:
                mapping.append({
                    'bundled_filename': bundled_name,
                    'source_package': matched_package,
                    'source_version': inventory['packages'][matched_package]['version'],
                    'source_so_file': matched_so_file['path'],
                    'confidence': 'high'
                })
                print(f"    ✓ Matched to: {matched_package} v{inventory['packages'][matched_package]['version']}")
            else:
                mapping.append({
                    'bundled_filename': bundled_name,
                    'source_package': 'unknown',
                    'source_version': 'unknown',
                    'confidence': 'none'
                })
                print(f"    ✗ No match found")
        
        return mapping
    
    def _scan_wheel_direct(self, extract_dir: Path) -> Dict:
        """
        Phase 1: run grype directly on the extracted wheel directory.

        This replicates the original Phase 1 approach — scan what is literally
        inside the wheel.  Grype can identify Python packages via .dist-info /
        METADATA and any other files it recognises.

        Results are stored raw and later deduplicated against Lane 1 + Lane 2
        in _generate_final_report() so the final report has no duplicate CVE
        entries across phases.

        Returns dict with 'matches' list — each entry:
            { package, version, cve_id, severity, description }
        """
        result_data = {'matches': []}
        print(f"  Running grype on extracted wheel: {extract_dir}")
        try:
            result = subprocess.run(
                ['grype', f'dir:{extract_dir}', '-o', 'json'],
                capture_output=True, text=True, timeout=300
            )
            if result.returncode == 0:
                scan_data = json.loads(result.stdout)
                seen: Set[Tuple[str, str]] = set()  # (package, cve_id) dedup
                for match in scan_data.get('matches', []):
                    artifact = match.get('artifact', {})
                    pkg_name = artifact.get('name', '')
                    pkg_ver  = artifact.get('version', '')
                    vuln     = match.get('vulnerability', {})
                    cve_id   = vuln.get('id', '')
                    key = (pkg_name, cve_id)
                    if key in seen:
                        continue
                    seen.add(key)
                    result_data['matches'].append({
                        'package':     pkg_name,
                        'version':     pkg_ver,
                        'cve_id':      cve_id,
                        'severity':    vuln.get('severity', ''),
                        'description': vuln.get('description', '')[:200]
                    })
                print(f"  Phase 1: found {len(result_data['matches'])} CVE(s) in wheel")
            else:
                print(f"  Phase 1 grype scan failed: {result.stderr.strip()[:200]}")
        except Exception as e:
            print(f"  Phase 1 grype scan error: {e}")
        return result_data

    def _scan_for_cves(self) -> Dict:
        """Scan for CVEs using Grype on the entire system"""
        cve_results = {
            'scan_method': 'grype_directory_scan',
            'packages_with_cves': {}
        }

        print("  Running Grype scan on system...")

        try:
            result = subprocess.run(
                ['grype', 'dir:/', '-o', 'json'],
                capture_output=True,
                text=True,
                timeout=300
            )

            if result.returncode == 0:
                scan_data = json.loads(result.stdout)

                # Lane 2: RPM/system packages matched via .so mapping
                library_mapping = self.results['steps'].get('library_mapping', [])
                rpm_target_packages = {
                    m['source_package'] for m in library_mapping
                    if m['source_package'] != 'unknown'
                }

                # Lane 1: Python runtime deps from recursive METADATA walk
                python_deps = self.results['steps'].get('python_deps', {})
                python_target_packages = set(python_deps.get('packages', {}).keys())

                # Combined target set
                target_packages = rpm_target_packages | python_target_packages

                print(f"  Scanning CVEs for {len(rpm_target_packages)} RPM packages "
                      f"and {len(python_target_packages)} Python packages")

                # Track seen CVE IDs per package to deduplicate
                # Grype reports same CVE multiple times when a package is
                # found in multiple locations (e.g. system + venv)
                seen_cves: Dict[str, set] = {}

                for match in scan_data.get('matches', []):
                    artifact = match.get('artifact', {})
                    pkg_name = artifact.get('name', '')

                    if pkg_name in target_packages:
                        if pkg_name not in cve_results['packages_with_cves']:
                            cve_results['packages_with_cves'][pkg_name] = []
                            seen_cves[pkg_name] = set()

                        vuln = match.get('vulnerability', {})
                        cve_id = vuln.get('id')

                        # Skip if already recorded for this package
                        if cve_id in seen_cves[pkg_name]:
                            continue
                        seen_cves[pkg_name].add(cve_id)

                        cve_results['packages_with_cves'][pkg_name].append({
                            'cve_id': cve_id,
                            'severity': vuln.get('severity'),
                            'description': vuln.get('description', '')[:200]
                        })

                print(f"  Found CVEs in {len(cve_results['packages_with_cves'])} packages")
            else:
                print(f"  Warning: Grype scan failed: {result.stderr}")

        except Exception as e:
            print(f"  Error running Grype: {e}")

        return cve_results
    
    # ------------------------------------------------------------------ #
    #  Lane 3 — Source-built C/C++ libraries via NVD CPE + CVE API        #
    # ------------------------------------------------------------------ #

    @staticmethod
    def _resolve_shell_vars(lines: List[str]) -> List[str]:
        """
        Pre-process raw shell script lines to resolve simple scalar variable
        assignments and substitute all $VAR / ${VAR} references.

        Only handles plain assignments (VAR=value) — not command substitution
        $(...), arithmetic $((...)), or arrays.  This is sufficient to cover
        the standard pattern used in every ppc64le build script:

            PACKAGE_URL=https://github.com/org/repo.git
            PACKAGE_VERSION=${1:-v1.2.3}       # default-value form
            git clone $PACKAGE_URL
            git checkout $PACKAGE_VERSION

        Two passes:
          Pass 1 — collect VAR=value mappings.  For default-value syntax
                   ${VAR:-default}, record the default.
          Pass 2 — substitute $VAR and ${VAR} in every line using the
                   collected mappings (longest-name-first to avoid partial
                   matches, e.g. $PACKAGE_VERSION before $PACKAGE).
        """
        env: Dict[str, str] = {}

        # Pass 1: collect assignments
        assign_re = re.compile(
            r'^([A-Za-z_][A-Za-z0-9_]*)'          # variable name
            r'='
            r'(?:"([^"]*)"'                         # "quoted value"
            r"|'([^']*)'"                           # 'single-quoted'
            r'|\$\{[^}]*:-([^}]+)\}'               # ${VAR:-default}
            r'|(\S+))'                              # bare unquoted value
        )
        for line in lines:
            stripped = line.strip()
            # Skip export/local prefixes so "export VAR=val" also matches
            stripped = re.sub(r'^(?:export|local|readonly)\s+', '', stripped)
            m = assign_re.match(stripped)
            if m:
                var_name = m.group(1)
                # Pick whichever capture group matched the value
                value = m.group(2) or m.group(3) or m.group(4) or m.group(5) or ''
                # Only store if value looks like a useful literal (non-empty,
                # not a further $VAR reference itself)
                if value and not value.startswith('$'):
                    env[var_name] = value

        # Pass 2: substitute — sort by length descending to prevent partial hits
        sorted_vars = sorted(env.keys(), key=len, reverse=True)

        resolved = []
        for line in lines:
            for var in sorted_vars:
                # Replace ${VAR} and $VAR (not followed by another word-char)
                line = re.sub(
                    r'\$\{' + re.escape(var) + r'\}',
                    env[var], line
                )
                line = re.sub(
                    r'\$' + re.escape(var) + r'(?![A-Za-z0-9_])',
                    env[var], line
                )
            resolved.append(line)

        return resolved

    @staticmethod
    def _normalise_version_tag(tag: str) -> str:
        """
        Normalise any git tag / branch name into a plain version string.

        Handles:
          v4.25.8          ->  4.25.8        (leading v)
          20240116.2       ->  20240116.2    (date/numeric, already clean)
          cares-1_19_1     ->  1.19.1        (prefix up to first digit run, _ -> .)
          cares-1_19_2     ->  1.19.2
          openssl-3.0.0    ->  3.0.0
          release-1.2.3    ->  1.2.3
          refs/tags/v1.0   ->  1.0
        """
        # Strip refs/tags/ prefix
        tag = re.sub(r'^refs/tags/', '', tag)
        # Strip leading 'v' or 'V'
        tag = tag.lstrip('vV')
        # If there is a non-numeric prefix followed by digits (e.g. "cares-1_19_1"),
        # drop everything up to and including the separator before the first digit run
        m = re.match(r'^[A-Za-z][A-Za-z0-9]*[-_](\d.*)', tag)
        if m:
            tag = m.group(1)
        # Replace underscores with dots (cares uses 1_19_1 style)
        tag = tag.replace('_', '.')
        return tag

    def _parse_build_script_libs(self) -> List[Dict]:
        """
        Parse the build script for source-built library name + version.

        Handles four patterns (after shell variable substitution):

          1. git clone + git checkout (most common)
               git clone https://github.com/protocolbuffers/protobuf
               git checkout v4.25.8

          2. git clone with inline -b branch/tag
               git clone https://github.com/abseil/abseil-cpp -b 20240116.2
               # Also resolves variable form:
               #   ABSEIL_URL=https://github.com/abseil/abseil-cpp
               #   ABSEIL_VERSION=20240116.2
               #   git clone $ABSEIL_URL -b $ABSEIL_VERSION

          3. wget/curl GitHub tarball
               wget https://github.com/org/lib/archive/refs/tags/v1.2.3.tar.gz
               curl -L https://github.com/org/lib/archive/v1.2.3.tar.gz

          4. git checkout with non-standard tag (e.g. cares-1_19_1)
               git clone https://github.com/c-ares/c-ares
               git checkout cares-1_19_1

        Variable substitution is done in a pre-pass so any of the above
        patterns work whether URLs/versions are literals or $VARIABLE refs.

        Returns list of { name, version, git_org, so_pattern }.
        Deduplicates by (name, version).
        """
        libs = []
        seen: Set[Tuple[str, str]] = set()  # (name, version) dedup

        if not self.build_script_path or not self.build_script_path.exists():
            print("  No build script provided — skipping Lane 3")
            return libs

        try:
            raw_lines = self.build_script_path.read_text(errors='ignore').splitlines()

            # ── Pre-pass: resolve shell variable substitutions ─────────────
            lines = self._resolve_shell_vars(raw_lines)

            pending_clone = None  # holds (name, git_org, raw_name) until version found

            for line in lines:
                line = line.strip()

                # ── Pattern 1 & 2: git clone ──────────────────────────────
                clone_match = re.search(
                    r'git\s+clone\s+.*github\.com/([^/\s]+)/([^/\s]+?)(?:\.git)?'
                    r'(?:\s+-b\s+([\S]+))?(?:\s|$)',
                    line
                )
                if clone_match:
                    git_org    = clone_match.group(1)
                    raw_name   = clone_match.group(2)
                    inline_tag = clone_match.group(3)  # -b value if present
                    name = re.sub(r'[-_]cpp$', '', raw_name, flags=re.IGNORECASE).lower()

                    if inline_tag:
                        # Pattern 2: version on the same line as clone
                        version = self._normalise_version_tag(inline_tag)
                        self._add_lib(libs, seen, name, raw_name, version, git_org)
                        pending_clone = None
                    else:
                        # Pattern 1: wait for next git checkout line
                        pending_clone = (name, git_org, raw_name)
                    continue

                # ── Pattern 1 & 4 continued: git checkout ─────────────────
                # Accept any tag after "git checkout" — not just digit-starting ones
                checkout_match = re.search(
                    r'git\s+checkout\s+(\S+)',
                    line
                )
                if checkout_match and pending_clone:
                    tag = checkout_match.group(1)
                    version = self._normalise_version_tag(tag)
                    # Only record if we ended up with something that starts with a digit
                    # (filters out branch names like "main", "master", sha hashes, etc.)
                    if version and re.match(r'^\d', version):
                        name, git_org, raw_name = pending_clone
                        self._add_lib(libs, seen, name, raw_name, version, git_org)
                        pending_clone = None
                    continue

                # ── Pattern 3: wget/curl GitHub tarball ───────────────────
                # e.g. wget https://github.com/ORG/REPO/archive/refs/tags/v1.2.3.tar.gz
                # e.g. curl -L https://github.com/ORG/REPO/archive/v1.2.3.tar.gz
                tarball_match = re.search(
                    r'(?:wget|curl)\s+.*github\.com/([^/\s]+)/([^/\s]+?)'
                    r'/(?:archive|releases/download)/(?:refs/tags/)?([^/\s]+?)'
                    r'(?:\.tar\.gz|\.tgz|\.zip)',
                    line
                )
                if tarball_match:
                    git_org  = tarball_match.group(1)
                    raw_name = tarball_match.group(2)
                    tag      = tarball_match.group(3)
                    version  = self._normalise_version_tag(tag)
                    if version and re.match(r'^\d', version):
                        name = re.sub(r'[-_]cpp$', '', raw_name, flags=re.IGNORECASE).lower()
                        self._add_lib(libs, seen, name, raw_name, version, git_org)
                        pending_clone = None
                    continue

        except Exception as e:
            print(f"  Warning: Error parsing build script: {e}")

        return libs

    def _add_lib(
        self,
        libs: List[Dict],
        seen: Set[Tuple[str, str]],
        name: str,
        raw_name: str,
        version: str,
        git_org: str
    ):
        """Add a source-built lib entry if not already seen (dedup by name+version)."""
        key = (name, version)
        if key in seen:
            return
        seen.add(key)
        libs.append({
            'name':       name,
            'raw_name':   raw_name,
            'version':    version,
            'git_org':    git_org,
            'so_pattern': f'lib{name}*'
        })
        print(f"  Parsed source-built lib: {name} v{version} (org={git_org})")

    def _nvd_get(self, url: str) -> Dict:
        """Single NVD API GET call. Reads NVD_API_KEY from environment."""
        req = urllib.request.Request(url)
        api_key = os.environ.get("NVD_API_KEY", "")
        if api_key:
            req.add_header("apiKey", api_key)
        try:
            with urllib.request.urlopen(req, timeout=30) as resp:
                return json.loads(resp.read())
        except Exception as e:
            print(f"  Warning: NVD API call failed ({url}): {e}")
            return {}

    # Language binding suffixes — deprioritised when scanning C/C++ .so files
    _LANG_SUFFIXES = (
        '-python', '-java', '-ruby', '-php', '-js',
        '-csharp', '-go', '-kotlin', '-objc', '-swift'
    )

    def _nvd_cpe_search(self, keyword: str, version: str) -> List[Tuple[str, str]]:
        """
        Query NVD CPE API for keyword+version and return deduplicated list of
        (vendor, product) pairs where the CPE version field exactly equals version.
        Language-binding variants are filtered out (we scan C/C++ .so files).
        """
        url = (f"{NVD_API_BASE}/cpes/2.0?"
               f"keywordSearch={urllib.parse.quote(keyword + ' ' + version)}")
        data = self._nvd_get(url)
        time.sleep(0.6 if os.environ.get("NVD_API_KEY") else 6.0)

        seen: Set[Tuple[str, str]] = set()
        matches = []
        for p in data.get('products', []):
            cpe_name = p.get('cpe', {}).get('cpeName', '')
            parts = cpe_name.split(':')
            if len(parts) < 6:
                continue
            if parts[5] != version:
                continue
            vendor, product = parts[3], parts[4]
            # Skip language-binding variants — not applicable to C/C++ .so
            if any(product.endswith(s) for s in self._LANG_SUFFIXES):
                continue
            pair = (vendor, product)
            if pair not in seen:
                seen.add(pair)
                matches.append(pair)
        return matches

    def _get_cpe_vendor(self, name: str, version: str, raw_name: str = "") -> Tuple[Optional[str], Optional[str]]:
        """
        Auto-discover vendor + product for a source-built library via NVD CPE API.

        Layered search strategy:
          Layer 1 — search using raw_name (e.g. "grpc-cpp", "abseil-cpp")
                    This catches cases where NVD stores the -cpp suffix.
                    Language-binding variants are filtered out.

          Layer 2 — search using stripped name (e.g. "grpc", "abseil")
                    Runs only when raw_name differs from name AND Layer 1 found
                    nothing.  Catches the common case where NVD drops the -cpp
                    suffix (e.g. grpc-cpp → grpc, abseil-cpp → common_libraries).

        After each layer, if exactly 1 non-language-binding match is found it is
        accepted.  If multiple remain, a tiebreaker prefers the product whose
        name exactly matches the search keyword.  If still ambiguous → unresolved.

        Real-world behaviour verified against NVD:
          grpc-cpp  1.68.0    → L1: 0,  L2: grpc:grpc          ✓
          abseil-cpp 20240116.2→ L1: 0,  L2: abseil:common_libs ✓
          protobuf  4.25.8   → L1: only protobuf-python (filtered) → unresolved ✓
          c-ares    1.19.1   → L1: c-ares:c-ares               ✓
        """
        # Determine the two search keywords
        stripped_name = name  # name already has -cpp stripped by parser
        raw_keyword   = raw_name.lower() if raw_name else stripped_name

        for layer, keyword in enumerate([raw_keyword, stripped_name], start=1):
            # Skip Layer 2 when keyword is same as Layer 1 (no -cpp was present)
            if layer == 2 and keyword == raw_keyword:
                break

            print(f"    Layer {layer} CPE search: '{keyword} {version}'")
            matches = self._nvd_cpe_search(keyword, version)

            if not matches:
                print(f"      No matches")
                continue

            if len(matches) == 1:
                vendor, product = matches[0]
                print(f"      CPE found: vendor={vendor} product={product}")
                return vendor, product

            # Multiple matches — tiebreaker: prefer product name == keyword
            exact = [(v, p) for v, p in matches if p == keyword]
            if len(exact) == 1:
                vendor, product = exact[0]
                print(f"      CPE tiebreaker (exact name): vendor={vendor} product={product}")
                return vendor, product

            # Still ambiguous — try next layer
            print(f"      {len(matches)} matches, ambiguous — trying next layer")

        print(f"    CPE not resolved for {name} v{version} — flagging as unresolved")
        return None, None

    def _get_nvd_cves(self, vendor: str, product: str, version: str) -> List[Dict]:
        """
        Call NVD CVE API with a confirmed CPE.
        Returns list of { cve_id, severity, score, description }.
        """
        cpe = f"cpe:2.3:a:{vendor}:{product}:{version}:*:*:*:*:*:*:*"
        url = (f"{NVD_API_BASE}/cves/2.0?"
               f"cpeName={urllib.parse.quote(cpe)}")
        data = self._nvd_get(url)
        # Rate limit: 0.6s with API key (50 req/30sec), 6s without (5 req/30sec)
        time.sleep(0.6 if os.environ.get("NVD_API_KEY") else 6.0)

        cves = []
        for m in data.get('vulnerabilities', []):
            cve = m.get('cve', {})
            cve_id = cve.get('id', '')

            # Severity — prefer CVSS 4.0, then 3.1, then 2.0
            sev, score = 'N/A', 'N/A'
            for key in ['cvssMetricV40', 'cvssMetricV31', 'cvssMetricV30', 'cvssMetricV2']:
                if key in cve.get('metrics', {}):
                    entry = cve['metrics'][key][0].get('cvssData', {})
                    sev   = entry.get('baseSeverity', 'N/A')
                    score = entry.get('baseScore', 'N/A')
                    break

            # English description
            description = ''
            for desc in cve.get('descriptions', []):
                if desc.get('lang') == 'en':
                    description = desc.get('value', '')[:200]
                    break

            cves.append({
                'cve_id':      cve_id,
                'severity':    sev,
                'score':       score,
                'description': description
            })

        return cves

    def _match_so_to_lib(self, bundled_libs: List[Dict], so_pattern: str) -> List[str]:
        """Return bundled filenames that match the given so_pattern (glob-style prefix)."""
        prefix = so_pattern.rstrip('*').lower()
        return [
            lib['bundled_filename'] for lib in bundled_libs
            if lib['bundled_filename'].lower().startswith(prefix)
        ]

    def _scan_source_built_libs(self) -> List[Dict]:
        """
        Lane 3: scan source-built C/C++ libraries via NVD CPE + CVE API.

        Option B matching strategy:
          Any bundled .so that Lane 2 could NOT match to an RPM package is
          considered source-built. These unmatched .so files are collected once
          and shared across all source-built libs parsed from the build script.
          This avoids fragile name-to-so-prefix guessing (e.g. abseil-cpp repo
          produces libabsl_* files, not libabseil_*).

        Flow:
          1. Collect all Lane-2-unmatched .so files → these are source-built
          2. Parse build script → unique (name, version) entries
          3. For each unique lib: CPE API → vendor, CVE API → CVEs
          4. Each lib entry references the full unmatched .so list
          5. Flag cpe_resolved=False if CPE lookup returns 0 or multiple matches
        """
        results = []

        # Parse source-built libs from build script
        source_libs = self._parse_build_script_libs()
        if not source_libs:
            return results

        bundled_libs = self.results['steps'].get('bundled_libs', [])
        library_mapping = self.results['steps'].get('library_mapping', [])

        # Collect ALL bundled .so files not matched by Lane 2 (RPM-owned)
        # These are the source-built candidates — shared across all Lane 3 libs
        rpm_matched = {
            m['bundled_filename'] for m in library_mapping
            if m['source_package'] != 'unknown'
        }
        unmatched_sos = [
            lib['bundled_filename'] for lib in bundled_libs
            if lib['bundled_filename'] not in rpm_matched
        ]

        print(f"  {len(unmatched_sos)} bundled .so file(s) not RPM-owned → source-built candidates")
        print(f"  Processing {len(source_libs)} source-built lib(s) from build script...")

        for lib in source_libs:
            name    = lib['name']
            version = lib['version']
            git_org = lib['git_org']

            print(f"\n  [{name} v{version}]")

            entry = {
                'name':             name,
                'version':          version,
                'git_org':          git_org,
                'matched_sos':      unmatched_sos,  # all unmatched .so files
                'cpe_resolved': True,
                'cves':             []
            }

            if not unmatched_sos:
                print(f"    No unmatched .so files — skipping CVE lookup")
                results.append(entry)
                continue

            # CPE API — get vendor (pass raw_name for layered search)
            vendor, product = self._get_cpe_vendor(name, version, lib.get('raw_name', ''))

            if vendor is None:
                entry['cpe_resolved'] = False
                print(f"    CVE lookup skipped — CPE not resolved")
                results.append(entry)
                continue

            # CVE API — get CVEs
            cves = self._get_nvd_cves(vendor, product, version)
            entry['vendor']  = vendor
            entry['product'] = product
            entry['cves']    = cves
            print(f"    Found {len(cves)} CVE(s) for {vendor}:{product}:{version}")
            results.append(entry)

        return results

    def _generate_final_report(self) -> Dict:
        """
        Generate the unified final CVE report combining Phase 1 + Phase 2.

        Section order in final_report:
          wheel_direct_scan     — Phase 1: CVEs found by grype on the wheel itself
                                  (deduplicated against Lane 1 + Lane 2)
          bundled_libraries     — Lane 2: hash-renamed .so → RPM owner → grype
          python_packages       — Lane 1: transitive Python dep → grype
          source_built_libraries— Lane 3: source-built C/C++ → NVD CPE/CVE API

        Deduplication rule:
          A (package, cve_id) pair already recorded in Lane 1 or Lane 2 is NOT
          added again to wheel_direct_scan.  CVEs only found by Phase 1 that
          neither lane covers are kept in wheel_direct_scan.
          total_unique_cve counts globally unique cve_ids across ALL sections.
        """
        report = {
            'wheel_file':             self.wheel_name,
            'scan_date':              self.results['scan_date'],
            'grype_available':        self.results.get('grype_available', False),
            'wheel_direct_scan':      [],   # Phase 1
            'bundled_libraries':      [],   # Lane 2
            'python_packages':        [],   # Lane 1
            'source_built_libraries': [],   # Lane 3
            # total_unique_cve  — globally unique CVE IDs across all sections
            #               e.g. CVE-2022-27943 counts once even if it affects
            #               libgfortran, libgomp and libquadmath all at once
            # total_cve — sum of per-library CVE occurrences
            #               e.g. CVE-2022-27943 × 3 libraries = 3 findings
            'total_unique_cve':     0,
            'total_cve': 0,
            'severity_breakdown': {
                'critical': 0,
                'high': 0,
                'medium': 0,
                'low': 0
            }
        }

        cve_scan = self.results['steps'].get('cve_scan', {})
        packages_with_cves = cve_scan.get('packages_with_cves', {})

        # Global dedup tracker — (pkg_name, cve_id) seen across all sections
        # Used to deduplicate Phase 1 results against Lane 1 + Lane 2.
        seen_pkg_cve: Set[Tuple[str, str]] = set()
        seen_cve_ids: Set[str] = set()  # for global unique CVE id count

        def _record_cve(cve: Dict, severity_override: str = "") -> None:
            """
            Increment counters for one CVE entry.
            - total_cve always increments (per-library occurrence count)
            - total_unique_cve + severity_breakdown only increment for new unique cve_ids
            """
            cve_id   = cve.get('cve_id', '')
            severity = (severity_override or cve.get('severity', 'unknown') or 'unknown').lower()
            report['total_cve'] += 1
            if cve_id not in seen_cve_ids:
                seen_cve_ids.add(cve_id)
                report['total_unique_cve'] += 1
                if severity in report['severity_breakdown']:
                    report['severity_breakdown'][severity] += 1

        # --- Lane 2: bundled .so CVEs ---
        library_mapping = self.results['steps'].get('library_mapping', [])
        for mapping in library_mapping:
            bundled_lib = {
                'bundled_filename': mapping['bundled_filename'],
                'source_package':   mapping['source_package'],
                'source_version':   mapping['source_version'],
                'cves':             []
            }
            pkg = mapping['source_package']
            if pkg in packages_with_cves:
                bundled_lib['cves'] = packages_with_cves[pkg]
                for cve in bundled_lib['cves']:
                    seen_pkg_cve.add((pkg, cve.get('cve_id', '')))
                    _record_cve(cve)
            report['bundled_libraries'].append(bundled_lib)

        # --- Lane 1: Python runtime dep CVEs ---
        python_deps = self.results['steps'].get('python_deps', {})
        for pkg_name, pkg_version in python_deps.get('packages', {}).items():
            python_pkg = {
                'package': pkg_name,
                'version': pkg_version,
                'cves':    []
            }
            if pkg_name in packages_with_cves:
                python_pkg['cves'] = packages_with_cves[pkg_name]
                for cve in python_pkg['cves']:
                    seen_pkg_cve.add((pkg_name, cve.get('cve_id', '')))
                    _record_cve(cve)
            report['python_packages'].append(python_pkg)

        # --- Lane 3: source-built library CVEs ---
        source_built_scan = self.results['steps'].get('source_built_scan', [])
        for lib in source_built_scan:
            source_lib = {
                'name':             lib['name'],
                'version':          lib['version'],
                'git_org':          lib['git_org'],
                'matched_sos':      lib.get('matched_sos', []),
                'cpe_resolved': lib.get('cpe_resolved', False),
                'cves':             lib.get('cves', [])
            }
            if lib.get('cpe_resolved'):
                source_lib['vendor']  = lib.get('vendor', '')
                source_lib['product'] = lib.get('product', '')
            for cve in source_lib['cves']:
                _record_cve(cve)
            report['source_built_libraries'].append(source_lib)

        # --- Phase 1: wheel direct scan (deduplicated against Lane 1 + Lane 2) ---
        wheel_direct = self.results['steps'].get('wheel_direct_scan', {})
        skipped = wheel_direct.get('skipped', False)
        unique_phase1 = []
        for match in wheel_direct.get('matches', []):
            pkg    = match.get('package', '')
            cve_id = match.get('cve_id', '')
            # Skip if already recorded by Lane 1 or Lane 2
            if (pkg, cve_id) in seen_pkg_cve:
                continue
            unique_phase1.append(match)
            seen_pkg_cve.add((pkg, cve_id))
            _record_cve({'cve_id': cve_id, 'severity': match.get('severity', '')})

        report['wheel_direct_scan'] = {
            'skipped':      skipped,
            'unique_cves':  unique_phase1,   # CVEs only found by Phase 1
            'total_found':  len(wheel_direct.get('matches', [])),
            'deduplicated': len(wheel_direct.get('matches', [])) - len(unique_phase1)
        }

        return report
    
    def save_report(self, output_file: str):
        """Save report to JSON file"""
        with open(output_file, 'w') as f:
            json.dump(self.results, f, indent=2)
        print(f"\nReport saved to: {output_file}")
    
    def print_summary(self):
        """Print summary of scan results"""
        report = self.results.get('final_report', {})

        print(f"\n{'='*70}")
        print("SCAN SUMMARY")
        print(f"{'='*70}")
        print(f"Wheel: {report.get('wheel_file')}")
        print(f"Scan Date: {report.get('scan_date')}")
        print(f"\nBundled Libraries: {len(report.get('bundled_libraries', []))}")
        print(f"Python Runtime Packages: {len(report.get('python_packages', []))}")
        print(f"Total Unique CVEs: {report.get('total_unique_cve', 0)}")
        print(f"Total CVEs:        {report.get('total_cve', 0)} "
              f"(per-library occurrences)")
        print(f"\nSeverity Breakdown (by unique CVE):")
        for severity, count in report.get('severity_breakdown', {}).items():
            print(f"  {severity.capitalize()}: {count}")

        print(f"\nCVEs by Bundled Library (.so):")
        for lib in report.get('bundled_libraries', []):
            cve_count = len(lib.get('cves', []))
            if cve_count > 0:
                print(f"\n  {lib['bundled_filename']}")
                print(f"    Source: {lib['source_package']} v{lib['source_version']}")
                print(f"    CVEs: {cve_count}")
                for cve in lib['cves'][:3]:
                    print(f"      - {cve['cve_id']} ({cve['severity']})")
                if cve_count > 3:
                    print(f"      ... and {cve_count - 3} more")

        print(f"\nCVEs by Python Package:")
        for pkg in report.get('python_packages', []):
            cve_count = len(pkg.get('cves', []))
            if cve_count > 0:
                print(f"\n  {pkg['package']} v{pkg['version']}")
                print(f"    CVEs: {cve_count}")
                for cve in pkg['cves'][:3]:
                    print(f"      - {cve['cve_id']} ({cve['severity']})")
                if cve_count > 3:
                    print(f"      ... and {cve_count - 3} more")

        print(f"\n{'='*70}\n")


def main():
    if len(sys.argv) < 2:
        print("Usage: python generalized_wheel_scanner.py <wheel_file.whl> [build_script.sh]")
        sys.exit(1)

    wheel_path = sys.argv[1]
    build_script_path = sys.argv[2] if len(sys.argv) > 2 else ""

    if not Path(wheel_path).exists():
        print(f"Error: Wheel file not found: {wheel_path}")
        sys.exit(1)

    if build_script_path and not Path(build_script_path).exists():
        print(f"Warning: Build script not found: {build_script_path} — Lane 3 will be skipped")
        build_script_path = ""

    # Create scanner
    scanner = WheelCVEScanner(wheel_path, build_script_path)
    
    # Run scan
    results = scanner.scan()
    
    # Print summary
    scanner.print_summary()
    
    # Save report
    output_file = f"{Path(wheel_path).stem}_cve_report.json"
    scanner.save_report(output_file)
    
    print(f"✓ Scan complete!")


if __name__ == '__main__':
    main()
