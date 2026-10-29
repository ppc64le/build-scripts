#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : tree-sitter-typescript
# Version       : v0.23.2
# Source repo   : https://github.com/tree-sitter/tree-sitter-typescript
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Yussuf Shaikh <yussufsh>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="tree-sitter-typescript"
PACKAGE_VERSION="${1:-v0.23.2}"
PACKAGE_URL="https://github.com/tree-sitter/tree-sitter-typescript"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="clang-devel cmake gcc-toolset-13 git make nodejs python3-devel sudo wget"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: post_clone — fix tsx/src/parser.c compilation and read
#   SETUPTOOLS_VERSION from pyproject.toml.
#
#   The build runs as: sdist → wheel-from-sdist.  The sdist only bundles
#   tsx/src/parser.c and tsx/src/scanner.c; the tsx/src/tree_sitter/ headers
#   are excluded.  Two fixes are needed:
#
#   1. Copy typescript/src/tree_sitter/ headers into tsx/src/tree_sitter/ so
#      the original clone tree (and any sdist build temp tree) has them.
#   2. Create MANIFEST.in to include tsx/src/tree_sitter/*.h in the sdist so
#      the wheel-from-sdist build can also find the headers.
#   3. Patch setup.py to add "tsx/src" to include_dirs so gcc receives
#      -Itsx/src and resolves the header via that path as a fallback.
# =============================================================================
post_clone() {
    log_info "Copying tree_sitter/ headers into tsx/src/ for tsx grammar compilation..."
    mkdir -p tsx/src/tree_sitter
    cp -f typescript/src/tree_sitter/parser.h tsx/src/tree_sitter/parser.h
    cp -f typescript/src/tree_sitter/alloc.h  tsx/src/tree_sitter/alloc.h
    cp -f typescript/src/tree_sitter/array.h  tsx/src/tree_sitter/array.h

    log_info "Creating MANIFEST.in to include tsx/src/tree_sitter headers in the sdist..."
    cat > MANIFEST.in <<'EOF'
recursive-include typescript/src/tree_sitter *.h
recursive-include tsx/src/tree_sitter *.h
EOF

    log_info "Patching setup.py: adding tsx/src to include_dirs..."
    sed -i 's/include_dirs=\["typescript\/src"\]/include_dirs=["typescript\/src", "tsx\/src"]/' setup.py

    log_info "Reading setuptools version requirement from pyproject.toml"
    if [[ -f "pyproject.toml" ]]; then
        setuptools_req="$(grep -o '"setuptools[^"]*"' pyproject.toml | head -1 | tr -d '"')"
        if [[ -n "$setuptools_req" ]]; then
            SETUPTOOLS_VERSION="${setuptools_req#setuptools}"
            SETUPTOOLS_VERSION="${SETUPTOOLS_VERSION//[[:space:]]/}"
            log_info "Using SETUPTOOLS_VERSION='${SETUPTOOLS_VERSION}' from pyproject.toml"
        else
            log_info "No setuptools pin found in pyproject.toml — using template default"
        fi
    else
        SETUPTOOLS_VERSION="<82"
        log_info "No pyproject.toml found — falling back to SETUPTOOLS_VERSION='${SETUPTOOLS_VERSION}'"
    fi
}

# =============================================================================
# CALLBACK: pre_build — install tree-sitter runtime dependency
# =============================================================================
pre_build() {
    log_info "Installing tree-sitter runtime for ${PACKAGE_NAME} ${PACKAGE_VERSION}..."
    python -m pip install "tree-sitter~=0.23"
}

# =============================================================================
# CALLBACK: pre_test — mirror build dependencies and install package for tests
# =============================================================================
pre_test() {
    log_info "Upgrading pip, setuptools, wheel in test venv..."
    python -m pip install --upgrade pip setuptools wheel
    python -m pip install "tree-sitter~=0.23"
    log_info "Installing package in editable mode with core extras for binding tests..."
    python -m pip install -e ".[core]"
}

# =============================================================================
# CALLBACK: custom_test_command — run binding tests via unittest discover
# =============================================================================
custom_test_command() {
    log_info "Running binding tests..."
    python -m unittest discover -v -s bindings/python/tests
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
