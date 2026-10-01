#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : cysignals
# Version       : 1.11.4
# Source repo   : https://github.com/sagemath/cysignals
# Tested on     : UBI 9.6
# Language      : Python, C
# Script License: GNU Lesser General Public License v3.0
# Maintainer    : Vrusha Naik <Vrusha.Naik@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="cysignals"
PACKAGE_VERSION="${1:-1.11.4}"
PACKAGE_URL="https://github.com/sagemath/cysignals"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
# cysignals requires Cython and build system (setuptools or meson-python)
# Version 1.11.4 uses setuptools, later versions (1.12+) use meson-python
RH_DEP_PKGS="git gcc-toolset-13 gcc-toolset-13-gcc gcc-toolset-13-gcc-c++ make cmake autoconf automake libtool python3 python3-devel"
DEB_DEP_PKGS="git gcc g++ make cmake autoconf automake libtool python3 python3-dev python3-venv"
SLES_DEP_PKGS=""

# =============================================================================
# OPTIONAL: Build configuration
# =============================================================================
# Build system varies by version: setuptools (<=1.11.x) or meson-python (>=1.12)

# =============================================================================
# CALLBACK: pre_build - Install build dependencies
# =============================================================================
pre_build() {
    log_info "Installing build dependencies..."
    
    # Install tomli first - required to parse pyproject.toml
    # Note: tomli is built into Python 3.11+ as tomllib, but we need the backport for consistency
    log_info "Installing tomli for pyproject.toml parsing..."
    python -m pip install tomli
    
    # Extract and install build-system requirements from pyproject.toml
    # This makes the script version-agnostic - each version specifies its own requirements
    if [[ -f "pyproject.toml" ]]; then
        log_info "Extracting build-system requirements from pyproject.toml..."
        
        # Install requirements one by one to handle environment markers correctly
        python3 -c "
import tomli
import subprocess
import sys

with open('pyproject.toml', 'rb') as f:
    requires = tomli.load(f)['build-system']['requires']
    
# Install all at once - pip handles markers
subprocess.run([sys.executable, '-m', 'pip', 'install'] + requires, check=True)
"
    else
        # Fallback for older versions without pyproject.toml (unlikely for cysignals)
        log_warn "pyproject.toml not found, using fallback dependencies"
        log_info "Installing setuptools and Cython (common build dependencies)"
        python -m pip install setuptools "cython>=0.28"
    fi
    
    # Install setuptools-scm for version detection from git tags
    python -m pip install setuptools-scm
}

# =============================================================================
# CALLBACK: custom_test_command - Run cysignals tests
# =============================================================================
custom_test_command() {
    log_info "Running cysignals test suite..."

    # cysignals test structure varies by version:
    # - v1.11.x: uses rundoctests.py to run doctests in .pyx files
    # - v1.12+: uses pytest with src/ and tests/ directories

    local test_cmd=""
    local test_description=""

    # Determine test method based on available files/directories
    if [[ -d "tests" ]]; then
        # v1.12+: pytest with src and tests directories
        test_cmd="python -m pytest --import-mode=importlib --doctest-modules src tests"
        test_description="pytest with src and tests directories (v1.12+)"
    elif [[ -f "rundoctests.py" ]]; then
        # v1.11.x: custom rundoctests.py script
        test_cmd="python rundoctests.py src/cysignals/*.pyx"
        test_description="doctests using rundoctests.py (v1.11.x)"
    else
        # Fallback: test installed module
        test_cmd="python -m pytest --import-mode=importlib --doctest-modules --pyargs cysignals"
        test_description="pytest on installed module (fallback)"
    fi

    # Run the test
    log_info "Running $test_description"
    if eval "$test_cmd"; then
        log_info "✓ cysignals tests passed"
        return 0
    else
        log_error "✗ cysignals tests failed"
        return 1
    fi
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
