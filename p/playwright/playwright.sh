#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : playwright
# Version       : v1.61.0
# Source repo   : https://github.com/microsoft/playwright-python.git
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Stuti Wali <Stuti.Wali@ibm.com>
#
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="playwright"
PACKAGE_VERSION="${1:-v1.61.0}"
PACKAGE_URL="https://github.com/microsoft/playwright-python.git"
CLONE_DIR="playwright-python"

# Normalize tag prefix (supports both 1.61.0 and v1.61.0)
if [[ "$PACKAGE_VERSION" != v* ]]; then
    PACKAGE_VERSION="v${PACKAGE_VERSION}"
fi

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git make autoconf automake libtool python3 python3-devel python3-pip"
DEB_DEP_PKGS="git make autoconf automake libtool python3 python3-dev python3-pip python3-venv"
SLES_DEP_PKGS="git make autoconf automake libtool python3 python3-devel python3-pip"

# =============================================================================
# CALLBACK: post_clone
# Applies Power support patch for Playwright driver and setup.py
# Writes package version to playwright/_repo_version.py
# =============================================================================
post_clone() {
    log_info "Applying power support patch..."
    if [[ -f "${SCRIPT_DIR}/patches/power_support.patch" ]]; then
        git apply "${SCRIPT_DIR}/patches/power_support.patch"
    elif [[ -f "${SCRIPT_DIR}/power_support.patch" ]]; then
        git apply "${SCRIPT_DIR}/power_support.patch"
    fi

    local raw_version="${PACKAGE_VERSION#v}"
    log_info "Writing version '${raw_version}' to playwright/_repo_version.py"
    echo "version = \"${raw_version}\"" > playwright/_repo_version.py

    if [[ -f "pyproject.toml" ]]; then
        local setuptools_req
        setuptools_req="$(python3 -c '
import re, sys
try:
    import tomllib
    with open("pyproject.toml", "rb") as f:
        data = tomllib.load(f)
    reqs = data.get("build-system", {}).get("requires", [])
except Exception:
    reqs = []
    try:
        with open("pyproject.toml", "r") as f:
            content = f.read()
        m = re.search(r"requires\s*=\s*\[(.*?)\]", content, re.DOTALL)
        if m:
            reqs = re.findall(r"[\x22\x27]([^\x22\x27]+)[\x22\x27]", m.group(1))
    except Exception:
        pass
for req in reqs:
    if req.startswith("setuptools") and not req.startswith(("setuptools-scm", "setuptools_scm")):
        print(req[len("setuptools"):].strip())
        break
' 2>/dev/null)"
        if [[ -n "$setuptools_req" ]]; then
            SETUPTOOLS_VERSION="$setuptools_req"
            log_info "Using dynamic SETUPTOOLS_VERSION='${SETUPTOOLS_VERSION}' from pyproject.toml"
        fi
    fi
}

# =============================================================================
# CALLBACK: pre_build — dynamically install build-system requires from pyproject.toml
# =============================================================================
pre_build() {
    log_info "Fetching and installing build-system dependencies dynamically from pyproject.toml..."
    if [[ -f "pyproject.toml" ]]; then
        local build_reqs
        build_reqs="$(python -c '
import re, sys
try:
    import tomllib
    with open("pyproject.toml", "rb") as f:
        data = tomllib.load(f)
    reqs = data.get("build-system", {}).get("requires", [])
except Exception:
    reqs = []
    try:
        with open("pyproject.toml", "r") as f:
            content = f.read()
        m = re.search(r"requires\s*=\s*\[(.*?)\]", content, re.DOTALL)
        if m:
            reqs = re.findall(r"[\x22\x27]([^\x22\x27]+)[\x22\x27]", m.group(1))
    except Exception:
        pass
if reqs:
    print(" ".join(f"\"{r}\"" for r in reqs))
' 2>/dev/null)"
        if [[ -n "$build_reqs" ]]; then
            log_info "Dynamically installing build requirements: ${build_reqs}"
            eval "python -m pip install ${build_reqs}"
            return 0
        fi
    fi
    log_info "Fallback: Installing unpinned build-system dependencies..."
    python -m pip install setuptools setuptools-scm wheel auditwheel
}

# =============================================================================
# CALLBACK: custom_test_command — import smoke test
# =============================================================================
custom_test_command() {
    log_info "Running import smoke test (browser tests skipped: no upstream ppc64le browser binaries)"
    python -c "import playwright; from playwright.sync_api import sync_playwright; from playwright.async_api import async_playwright; print('Playwright import test successful')"
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
