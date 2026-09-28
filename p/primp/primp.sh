#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : primp
# Version       : v0.15.0
# Source repo   : https://github.com/deedy5/primp
# Tested on     : UBI:9.6
# Language      : Python/Rust
# Script License: Apache License, Version 2.0 or later
# Maintainer    : Sanket-Kumbhar <Sanket.Kumbhar@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME=primp
PACKAGE_VERSION=${1:-v0.15.0}
PACKAGE_URL=https://github.com/deedy5/primp

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git python3-devel gcc gcc-c++ gzip tar make wget xz cmake yum-utils openssl-devel openblas-devel bzip2-devel bzip2 zip unzip libffi-devel zlib-devel autoconf automake libtool cargo pkgconf-pkg-config info fontconfig fontconfig-devel sqlite-devel"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: pre_build — Patch BoringSSL base.h for ppc64le (if present)
# =============================================================================
# boring-sys / boring-sys2 bundles BoringSSL source under deps/boringssl/.
# Before the cargo build runs, get_boringssl_source_path() copies that tree to
# out/boringssl/ and ensure_patches_applied() runs git-apply on the result.
# Versions of boring-sys2 older than ~4.15.11 do not have a ppc64le entry in
# base.h, so the compiler hits:
#
#   base.h:124: #error "Unknown target CPU"
#
# The fix: add the ppc64le #elif directly into the bundled
# deps/boringssl/src/include/openssl/base.h in the cargo registry before
# cargo starts.  The insertion point is just after the __myriad2__ block
# (the last named arch before the #else fallback).  If the file is already
# patched (boring-sys2 >=4.15.11 ships it fixed) the grep guard skips the
# sed entirely — no false failure.
# =============================================================================
pre_build() {
    log_info "Installing maturin..."
    python -m pip install "maturin>=1.5,<2.0"

    log_info "Fetching cargo dependencies..."
    cargo fetch

    # Query cargo metadata for boring-sys or boring-sys2 crate location
    local BORING_MANIFEST
    BORING_MANIFEST=$(cargo metadata --format-version=1 2>/dev/null \
        | jq -r '.packages[] | select(.name=="boring-sys" or .name=="boring-sys2") | .manifest_path' 2>/dev/null | head -n 1 || true)

    if [[ -n "${BORING_MANIFEST}" && -f "${BORING_MANIFEST}" ]]; then
        local BORING_DIR
        BORING_DIR=$(dirname "${BORING_MANIFEST}")
        local BASE_H="${BORING_DIR}/deps/boringssl/src/include/openssl/base.h"

        if [[ -f "${BASE_H}" ]]; then
            if grep -q "__powerpc64__" "${BASE_H}"; then
                log_info "base.h already contains ppc64le support — skipping patch."
            else
                log_info "Patching base.h for ppc64le in ${BASE_H}..."
                sed -i \
                    '/^#elif defined(__myriad2__)/,/^#define OPENSSL_32_BIT/{
                        /^#define OPENSSL_32_BIT/a\
\
#elif defined(__powerpc64__) && defined(__LITTLE_ENDIAN__)\
#define OPENSSL_64_BIT\
#define OPENSSL_PPC64LE
                    }' \
                    "${BASE_H}"

                if grep -q "__powerpc64__" "${BASE_H}"; then
                    log_info "Successfully patched ${BASE_H}"
                else
                    log_error "Failed to patch ${BASE_H}"
                    exit 1
                fi
            fi
        else
            log_info "boring-sys found, but ${BASE_H} does not exist — skipping patch."
        fi
    else
        log_info "No boring-sys or boring-sys2 dependency detected in cargo metadata — skipping patch."
    fi
}

# =============================================================================
# CALLBACK: pre_test — Install test dependencies
# =============================================================================
pre_test() {
    log_info "Installing test dependencies..."
    python -m pip install certifi pytest-asyncio
}

# =============================================================================
# CALLBACK: custom_test_command — Skip tests requiring live external services
# =============================================================================
# v0.8.1 SPECIFIC NOTE:
#   test_response.py does not exist in v0.8.1. Every test in test_client.py
#   and test_defs.py calls either https://httpbin.org/anything (returns 503)
#   or https://tls.peet.ws (hash drift). There is nothing to run, so all
#   tests are skipped for this version.
#
# v0.14.0 / v0.15.0:
#   test_response.py exists and hits https://nytimes.com .
#   The three httpbin.org files are ignored; only test_response.py is run.
# =============================================================================
custom_test_command() {
    # v0.8.1: test_response.py does not exist — skip everything.
    if [ ! -f tests/test_response.py ]; then
        log_info "No offline-capable tests found for ${PACKAGE_VERSION} — skipping test suite."
        log_info "All tests in this version call https://httpbin.org/anything "
        log_info "or https://tls.peet.ws (server-side hash values that drift across environments)."
        return 0
    fi

    # v0.14.0 / v0.15.0: ignore the three httpbin.org test files and run
    # only test_response.py which hits https://nytimes.com 
    log_info "Running test_response.py..."
    python -I -m pytest --import-mode=importlib \
        --ignore=tests/test_client.py \
        --ignore=tests/test_asyncclient.py \
        --ignore=tests/test_defs.py \
        tests/test_response.py
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
