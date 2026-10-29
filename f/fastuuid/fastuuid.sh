#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : fastuuid
# Version       : 0.14.0
# Source repo   : https://github.com/fastuuid/fastuuid
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2.0 or later
# Maintainer    : Ryder Salinas <rbsalinas@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="fastuuid"
PACKAGE_VERSION="${1:-0.14.0}"
PACKAGE_URL="https://github.com/fastuuid/fastuuid"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git python3-devel"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

PROVIDES_ARTIFACT="fastuuid"

# =============================================================================
# CALLBACK: post_clone — Initialize git submodules and apply patch after clone
# =============================================================================
post_clone() {
    log_info "Applying patch to fix deprecated uuid::Context"
    local patch_file="${SCRIPT_DIR}/patches/fastuuid_${PACKAGE_VERSION}.patch"
    if [[ ! -f "${patch_file}" ]]; then
        log_error "Patch file not found: ${patch_file}"
        return 1
    fi
    git apply "${patch_file}"
}

# =============================================================================
# CALLBACK: pre_build — Install Rust build dependencies (maturin for Rust extension)
# =============================================================================
pre_build() {
    log_info "Installing maturin for Rust extension build"
    python -m pip install --upgrade maturin
}


# =============================================================================
# CALLBACK: post_build — Package the built wheel into the artifact directory
# =============================================================================
post_build() {
    log_info "Packaging fastuuid wheel into artifact directory..."

    local ARTIFACT_DIR
    ARTIFACT_DIR="$(artifact_dir "${PACKAGE_NAME}" "${PACKAGE_VERSION}")"

    local wheel_file
    wheel_file=$(ls "${OUTPUT_DIR:-/output}"/fastuuid-*.whl 2>/dev/null | head -1)
    if [[ -z "${wheel_file}" ]]; then
        wheel_file=$(ls wheelhouse/fastuuid-*.whl 2>/dev/null | head -1)
    fi
    if [[ -z "${wheel_file}" ]]; then
        wheel_file=$(ls dist/fastuuid-*.whl 2>/dev/null | head -1)
    fi

    if [[ -n "${wheel_file}" ]]; then
        log_info "Copying fastuuid wheel to artifact: ${ARTIFACT_DIR}/wheels/"
        mkdir -p "${ARTIFACT_DIR}/wheels"
        cp "${wheel_file}" "${ARTIFACT_DIR}/wheels/"
        log_info "fastuuid artifact wheel saved: $(basename "${wheel_file}")"
    else
        log_warn "No fastuuid wheel found to copy into artifact — skipping wheels/ dir"
    fi
}

# =============================================================================
# CALLBACK: custom_test_command — Run custom smoke tests to verify package functionality
# =============================================================================
custom_test_command() {
    log_info "Running custom smoke tests"

    log_info "Test 1: Import and version"
    python -c "
import ${PACKAGE_NAME}
from importlib.metadata import version
print('Import successful:', ${PACKAGE_NAME}.__file__)
print('Version:', version('${PACKAGE_NAME}'))
print('Import and version: OK')
"

    log_info "Test 2: Generate UUID4"
    python -c "
import fastuuid
u = fastuuid.uuid4()
assert isinstance(u, fastuuid.UUID), 'uuid4() did not return a UUID'
assert u.version == 4, f'Expected version 4, got {u.version}'
print('uuid4():', u)
print('UUID4: OK')
"

    log_info "Test 3: Generate UUID1"
    python -c "
import fastuuid
u = fastuuid.uuid1()
assert isinstance(u, fastuuid.UUID), 'uuid1() did not return a UUID'
assert u.version == 1, f'Expected version 1, got {u.version}'
print('uuid1():', u)
print('UUID1: OK')
"

    log_info "Test 4: UUID uniqueness"
    python -c "
import fastuuid
uuids = {str(fastuuid.uuid4()) for _ in range(1000)}
assert len(uuids) == 1000, f'Collision detected: only {len(uuids)} unique UUIDs from 1000'
print('1000 unique UUID4s generated')
print('Uniqueness: OK')
"

    log_info "Test 5: UUID string format"
    python -c "
import fastuuid, re
u = fastuuid.uuid4()
s = str(u)
pattern = r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'
assert re.match(pattern, s), f'UUID string format invalid: {s}'
print('UUID string:', s)
print('String format: OK')
"

    log_info "Test 6: UUID from string roundtrip"
    python -c "
import fastuuid
original = fastuuid.uuid4()
parsed = fastuuid.UUID(str(original))
assert original == parsed, f'Roundtrip mismatch: {original} != {parsed}'
print('Roundtrip:', original, '->', parsed)
print('String roundtrip: OK')
"

    log_info "Test 7: UUID bytes roundtrip"
    python -c "
import fastuuid
original = fastuuid.uuid4()
parsed = fastuuid.UUID(bytes=original.bytes)
assert original == parsed, f'Bytes roundtrip mismatch: {original} != {parsed}'
assert len(original.bytes) == 16, f'Expected 16 bytes, got {len(original.bytes)}'
print('Bytes roundtrip:', original)
print('Bytes roundtrip: OK')
"

    log_info "Test 8: UUID int roundtrip"
    python -c "
import fastuuid
original = fastuuid.uuid4()
parsed = fastuuid.UUID(int=original.int)
assert original == parsed, f'Int roundtrip mismatch: {original} != {parsed}'
print('Int roundtrip:', original.int)
print('Int roundtrip: OK')
"

    log_info "Test 9: UUID fields"
    python -c "
import fastuuid
u = fastuuid.uuid4()
assert hasattr(u, 'time_low'), 'Missing field: time_low'
assert hasattr(u, 'time_mid'), 'Missing field: time_mid'
assert hasattr(u, 'time_hi_version'), 'Missing field: time_hi_version'
assert hasattr(u, 'clock_seq_hi_variant'), 'Missing field: clock_seq_hi_variant'
assert hasattr(u, 'clock_seq_low'), 'Missing field: clock_seq_low'
assert hasattr(u, 'node'), 'Missing field: node'
print('Fields:', u.fields)
print('UUID fields: OK')
"

    log_info "Test 10: Comparison and hashing"
    python -c "
import fastuuid
a = fastuuid.uuid4()
b = fastuuid.uuid4()
same = fastuuid.UUID(str(a))
assert a == same, 'Equality failed for same UUID'
assert a != b, 'Two random UUIDs should not be equal'
assert hash(a) == hash(same), 'Hash mismatch for equal UUIDs'
s = {a, b, same}
assert len(s) == 2, f'Set deduplication failed: expected 2 elements, got {len(s)}'
print('Comparison and hashing: OK')
"

    log_info "All smoke tests passed successfully"
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
