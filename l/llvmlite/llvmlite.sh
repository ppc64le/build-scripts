#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : llvmlite
# Version       : v0.47.0
# Source repo   : https://github.com/numba/llvmlite
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : IBM
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="llvmlite"
PACKAGE_VERSION="${1:-v0.47.0}"
PACKAGE_URL="https://github.com/numba/llvmlite"

PROVIDES_ARTIFACT="llvmlite"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git python3 python3-devel python3-pip cmake make zlib-devel libffi-devel"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# Build Configuration
# =============================================================================
LICENSE_SPDX="BSD-2-Clause"
# llvmlite uses only setup.py (no pyproject.toml across all supported versions).
# setuptools>=74 removed the re-bundled distutils that Python 3.12+ depends on.
# Pin to >=60,<74 which re-bundles distutils and is compatible with Python 3.9–3.14.
SETUPTOOLS_VERSION=">=60,<74"

# =============================================================================
# CALLBACK: pre_build — validate LLVM dependency and export LLVM_CONFIG
# =============================================================================
pre_build() {
    log_info "Validating LLVM dependency version"
    # Determine required LLVM major version for the requested llvmlite version.
    # These ranges mirror the version checks in each llvmlite release's ffi/build.py.
    local pkg_ver="${PACKAGE_VERSION#v}"   # strip leading 'v'
    local pkg_major pkg_minor
    pkg_major="$(echo "${pkg_ver}" | cut -d. -f1)"
    pkg_minor="$(echo "${pkg_ver}" | cut -d. -f2)"

    local required_llvm_major
    # v0.45.0+ uses CMake and targets LLVM 20; v0.44.x requires LLVM 15;
    # v0.43.x and earlier require LLVM 14 (11–14 accepted).
    if [[ "${pkg_major}" -gt 0 ]] || [[ "${pkg_major}" -eq 0 && "${pkg_minor}" -ge 45 ]]; then
        required_llvm_major=20
    elif [[ "${pkg_major}" -eq 0 && "${pkg_minor}" -eq 44 ]]; then
        required_llvm_major=15
    else
        required_llvm_major=14
    fi

    # Locate llvm-config: prefer LLVM_CONFIG if already set, then LLVM_PREFIX/bin,
    # then versioned binary inside LLVM_PREFIX/bin.
    # Never fall back to a system llvm-config — it may be the wrong version.
    if [[ -z "${LLVM_CONFIG:-}" ]]; then
        if [[ -n "${LLVM_PREFIX:-}" && -x "${LLVM_PREFIX}/bin/llvm-config" ]]; then
            export LLVM_CONFIG="${LLVM_PREFIX}/bin/llvm-config"
        elif [[ -n "${LLVM_PREFIX:-}" ]]; then
            # Some LLVM builds install a versioned binary (e.g. llvm-config-14)
            local versioned
            versioned="$(ls "${LLVM_PREFIX}/bin/llvm-config-"* 2>/dev/null | sort -V | tail -1)"
            if [[ -n "${versioned}" && -x "${versioned}" ]]; then
                export LLVM_CONFIG="${versioned}"
            else
                log_error "llvm-config not found in LLVM_PREFIX=${LLVM_PREFIX}/bin"
                    log_error "Ensure the llvm artifact for LLVM ${required_llvm_major} was built correctly"
                    false
            fi
        else
            log_error "Neither LLVM_CONFIG nor LLVM_PREFIX is set"
            log_error "llvmlite ${PACKAGE_VERSION} requires LLVM ${required_llvm_major}; source the correct llvm artifact first"
            false
        fi
    fi

    if [[ ! -x "${LLVM_CONFIG}" ]]; then
        log_error "LLVM_CONFIG points to a non-executable path: ${LLVM_CONFIG}"
        false
    fi

    # Validate that the found LLVM matches what this llvmlite version requires.
    local found_llvm_ver found_llvm_major
    found_llvm_ver="$("${LLVM_CONFIG}" --version 2>/dev/null)"
    if [[ -z "${found_llvm_ver}" ]]; then
        log_error "Failed to run ${LLVM_CONFIG} --version"
        false
    fi
    found_llvm_major="$(echo "${found_llvm_ver}" | cut -d. -f1)"

    log_info "Using LLVM_CONFIG: ${LLVM_CONFIG}"
    log_info "LLVM version: ${found_llvm_ver} (major=${found_llvm_major}, required=${required_llvm_major})"

    if [[ "${found_llvm_major}" != "${required_llvm_major}" ]]; then
        log_error "llvmlite ${PACKAGE_VERSION} requires LLVM ${required_llvm_major}, but found LLVM ${found_llvm_major} (${LLVM_CONFIG})"
        log_error "Set LLVM_CONFIG to the correct llvm-config binary or ensure the right llvm artifact is sourced"
        false
    fi
}

# =============================================================================
# CALLBACK: post_build
# Package llvmlite artifact for downstream consumers (e.g. numba)
# =============================================================================
post_build() {
    local ARTIFACT_DIR
    ARTIFACT_DIR="$(artifact_dir "${PROVIDES_ARTIFACT}" "${PACKAGE_VERSION}")"

    local python_version
    python_version="$(python -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')" 2>/dev/null || python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")"

    local wheel_file
    wheel_file="$(ls "${OUTPUT_DIR:-/tmp}/artifacts"/llvmlite-*.whl 2>/dev/null | head -1)"
    if [[ -z "${wheel_file}" ]]; then
        wheel_file="$(ls "${OUTPUT_DIR:-.}"/llvmlite-*.whl 2>/dev/null | head -1)"
    fi
    if [[ -z "${wheel_file}" ]]; then
        wheel_file="$(ls dist/llvmlite-*.whl 2>/dev/null | head -1)"
    fi

    mkdir -p "${ARTIFACT_DIR}"

    if [[ -n "${wheel_file}" ]]; then
        local site_packages="${ARTIFACT_DIR}/lib/python${python_version}/site-packages"
        log_info "Installing wheel into artifact site-packages: ${site_packages}"
        mkdir -p "${site_packages}"
        python -m pip install --target="${site_packages}" --no-deps "${wheel_file}"

        mkdir -p "${ARTIFACT_DIR}/wheels"
        cp "${wheel_file}" "${ARTIFACT_DIR}/wheels/"
    fi

    _cleanup_artifact "${ARTIFACT_DIR}"
    _copy_license "${ARTIFACT_DIR}"

    # Generate env.sh for downstream consumers (relocatable, versioned site-packages)
    cat > "${ARTIFACT_DIR}/env.sh" << 'EOF'
# llvmlite environment
export LLVMLITE_PREFIX="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_llvmlite_python_version="$(python -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')" 2>/dev/null || python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")"
export PYTHONPATH="${LLVMLITE_PREFIX}/lib/python${_llvmlite_python_version}/site-packages:${PYTHONPATH:-}"
unset _llvmlite_python_version
EOF

    generate_artifact_manifest "${ARTIFACT_DIR}" \
        "${PROVIDES_ARTIFACT}" "${PACKAGE_VERSION}" \
        "${PACKAGE_URL}" "${LICENSE_SPDX}" \
        "llvm"

}

# =============================================================================
# CALLBACK: custom_test_command — verify llvmlite import and run test suite
# =============================================================================
custom_test_command() {
    log_info "Verifying llvmlite installation..."
    python -c "import llvmlite; print('llvmlite version:', llvmlite.__version__)"
    log_info "Running llvmlite test suite"

    # Run pytest from /tmp so the source tree (/workspace/llvmlite) is never on
    # sys.path.  Without this, the subprocess-spawning tests (test_initfini,
    # test_set_option, test_no_accidental_warnings) launch a fresh Python that
    # resolves `import llvmlite` to the bare source clone — where libllvmlite.so
    # does not exist — instead of the installed wheel in .venv-test.
    # --pyargs collects tests from the installed package, not the source tree.
    (cd /tmp && python -m pytest \
        --pyargs llvmlite.tests \
        --import-mode=importlib \
        -o "addopts=" \
        --disable-warnings \
        -k "not test_issue")  # test_issue tests require network access unavailable in CI
}

# =============================================================================
# Execute the build
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
