#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : clawpack
# Version       : v5.12.0
# Source repo   : https://github.com/clawpack/clawpack
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Anumala Rajesh <Anumala.Rajesh@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="clawpack"
PACKAGE_VERSION="${1:-v5.12.0}"
PACKAGE_URL="https://github.com/clawpack/clawpack"
# =============================================================================
# REQUIRED: Dependencies
# System packages needed for building clawpack
# Key: gfortran is REQUIRED for the Riemann solvers (Fortran code)
# =============================================================================
RH_DEP_PKGS="git python3-devel python3-pip gcc gcc-c++ gcc-gfortran make cmake diffutils"
RH_DEP_PKGS="${RH_DEP_PKGS} openssl-devel bzip2-devel libffi-devel zlib-devel"
RH_DEP_PKGS="${RH_DEP_PKGS} libjpeg-turbo-devel freetype-devel libwebp-devel"
RH_DEP_PKGS="${RH_DEP_PKGS} graphviz"

DEB_DEP_PKGS=""   # not validated on Debian/Ubuntu

SLES_DEP_PKGS=""  # not validated on SUSE

# =============================================================================
# CALLBACK: pre_clone
# Set up Fortran compiler environment variables before cloning.
# =============================================================================
pre_clone() {
    log_info "Setting up Fortran compiler environment..."
    export FC=gfortran
    export F77=gfortran
    export F90=gfortran
}

# =============================================================================
# CALLBACK: post_clone
# Set up clawpack environment variables and run setup.py git-dev.
# =============================================================================
post_clone() {
    export CLAW=$(pwd)
    export GEOCLAW=$CLAW/geoclaw
    export RIEMANN=$CLAW/riemann
    export CLAWUTIL=$CLAW/clawutil
    export AMRCLAW=$CLAW/amrclaw
    export PYTHONPATH=$CLAW:$PYTHONPATH
    export PATH=$CLAW/clawutil/src:$PATH

    log_info "CLAW environment set: $CLAW"

    # Register all submodule sub-packages before build
    log_info "Running setup.py git-dev..."
    if ! python setup.py git-dev; then
        log_warn "setup.py git-dev failed or not available, continuing..."
    fi
}

# =============================================================================
# CALLBACK: pre_build
# Install numpy and meson build stack INTO THE VENV before custom_install.
#
# WHY numpy must be installed here (outside the source checkout):
#   clawpack's meson.build:24 calls numpy.get_include() and passes the result
#   to include_directories(). Meson >= 0.61.0 rejects any include path that
#   starts with the meson source-tree root (/workspace/clawpack).
#
#   The template venv (.venv-build) lives at /workspace/clawpack/.venv-build.
#   If numpy is installed there, get_include() returns a path inside the
#   source tree -> meson rejects it.
#
#   The fix (matching the upstream CI approach) is to install numpy into a
#   location OUTSIDE the source tree before the build runs, then put that
#   location first on PYTHONPATH so meson's run_command finds it.
#   numpy installed at /workspace/numpy_extern/... does not start with
#   /workspace/clawpack -> meson check passes.
# =============================================================================
pre_build() {
    log_info "Installing meson build stack..."
    python -m pip install meson-python meson ninja patchelf auditwheel cython

    log_info "Installing numpy outside source tree (required for meson include_directories check)..."
    # Install numpy into a sibling directory of the source checkout so that
    # numpy.get_include() returns a path outside /workspace/clawpack.
    local numpy_extern
    numpy_extern="$(dirname "$(pwd)")/numpy_extern"
    python -m pip install numpy --target "$numpy_extern"
    export PYTHONPATH="$numpy_extern:${PYTHONPATH:-}"
    log_info "numpy_extern: $numpy_extern"
    log_info "numpy.get_include() -> $(python -c "import numpy; print(numpy.get_include())")"
}

# =============================================================================
# CALLBACK: pre_test
# Install clawpack runtime and test dependencies into the test venv.
# numpy must be force-installed into .venv-test even though PYTHONPATH still
# points to numpy_extern from pre_build. Without --ignore-installed, pip sees
# numpy already satisfied via PYTHONPATH and skips it — but custom_test_command
# runs python -I (isolated mode) which ignores PYTHONPATH, so numpy would be
# missing from the test venv and every import would fail.
# =============================================================================
pre_test() {
    log_info "Installing Clawpack test dependencies..."
    python -m pip install --ignore-installed numpy
    python -m pip install pynose matplotlib pandas xarray pytest
}

# =============================================================================
# CALLBACK: custom_test_command
# Run Clawpack regression checks from the upstream test locations.
# =============================================================================
custom_test_command() {
    # Do not prepend $CLAW during tests; it shadows the installed package and
    # can hide compiled Riemann extension modules behind the source tree.
    export PYTHONPATH="${PYTHONPATH#"$CLAW:"}"

    local test_status=0

    log_info "Verifying Clawpack Python modules..."
    python -I -c "from clawpack import pyclaw, riemann; import clawpack.geoclaw, clawpack.classic, clawpack.amrclaw"

    log_info "Verifying isolated-mode test dependencies..."
    python -I -c "import numpy, matplotlib, pandas, xarray, PIL"

    run_required_regression_tests() {
        local test_root="$1"
        shift

        if [[ ! -d "$test_root" ]]; then
            log_error "Regression test root not found: $test_root"
            test_status=1
            false; return
        fi

        local test_target missing_target=0
        for test_target in "$@"; do
            if [[ ! -e "$test_root/$test_target" ]]; then
                log_error "Regression test target not found: $test_root/$test_target"
                missing_target=1
            fi
        done

        if [[ "$missing_target" -ne 0 ]]; then
            test_status=1
            false; return
        fi

        log_info "Running regression tests in $test_root${*:+: $*}"
        local test_output test_rc=0
        test_output="$(cd "$test_root" && python -I -m nose -sv "$@" 2>&1)" || test_rc=$?
        printf '%s\n' "$test_output"

        if [[ "${test_rc:-0}" -ne 0 ]]; then
            log_error "Regression test command failed in $test_root with exit code $test_rc"
            test_status=$test_rc
            false; return
        fi

        if grep -q "Ran 0 tests" <<< "$test_output"; then
            log_error "Regression test command collected zero tests in $test_root"
            test_status=1
        fi
    }

    run_optional_regression_tests() {
        local test_root="$1"
        shift

        if [[ ! -d "$test_root" ]]; then
            log_warn "Optional regression test root not found: $test_root"
            false; return
        fi

        local test_target existing_targets=()
        for test_target in "$@"; do
            if [[ -e "$test_root/$test_target" ]]; then
                existing_targets+=("$test_target")
            else
                log_warn "Optional regression test target not found: $test_root/$test_target"
            fi
        done

        if [[ "${#existing_targets[@]}" -eq 0 ]]; then
            log_warn "No optional regression test targets found in $test_root"
            false; return
        fi

        log_info "Running optional regression tests in $test_root: ${existing_targets[*]}"
        local test_output test_rc=0
        test_output="$(cd "$test_root" && python -I -m nose -sv "${existing_targets[@]}" 2>&1)" || test_rc=$?
        printf '%s\n' "$test_output"

        if [[ "${test_rc:-0}" -ne 0 ]]; then
            log_error "Optional regression test command failed in $test_root with exit code $test_rc"
            test_status=$test_rc
            false; return
        fi

        if grep -q "Ran 0 tests" <<< "$test_output"; then
            log_error "Optional regression test command collected zero tests in $test_root"
            test_status=1
        fi
    }

    run_optional_regression_tests "$CLAW/classic/tests" \
        "acoustics_1d_heterogeneous/regression_test.py"
    run_optional_regression_tests "$CLAW/amrclaw/tests" \
        "acoustics_1d_homogeneous/regression_tests.py"
    run_required_regression_tests "$CLAW/geoclaw/tests" \
        "bowl_slosh/regression_tests.py" \
        "test_topotools.py" \
        "test_units.py"

    [ "$test_status" -eq 0 ]
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
