#!/bin/bash
# =============================================================================
# automation-stanzas.sh - Standardized CI/CD output functions
# =============================================================================
# This file provides standardized functions for reporting build/test results
# to the automation framework.
#
# Requires: common.sh sourced first (for output_status, PACKAGE_NAME, etc.)
#
# Usage:
#   source "${SCRIPT_DIR}/lib/common.sh"
#   source "${SCRIPT_DIR}/lib/automation-stanzas.sh"
#
#   # Set package metadata
#   PACKAGE_NAME="mypackage"
#   PACKAGE_VERSION="1.0.0"
#   PACKAGE_URL="https://github.com/org/mypackage"
#
#   # Report results
#   if ! some_command; then
#       report_install_fail
#   fi
#   report_success
#
# Exit Codes:
#   0 - Success (install + test passed, or install passed with no tests)
#   1 - Clone or install failure
#   2 - Test failure (install succeeded)
# =============================================================================

# Prevent multiple sourcing
[[ -n "$_AUTOMATION_STANZAS_SH_SOURCED" ]] && return 0
_AUTOMATION_STANZAS_SH_SOURCED=1

# =============================================================================
# EXIT CODES
# =============================================================================
readonly EXIT_SUCCESS=0
readonly EXIT_CLONE_FAIL=1
readonly EXIT_INSTALL_FAIL=1
readonly EXIT_BUILD_FAIL=1
readonly EXIT_TEST_FAIL=2
readonly EXIT_WHEEL_FAIL=3

# =============================================================================
# CLONE/DOWNLOAD FAILURE REPORTS
# =============================================================================

# report_clone_fail: Report git clone failure and exit
report_clone_fail() {
    output_status "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
    output_status "$PACKAGE_URL $PACKAGE_NAME"
    output_status "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Clone_Fails"
    exit $EXIT_CLONE_FAIL
}

# report_download_fail: Report download failure and exit
report_download_fail() {
    output_status "------------------$PACKAGE_NAME:download_fails---------------------------------------"
    output_status "$PACKAGE_URL $PACKAGE_NAME"
    output_status "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Download_Fails"
    exit $EXIT_CLONE_FAIL
}

# report_untar_fail: Report archive extraction failure and exit
report_untar_fail() {
    output_status "------------------$PACKAGE_NAME:untar_fails---------------------------------------"
    output_status "$PACKAGE_URL $PACKAGE_NAME"
    output_status "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Untar_Fails"
    exit $EXIT_CLONE_FAIL
}

# =============================================================================
# BUILD/INSTALL FAILURE REPORTS
# =============================================================================

# report_install_fail: Report installation failure and exit
report_install_fail() {
    output_status "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    output_status "$PACKAGE_URL $PACKAGE_NAME"
    output_status "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_Fails"
    exit $EXIT_INSTALL_FAIL
}

# report_build_fail: Report build failure and exit
report_build_fail() {
    output_status "------------------$PACKAGE_NAME:build_fails---------------------------------------"
    output_status "$PACKAGE_URL $PACKAGE_NAME"
    output_status "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Build_Fails"
    exit $EXIT_BUILD_FAIL
}

# report_dependency_fail: Report dependency installation failure and exit
report_dependency_fail() {
    output_status "------------------$PACKAGE_NAME:dependency_fails----------------------------------"
    output_status "$PACKAGE_URL $PACKAGE_NAME"
    output_status "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Dependency_Fails"
    exit $EXIT_INSTALL_FAIL
}

# =============================================================================
# TEST FAILURE REPORTS
# =============================================================================

# report_test_fail: Report test failure and exit
report_test_fail() {
    output_status "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    output_status "$PACKAGE_URL $PACKAGE_NAME"
    output_status "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_success_but_test_Fails"
    exit $EXIT_TEST_FAIL
}

# report_build_success_test_fail: Report build success but test failure and exit
report_build_success_test_fail() {
    output_status "------------------$PACKAGE_NAME:build_success_but_test_fails-----------------------"
    output_status "$PACKAGE_URL $PACKAGE_NAME"
    output_status "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Build_success_but_test_Fails"
    exit $EXIT_TEST_FAIL
}

# =============================================================================
# WHEEL BUILD FAILURE REPORTS
# =============================================================================

# report_wheel_fail: Report wheel build failure and exit
report_wheel_fail() {
    output_status "------------------$PACKAGE_NAME:wheel_build_fails----------------------------------"
    output_status "$PACKAGE_URL $PACKAGE_NAME"
    output_status "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Wheel_Build_Fails"
    exit $EXIT_WHEEL_FAIL
}

# report_test_success_wheel_fail: Report test passed but wheel build failed and exit
report_test_success_wheel_fail() {
    output_status "------------------$PACKAGE_NAME:test_success_but_wheel_fails-----------------------"
    output_status "$PACKAGE_URL $PACKAGE_NAME"
    output_status "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Test_success_but_Wheel_Fails"
    exit $EXIT_WHEEL_FAIL
}

report_wheel_build_success_install_fail() {
    output_status "------------------$PACKAGE_NAME:wheel_build_success_but_install_fails-----------------------"
    output_status "$PACKAGE_URL $PACKAGE_NAME"
    output_status "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Test_success_but_Wheel_Fails"
    exit $EXIT_WHEEL_FAIL
}

# =============================================================================
# SUCCESS REPORTS
# =============================================================================

# report_success: Report full success (install + test) and exit
report_success() {
    output_status "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    output_status "$PACKAGE_URL $PACKAGE_NAME"
    output_status "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Pass | Both_Install_and_Test_Success"
    exit $EXIT_SUCCESS
}

# report_build_test_success: Report build and test success and exit
report_build_test_success() {
    output_status "------------------$PACKAGE_NAME:build_and_test_success------------------------------"
    output_status "$PACKAGE_URL $PACKAGE_NAME"
    output_status "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Pass | Build_and_Test_Success"
    exit $EXIT_SUCCESS
}

# report_no_tests: Report success when no tests are available
report_no_tests() {
    output_status "------------------$PACKAGE_NAME:install_success_&_test_NA-------------------------"
    output_status "$PACKAGE_URL $PACKAGE_NAME"
    output_status "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Pass | Install_Success_and_Test_NA"
    exit $EXIT_SUCCESS
}

# report_install_only_success: Report install-only success (when test is skipped intentionally)
report_install_only_success() {
    output_status "------------------$PACKAGE_NAME:install_success-----------------------------------"
    output_status "$PACKAGE_URL $PACKAGE_NAME"
    output_status "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Pass | Install_Success"
    exit $EXIT_SUCCESS
}

# report_success_with_wheel: Report full success including wheel build and exit
report_success_with_wheel() {
    output_status "------------------$PACKAGE_NAME:install_test_wheel_all_success---------------------"
    output_status "$PACKAGE_URL $PACKAGE_NAME"
    output_status "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Pass | Install_Test_and_Wheel_Success"
    exit $EXIT_SUCCESS
}

# report_no_tests_with_wheel: Report success when no tests but wheel built
report_no_tests_with_wheel() {
    output_status "------------------$PACKAGE_NAME:install_wheel_success_test_NA----------------------"
    output_status "$PACKAGE_URL $PACKAGE_NAME"
    output_status "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Pass | Install_Wheel_Success_Test_NA"
    exit $EXIT_SUCCESS
}

# =============================================================================
# CONDITIONAL EXECUTION HELPERS
# =============================================================================

# run_or_fail: Run a command, report install failure if it fails
# Usage: run_or_fail "Installing package" pip install .
run_or_fail() {
    local description="$1"
    shift

    echo "[INFO] $description..."
    if ! "$@"; then
        echo "[ERROR] $description failed"
        report_install_fail
    fi
}

# run_build_or_fail: Run a build command, report build failure if it fails
# Usage: run_build_or_fail "Building package" make
run_build_or_fail() {
    local description="$1"
    shift

    echo "[INFO] $description..."
    if ! "$@"; then
        echo "[ERROR] $description failed"
        report_build_fail
    fi
}

# run_test_or_fail: Run a test command, report test failure if it fails
# Usage: run_test_or_fail "Running tests" pytest
run_test_or_fail() {
    local description="$1"
    shift

    echo "[INFO] $description..."
    if ! "$@"; then
        echo "[ERROR] $description failed"
        report_test_fail
    fi
}
