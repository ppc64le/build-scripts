#!/usr/bin/env python3
"""
check-wheel-version.py
Validates a built wheel's version before post-processing.

Two checks:
  1. VERSION MATCH  — wheel base version must correspond to GITHUB_PACKAGE_VERSION / PACKAGE_VERSION.
  2. CLEAN VERSION  — wheel must not contain an unintended git-injected local identifier.

Usage:
    python3 check-wheel-version.py <wheel_filename> <github_package_version>

Requirements: pip install packaging

Exit codes:
    0  both checks passed
    1  one or both checks failed
"""

import re
import sys

try:
    from packaging.specifiers import SpecifierSet
    from packaging.utils import InvalidWheelFilename, parse_wheel_filename
    from packaging.version import InvalidVersion, Version
except ImportError:
    # Graceful fallback parser if packaging is not installed
    class InvalidWheelFilename(Exception):
        pass

    class InvalidVersion(Exception):
        pass

    class Version:
        def __init__(self, v_str):
            self.raw = v_str
            # extract local segment
            if "+" in v_str:
                self.base_version, self.local = v_str.split("+", 1)
            else:
                self.base_version, self.local = v_str, None

        def __str__(self):
            return self.raw

    class SpecifierSet:
        def __init__(self, spec, prereleases=True):
            self.spec = spec.lstrip("=").rstrip(".*")

        def __contains__(self, item):
            return str(item).startswith(self.spec)

    def parse_wheel_filename(filename):
        m = re.match(r"^([^-]+)-([^-]+?)(?:-([0-9][^-]*))?-([^-]+)-([^-]+)-([^-]+)\.whl$", filename)
        if not m:
            raise InvalidWheelFilename(f"Invalid wheel filename: {filename}")
        dist, ver, build, py, abi, plat = m.groups()
        return dist, Version(ver), build, (py, abi, plat)


# ---------------------------------------------------------------------------
# Compiled patterns
# ---------------------------------------------------------------------------

# Detects a git-hash local segment (6+ hex chars, optional leading 'g').
# Matches:   g1892993bc  56be3b5e  g6909efdd6
# No match:  cpu  cuda118  rocm6  cpu.ppc64le  ubi9  ppc64le1
_GIT_HASH_RE = re.compile(r"(?:^|\.)g?[0-9a-f]{6,}(?:\.|$)", re.IGNORECASE)

# Strips operator separators — e.g. pkg==1.2.3  pkg@1.2.3
_RE_OPERATOR = re.compile(r"^[^@=\s]+(?:@|==)(\S+)")

# Strips common textual version prefixes — e.g. v1.2  release-v1.2  RELEASE__3_100  rel_1_2  n7 (ffmpeg)
_RE_PREFIX = re.compile(r"^(?:release[-_]*v?|rel[-_]*|version[-_]*|v[-_]*|n(?=\d))", re.IGNORECASE)

# Strips a leading package-name segment — e.g. azure-mgmt-batch_18.0.0  jaxlib-v0.4.7  cares-1_19_1
_RE_PKG_PREFIX = re.compile(r"^[a-zA-Z][\w-]*?[-_]+v?(\d[^\n]*)")

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _is_dirty_local(local: str) -> bool:
    """Return True if *local* contains a setuptools-scm git-hash segment."""
    return bool(_GIT_HASH_RE.search(local))


def _normalize_version(github_package_version: str) -> str:
    """Return a bare version number from any common tagging convention.

    Strips (in order):
      1. Operator separators  pkg==1.2.3  pkg@1.2.3
      2. Textual prefixes     v  release-v  RELEASE__  rel_  version_  n (ffmpeg)
      3. Package-name prefix  azure-mgmt-batch_18.0.0  jaxlib-v0.4.7
      4. Underscores/hyphens between numbers → dot     1_4_39 → 1.4.39, 3_100 → 3.100
    """
    s = github_package_version.strip()
    m = _RE_OPERATOR.match(s)
    if m:
        s = m.group(1)
    s = _RE_PREFIX.sub("", s)
    m = _RE_PKG_PREFIX.match(s)
    if m:
        s = m.group(1)
    # Strip any remaining leading or trailing punctuation from prefix stripping
    s = s.strip("._-")
    # Replace multiple underscores or hyphens between digits with dots
    return re.sub(r"[-_]+", ".", s)


def version_matches(wheel_ver: Version, norm: str) -> bool:
    """Return True if *wheel_ver* corresponds to the already-normalised *norm*."""
    # Tier 1: SpecifierSet matching
    try:
        norm_base = Version(norm).base_version if hasattr(Version(norm), "base_version") else norm
        spec = SpecifierSet(f"=={norm_base}.*", prereleases=True)
        if str(wheel_ver) in spec or getattr(wheel_ver, "base_version", str(wheel_ver)) in spec:
            return True
    except (InvalidVersion, Exception):
        pass

    # Tier 2: Exact equality fallback
    base = getattr(wheel_ver, "base_version", str(wheel_ver))
    return base == norm or base.replace(".", "_") == norm.replace(".", "_") or base.startswith(norm)

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> None:
    if len(sys.argv) < 3:
        print("Usage: check-wheel-version.py <wheel_filename> <github_package_version>")
        sys.exit(1)

    wheel_filename = sys.argv[1]
    github_package_version = sys.argv[2].strip()

    try:
        _, ver, _, _ = parse_wheel_filename(wheel_filename)
    except InvalidWheelFilename as exc:
        print(f"ERROR: Cannot parse wheel filename: {exc}")
        sys.exit(1)

    sep = "=" * 60
    print(f"\n{sep}")
    print("Wheel Version Validation")
    print(sep)
    print(f"  Wheel    : {wheel_filename}")
    print(f"  Expected : {github_package_version}")
    base_ver = getattr(ver, "base_version", str(ver))
    print(f"  Got      : {ver}  (base: {base_ver})")
    print(sep)

    failed = False
    norm = _normalize_version(github_package_version)

    # Check 1: version match
    if not any(c.isdigit() for c in github_package_version):
        print(f"  SKIP [1] Version match  ('{github_package_version}' is a string/symbolic name, skipping check)")
    elif version_matches(ver, norm):
        print(f"  PASS [1] Version match  ({base_ver} matches {github_package_version})")
    else:
        print("  FAIL [1] Version mismatch!")
        print(f"           Expected  : {github_package_version}")
        print(f"           Normalised: {norm}")
        print(f"           Got       : {base_ver}")
        if norm == github_package_version:
            print(f"           _normalize_version did not recognise the format of '{github_package_version}'.")
        else:
            print("           The build script produced a different version than requested.")
            print(f"           Ensure it checks out / pins {github_package_version}")
        failed = True

    # Check 2: no git-injected local identifier
    local_ver = getattr(ver, "local", None)
    if local_ver is None:
        print("  PASS [2] Clean version  (no local identifier)")
    elif _is_dirty_local(str(local_ver)):
        print(f"  FAIL [2] Git-injected local identifier: +{local_ver}")
        print(f"           Got      : {ver}")
        print(f"           Expected : {base_ver}  (no git hash)")
        print("           setuptools-scm injected a commit hash because the")
        print("           source tree was not at a clean tagged commit.")
        print("           Ensure the build script checks out the exact release tag.")
        failed = True
    else:
        print(f"  PASS [2] Intentional local variant  (+{local_ver})")

    print()
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()

