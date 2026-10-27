#!/bin/bash
# =============================================================================
# r.sh - Invocable R Build Template
# =============================================================================
# This template is SOURCED by user build scripts, not executed directly.
# It provides the standard R package build workflow with callback hooks for
# customization. Uses R CMD build/install/check.
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
#   CLONE_DIR       - Directory name for clone (default: PACKAGE_NAME)
#   SKIP_TESTS      - Set to "true" to skip test phase
#   SKIP_VIGNETTES  - Set to "true" to skip vignette building (default: true)
#   CRAN_DEPS       - Set to "true" to install CRAN dependencies first
#   NOARCH          - Set to "true" to install from CRAN instead of building
#   CRAN_NAME       - CRAN package name if different from PACKAGE_NAME
#
# CALLBACK HOOKS (define as functions before sourcing):
#   pre_packages()         - Before package install (add extra repos)
#   pre_clone()            - Before git clone (extra deps, environment)
#   post_clone()           - After checkout (apply patches, modify source)
#   pre_build()            - Before R CMD build (environment setup)
#   post_build()           - After build, before test (verification)
#   custom_test_command()  - Override default test logic
#   post_test()            - After tests pass (cleanup, artifacts)
#   custom_build()         - Override entire build logic
#
# EXIT CODES:
#   0 - Success (build and test passed, or build passed with no tests)
#   1 - Clone or build failure
#   2 - Test failure (build succeeded)
# =============================================================================

# Ensure we're being sourced, not executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "ERROR: This script must be sourced, not executed directly."
    echo "Usage: source \"\${SCRIPT_DIR}/../templates/r.sh\""
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
: ${CLONE_DIR:="$PACKAGE_NAME"}
: ${SKIP_TESTS:="false"}
: ${SKIP_VIGNETTES:="true"}
: ${CRAN_DEPS:="true"}
: ${NOARCH:="false"}
: ${CRAN_NAME:="$PACKAGE_NAME"}
: ${R_CHECK_OPTS:=""}

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
log_info "OS: $OS_NAME"
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

log_info "R version: $(R --version | head -1)"

# =============================================================================
# CALLBACK: pre_clone
# =============================================================================
if _has_callback pre_clone; then
    log_info "Running pre_clone hook..."
    pre_clone
fi

# =============================================================================
# CLONE REPOSITORY
# =============================================================================
clone_repository
cd ..  # R builds from parent directory

# =============================================================================
# CALLBACK: post_clone (patches, source modifications)
# =============================================================================
if _has_callback post_clone; then
    log_info "Running post_clone hook..."
    cd "$CLONE_DIR"
    post_clone
    cd ..
fi

# =============================================================================
# INSTALL CRAN DEPENDENCIES
# =============================================================================
if [[ "$CRAN_DEPS" == "true" ]]; then
    log_info "Installing R package dependencies from CRAN"
    R -e "install.packages('$PACKAGE_NAME', dependencies = TRUE, repos = 'https://cloud.r-project.org/')" 2>/dev/null || \
        log_warn "CRAN dependency installation failed, continuing with local install"
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
if _has_callback custom_build; then
    log_info "Running custom_build hook..."
    if ! custom_build; then
        report_build_fail
    fi
elif [[ "$NOARCH" == "true" ]]; then
    # NOARCH: Install from CRAN instead of building from source
    local cran_version="${PACKAGE_VERSION#v}"
    log_info "NOARCH mode: Installing ${CRAN_NAME} from CRAN"
    # Note: CRAN doesn't support version pinning easily, install latest
    if ! Rscript -e "install.packages('${CRAN_NAME}', repos='https://cloud.r-project.org/')"; then
        report_install_fail
    fi
else
    log_info "Building R package"

    BUILD_OPTS=""
    [[ "$SKIP_VIGNETTES" == "true" ]] && BUILD_OPTS="--no-build-vignettes"

    if ! R CMD build "$CLONE_DIR" $BUILD_OPTS; then
        report_build_fail
    fi

    log_info "Installing R package"

    if ! R CMD INSTALL "$CLONE_DIR"; then
        report_install_fail
    fi
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

if [[ -n "${R_CHECK_OPTS}" ]]; then
    log_info "Running R package checks with options: ${R_CHECK_OPTS}"
else
    log_info "Running R package checks"
fi

test_status=0

if _has_callback custom_test_command; then
    log_info "Running custom_test_command hook..."
    custom_test_command && test_status=0 || test_status=$?
else
    CHECK_OPTS="--no-manual"
    [[ "$SKIP_VIGNETTES" == "true" ]] && CHECK_OPTS="$CHECK_OPTS --no-build-vignettes --ignore-vignettes"
    [[ -n "$R_CHECK_OPTS" ]] && CHECK_OPTS="$CHECK_OPTS $R_CHECK_OPTS"

    R CMD check "$CLONE_DIR" $CHECK_OPTS && test_status=0 || test_status=$?
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
    report_test_fail
fi
