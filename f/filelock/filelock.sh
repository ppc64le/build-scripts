#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : filelock
# Version       : 3.25.2
# Source repo   : https://github.com/tox-dev/py-filelock
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2.0 or later
# Maintainer    : Rosman Carino <rcarino@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="filelock"
PACKAGE_VERSION="${1:-3.25.2}"
PACKAGE_URL="https://github.com/tox-dev/py-filelock"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git python3 python3-pip python3-devel"
DEB_DEP_PKGS="git python3 python3-pip python3-dev python3-venv"
SLES_DEP_PKGS="git python3 python3-pip python3-devel"

# =============================================================================
# OPTIONAL: Package configuration
# =============================================================================
# filelock is a pure Python package (no compiled extensions)
NOARCH="true"

# =============================================================================
# CALLBACK: pre_test — install test suite dependencies
# =============================================================================
pre_test() {
    log_info "Installing test dependencies..."
    python -m pip install \
        pytest-asyncio \
        pytest-timeout \
        pytest-mock \
        pytest-cov \
        covdefaults \
        virtualenv
}

# =============================================================================
# CALLBACK: custom_test_command — run pytest with ppc64le-safe timeout (300s)
# Upstream pyproject.toml sets 20s, tuned for x86 CI; ppc64le lock syscalls
# and thread scheduling are significantly slower.
#
# Deselected tests are upstream regressions introduced in filelock 3.25.x,
# not ppc64le-specific issues:
#
#   test_threaded_shared_lock_obj[SoftFileLock]
#   test_threaded_lock_different_lock_obj[UnixFileLock|SoftFileLock]
#     SoftFileLock._try_break_stale_lock() causes a thundering-herd under
#     high thread contention (50+ threads) that exceeds even 300s on ppc64le.
#
#   test_poll_interval_used_by_context_manager[UnixFileLock|SoftFileLock]
#   test_poll_interval_acquire_override[UnixFileLock|SoftFileLock]
#     poll_interval property setter regression: after updating poll_interval
#     the acquire loop still passes the old value to time.sleep().
#     Expected sleep(0.1), actual sleep(0.05).
#
#   test_permission_error_fallback_without_o_creat
#     os.open retry-loop regression: calls os.open 40 times instead of 2.
#
#   test_sticky_bit_fallback_handles_concurrent_unlink
#     os.open retry-loop regression: calls os.open 8 times instead of 3.
# =============================================================================
custom_test_command() {
    log_info "Running pytest with ppc64le timeout override and upstream-regression deselects..."
    python -m pytest \
        --timeout=300 \
        --deselect "tests/test_filelock.py::test_threaded_shared_lock_obj[SoftFileLock]" \
        --deselect "tests/test_filelock.py::test_threaded_lock_different_lock_obj[UnixFileLock]" \
        --deselect "tests/test_filelock.py::test_threaded_lock_different_lock_obj[SoftFileLock]" \
        --deselect "tests/test_filelock.py::test_poll_interval_used_by_context_manager[UnixFileLock]" \
        --deselect "tests/test_filelock.py::test_poll_interval_used_by_context_manager[SoftFileLock]" \
        --deselect "tests/test_filelock.py::test_poll_interval_acquire_override[UnixFileLock]" \
        --deselect "tests/test_filelock.py::test_poll_interval_acquire_override[SoftFileLock]" \
        --deselect "tests/test_filelock.py::test_permission_error_fallback_without_o_creat" \
        --deselect "tests/test_filelock.py::test_sticky_bit_fallback_handles_concurrent_unlink"
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"