#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : z3-solver
# Version       : z3-4.15.4
# Source repo   : https://github.com/Z3Prover/z3
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2.0 or later
# Maintainer    : Daniel Schenker <daniel.schenker@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="z3-solver"
PACKAGE_VERSION="${1:-z3-4.15.4}"
PACKAGE_URL="https://github.com/Z3Prover/z3"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git gcc-c++ make python3-devel"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: post_clone — patch setup.py for ppc64le wheel tag
# =============================================================================
post_clone() {
    log_info "Patching src/api/python/setup.py for ppc64le wheel tag"
    python - <<'PYEOF'
from pathlib import Path
p = Path("src/api/python/setup.py")
src = p.read_text()
entry = "    ('linux', 'ppc64le'): 'manylinux2014_ppc64le',\n"
if entry in src:
    print("  setup.py already patched — skipping")
elif "TAGS = {" in src:
    p.write_text(src.replace("TAGS = {", "TAGS = {\n" + entry, 1))
    print("  setup.py patched OK")
else:
    raise SystemExit("Could not find TAGS dict in setup.py")
PYEOF
}

# =============================================================================
# CALLBACK: custom_install — build native Z3 library then Python bindings
# =============================================================================
custom_install() {
    local REPO_DIR
    REPO_DIR="$(pwd)"

    local _nproc
    _nproc=$(nproc 2>/dev/null || echo 4)
    local jobs=$(( _nproc > 4 ? 4 : _nproc ))

    export MAX_JOBS=${jobs}
    export CPU_COUNT=${jobs}
    export MAKEFLAGS="-j${jobs}"
    export CMAKE_BUILD_PARALLEL_LEVEL=${jobs}
    log_info "Configured build concurrency: MAX_JOBS=${MAX_JOBS} (host reports ${_nproc} cores)"

    log_info "Installing build and wheel packages"
    python -m pip install --upgrade pip setuptools wheel build
    
    log_info "Building Z3 native library using mk_make.py"

    # Build Z3 native library using the bundled mk_make.py build system
    # Do NOT pass --python/--pypkgdir here: mk_make.py requires --pypkgdir to live
    # under --prefix (/usr), which a source-relative path never satisfies.
    # The Python wheel is built separately via setup.py below.
    python scripts/mk_make.py

    cd "${REPO_DIR}/build"
    make

    log_info "Installing Z3 native library system-wide"
    make install

    # Build and install the Python bindings wheel
    cd "${REPO_DIR}/src/api/python"

    log_info "Building Python wheel for z3-solver"
    python setup.py bdist_wheel

    log_info "Installing z3-solver Python package"
    python -m pip install dist/*.whl

    # Copy wheel to repo root for artifact collection (BUILD_DIR is not set in custom_install)
    cp dist/*.whl "${REPO_DIR}/" 
}

# =============================================================================
# CALLBACK: custom_test_command — run z3 smoke test
# =============================================================================
custom_test_command() {
    log_info "Running z3 basic smoke test"
    python -c "import z3; s = z3.Solver(); x = z3.Int('x'); s.add(x > 0); assert str(s.check()) == 'sat'; print('z3 basic smoke test passed')"
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
