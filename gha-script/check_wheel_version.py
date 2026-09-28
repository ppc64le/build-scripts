#!/usr/bin/env python3

"""
check_wheel_version.py
Validates a built wheel's version before post-processing.

Two checks:
  1. VERSION MATCH  — wheel base version must correspond to GITHUB_PACKAGE_VERSION.
  2. CLEAN VERSION  — wheel must not contain a git-injected local identifier.

Usage:
    python check_wheel_version.py <wheel_filename> <github_package_version>

Requirements: pip install packaging

Exit codes:
    0  both checks passed
    1  one or both checks failed
"""

import re
import sys

from packaging.specifiers import SpecifierSet
from packaging.utils import InvalidWheelFilename, parse_wheel_filename
from packaging.version import InvalidVersion, Version

# ---------------------------------------------------------------------------
# Compiled patterns
# ---------------------------------------------------------------------------

# Detects a git-hash local segment (6+ hex chars, optional leading 'g').
# Matches:   g1892993bc  56be3b5e  g6909efdd6
# No match:  cpu  cuda118  rocm6  cpu.ppc64le
_GIT_HASH_RE = re.compile(r"(?:^|\.)g?[0-9a-f]{6,}(?:\.|$)", re.IGNORECASE)

# Strips operator separators — e.g. pkg==1.2.3  pkg@1.2.3
_RE_OPERATOR = re.compile(r"^[^@=\s]+(?:@|==)(\S+)")

# Strips common textual version prefixes — e.g. v1.2  release-v1.2  rel_1_2  n7 (ffmpeg)
# To add a new prefix pattern, extend this alternation.
_RE_PREFIX = re.compile(r"^(?:release-v|release[-_]|rel_|version_|v|n(?=\d))", re.IGNORECASE)

# Strips a leading package-name segment — e.g. azure-mgmt-batch_18.0.0  jaxlib-v0.4.7  cares-1_19_1
# To add a new package-name pattern, extend this regex.
_RE_PKG_PREFIX = re.compile(r"^[a-zA-Z][\w-]*?[-_]v?(\d[^\n]*)")

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
      2. Textual prefixes     v  release-v  rel_  version_  n (ffmpeg)
      3. Package-name prefix  azure-mgmt-batch_18.0.0  jaxlib-v0.4.7
      4. Underscore → dot     1_4_39 → 1.4.39

    Returns the input unchanged when no rule matches — the caller can detect
    this (norm == github_package_version) and hint that a new regex rule may
    be needed.
    """
    s = github_package_version.strip()
    m = _RE_OPERATOR.match(s)
    if m:
        s = m.group(1)
    s = _RE_PREFIX.sub("", s)
    m = _RE_PKG_PREFIX.match(s)
    if m:
        s = m.group(1)
    return s.replace("_", ".")


def version_matches(wheel_ver: Version, norm: str) -> bool:
    """Return True if *wheel_ver* corresponds to the already-normalised *norm*.

    Tier 1 — SpecifierSet: handles PEP 440 versions including dev/rc/post/local
      on the correct base (e.g. 1.14.0.dev0 matches norm '1.14.0').

    Tier 2 — Exact equality fallback: for numeric strings that are not valid
      PEP 440 (e.g. date-based '20220401').
    """
    # Tier 1
    try:
        spec = SpecifierSet(f"=={Version(norm).base_version}.*", prereleases=True)
        return str(wheel_ver) in spec
    except InvalidVersion:
        pass

    # Tier 2
    base = wheel_ver.base_version
    return base == norm or base.replace(".", "_") == norm.replace(".", "_")

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> None:
    if len(sys.argv) != 3:
        print("Usage: check_wheel_version.py <wheel_filename> <github_package_version>")
        sys.exit(1)

    wheel_filename         = sys.argv[1]
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
    print(f"  Got      : {ver}  (base: {ver.base_version})")
    print(sep)

    failed = False
    norm = _normalize_version(github_package_version)

    # Check 1: version match
    if version_matches(ver, norm):
        print(f"  PASS [1] Version match  ({ver.base_version} matches {github_package_version})")
    else:
        print("  FAIL [1] Version mismatch!")
        print(f"           Expected  : {github_package_version}")
        print(f"           Normalised: {norm}")
        print(f"           Got       : {ver.base_version}")
        if norm == github_package_version:
            # _normalize_version made no change — likely an unrecognised tag format.
            print(f"           _normalize_version did not recognise the format of '{github_package_version}'.")
            print("           If this is a new tag convention, add a rule to")
            print("           _RE_PREFIX or _RE_PKG_PREFIX in check_wheel_version.py.")
        else:
            print("           The build script produced a different version than requested.")
            print(f"           Ensure it checks out / pins {github_package_version}")
        failed = True

    # Check 2: no git-injected local identifier.
    # Intentional variant labels (+cpu, +cuda118, +rocm6) are allowed.
    if ver.local is None:
        print("  PASS [2] Clean version  (no local identifier)")
    elif _is_dirty_local(str(ver.local)):
        print(f"  FAIL [2] Git-injected local identifier: +{ver.local}")
        print(f"           Got      : {ver}")
        print(f"           Expected : {ver.base_version}  (no git hash)")
        print("           setuptools-scm injected a commit hash because the")
        print("           source tree was not at a clean tagged commit.")
        print("           Ensure the build script checks out the exact release tag.")
        failed = True
    else:
        print(f"  PASS [2] Intentional local variant  (+{ver.local})")

    print()
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
