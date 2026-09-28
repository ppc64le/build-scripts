#!/bin/bash
# =============================================================================
# node.sh - Invocable Node.js Build Template
# =============================================================================
# This template is SOURCED by user build scripts, not executed directly.
# It provides the standard Node.js build workflow with callback hooks for
# customization.
#
# REQUIRED variables (must be set before sourcing):
#   PACKAGE_NAME    - Name of the package
#   PACKAGE_VERSION - Version to build (usually from $1)
#   PACKAGE_URL     - Git repository URL
#   RH_DEP_PKGS     - Red Hat/Fedora dependencies
#   DEB_DEP_PKGS    - Debian/Ubuntu dependencies (optional)
#   SLES_DEP_PKGS   - SUSE dependencies (optional)
#
# OPTIONAL variables:
#   NODE_VERSION    - Node.js version via nvm (default: 20)
#   NVM_VERSION     - NVM version to install (default: v0.40.1)
#   CLONE_DIR       - Directory name for clone (default: PACKAGE_NAME)
#   SKIP_TESTS      - Set to "true" to skip test phase
#   NOARCH          - Set to "true" to install from npm registry instead of building
#   NPM_NAME        - npm package name if different from PACKAGE_NAME
#
# CALLBACK HOOKS (define as functions before sourcing):
#   pre_packages()         - Before package install (add extra repos)
#   pre_clone()            - Before git clone (extra deps, environment)
#   post_clone()           - After checkout (apply patches, modify source)
#   pre_build()            - Before npm install (environment setup)
#   post_build()           - After install, before test (verification)
#   custom_test_command()  - Override default test logic
#   post_test()            - After tests pass (cleanup, artifacts)
#   custom_install()       - Override entire install logic
#
# EXIT CODES:
#   0 - Success (build and test passed, or build passed with no tests)
#   1 - Clone or install failure
#   2 - Test failure (install succeeded)
# =============================================================================

# Ensure we're being sourced, not executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "ERROR: This script must be sourced, not executed directly."
    echo "Usage: source \"\${SCRIPT_DIR}/../templates/node.sh\""
    exit 1
fi

# =============================================================================
# SOURCE COMMON LIBRARIES
# =============================================================================
if [[ -z "${SCRIPT_DIR}" ]]; then
    echo "ERROR: SCRIPT_DIR must be set before sourcing this template"
    exit 1
fi

TEMPLATE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${TEMPLATE_DIR}/lib/common.sh"
source "${TEMPLATE_DIR}/lib/distro-packages.sh"
source "${TEMPLATE_DIR}/lib/automation-stanzas.sh"
source "${TEMPLATE_DIR}/lib/prereq-checks.sh"
source "${TEMPLATE_DIR}/lib/container.sh"

# =============================================================================
# VALIDATE REQUIRED VARIABLES
# =============================================================================
validate_required_vars PACKAGE_NAME PACKAGE_VERSION PACKAGE_URL

# Set defaults for optional variables
: ${NODE_VERSION:="20"}
: ${NVM_VERSION:="v0.40.1"}
: ${CLONE_DIR:="$PACKAGE_NAME"}
: ${SKIP_TESTS:="false"}
: ${NOARCH:="false"}
: ${NPM_NAME:="$PACKAGE_NAME"}
: ${NPM_TEST_OPTS:=""}

# =============================================================================
# HELPER: Check if callback function exists
# =============================================================================
_has_callback() {
    type -t "$1" 2>/dev/null | grep -q "function"
}

# =============================================================================
# INITIALIZATION
# =============================================================================
detect_os

log_info "======================================================================"
log_info "Building $PACKAGE_NAME version $PACKAGE_VERSION"
log_info "Node.js: $NODE_VERSION"
log_info "OS: $OS_NAME"
[[ "$NOARCH" == "true" ]] && log_info "Mode: NOARCH (install from npm registry)"
log_info "======================================================================"

# =============================================================================
# CALLBACK: pre_packages (add extra repos before package install)
# =============================================================================
if _has_callback pre_packages; then
    log_info "Running pre_packages hook..."
    pre_packages
fi

# =============================================================================
# INSTALL DEPENDENCIES
# =============================================================================
install_packages

# =============================================================================
# CALLBACK: pre_clone
# =============================================================================
if _has_callback pre_clone; then
    log_info "Running pre_clone hook..."
    pre_clone
fi

# =============================================================================
# INSTALL NVM AND NODE.JS
# =============================================================================
log_info "Setting up Node.js $NODE_VERSION via nvm"

if [[ ! -d "$HOME/.nvm" ]]; then
    log_info "Installing nvm $NVM_VERSION"
    curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | bash
fi

export NVM_DIR="$HOME/.nvm"
# shellcheck source=/dev/null
[[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"

log_info "Installing Node.js $NODE_VERSION"
nvm install "$NODE_VERSION" >/dev/null
nvm use "$NODE_VERSION"

log_info "Node.js version: $(node --version)"
log_info "npm version: $(npm --version)"

# =============================================================================
# CLONE REPOSITORY
# =============================================================================
clone_repository

# =============================================================================
# CALLBACK: post_clone (patches, source modifications)
# =============================================================================
if _has_callback post_clone; then
    log_info "Running post_clone hook..."
    post_clone
fi

# =============================================================================
# CALLBACK: pre_build (environment setup)
# =============================================================================
if _has_callback pre_build; then
    log_info "Running pre_build hook..."
    pre_build
fi

# =============================================================================
# BUILD / INSTALL
# =============================================================================
if _has_callback custom_install; then
    log_info "Running custom_install hook..."
    if ! custom_install; then
        report_install_fail
    fi
elif [[ "$NOARCH" == "true" ]]; then
    # NOARCH: Install from npm registry instead of building from source
    local npm_version="${PACKAGE_VERSION#v}"
    log_info "NOARCH mode: Installing ${NPM_NAME}@${npm_version} from npm registry"
    if ! npm install "${NPM_NAME}@${npm_version}"; then
        report_install_fail
    fi
else
    log_info "Installing package dependencies"
    if ! npm install; then
        report_install_fail
    fi

    # Run npm audit fix if needed (non-fatal)
    npm audit fix --force 2>/dev/null || true
fi

# =============================================================================
# CALLBACK: post_build (verification)
# =============================================================================
if _has_callback post_build; then
    log_info "Running post_build hook..."
    post_build
fi

# =============================================================================
# TEST PHASE
# =============================================================================
if [[ "$SKIP_TESTS" == "true" ]]; then
    log_info "Tests skipped (SKIP_TESTS=true)"
    # Container build before exit (report_no_tests exits the script)
    if _should_build_container "${SCRIPT_DIR}"; then
        build_container "${PACKAGE_VERSION}" "${SCRIPT_DIR}/Dockerfile"
    fi
    report_no_tests
fi

# =============================================================================
# CALLBACK: pre_test (install test deps or setup environment)
# =============================================================================
if _has_callback pre_test; then
    log_info "Running pre_test hook..."
    if ! pre_test; then
        log_error "pre_test hook failed"
        report_test_fail
    fi
fi

if [[ -n "${NPM_TEST_OPTS}" ]]; then
    log_info "Running tests with options: ${NPM_TEST_OPTS}"
else
    log_info "Running tests"
fi

test_status=1

if _has_callback custom_test_command; then
    log_info "Running custom_test_command hook..."
    custom_test_command && test_status=0 || test_status=$?
else
    # Standard npm test (NPM_TEST_OPTS passed via -- separator)
    if [[ -n "${NPM_TEST_OPTS}" ]]; then
        npm run test --if-present -- ${NPM_TEST_OPTS} 2>/dev/null && test_status=0
    else
        npm run test --if-present 2>/dev/null && test_status=0
    fi
fi

# =============================================================================
# CALLBACK: post_test
# =============================================================================
if _has_callback post_test; then
    log_info "Running post_test hook..."
    post_test
fi

# =============================================================================
# CONTAINER BUILD (optional)
# =============================================================================
if [[ $test_status -eq 0 ]] && _should_build_container "${SCRIPT_DIR}"; then
    build_container "${PACKAGE_VERSION}" "${SCRIPT_DIR}/Dockerfile"
fi

# =============================================================================
# REPORT RESULTS
# =============================================================================
if [[ $test_status -eq 0 ]]; then
    report_success
else
    # Check if there's actually a test script defined
    if grep -q '"test"' package.json 2>/dev/null; then
        report_test_fail
    else
        log_info "No test script found in package.json"
        # Container build before exit (report_no_tests exits the script)
        if _should_build_container "${SCRIPT_DIR}"; then
            build_container "${PACKAGE_VERSION}" "${SCRIPT_DIR}/Dockerfile"
        fi
        report_no_tests
    fi
fi
