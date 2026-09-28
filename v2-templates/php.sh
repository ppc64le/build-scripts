#!/bin/bash
# =============================================================================
# php.sh - Invocable PHP Build Template
# =============================================================================
# This template is SOURCED by user build scripts, not executed directly.
# It provides the standard PHP build workflow with callback hooks for
# customization. Uses Composer for dependency management.
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
#   PHP_VERSION     - PHP version (default: 8.2, informational only)
#   CLONE_DIR       - Directory name for clone (default: PACKAGE_NAME)
#   SKIP_TESTS      - Set to "true" to skip test phase
#   NOARCH          - Set to "true" to install from Packagist instead of building
#   PACKAGIST_NAME  - Packagist package name if different (e.g., "vendor/package")
#
# CALLBACK HOOKS (define as functions before sourcing):
#   pre_packages()         - Before package install (add extra repos)
#   pre_clone()            - Before git clone (extra deps, environment)
#   post_clone()           - After checkout (apply patches, modify source)
#   pre_build()            - Before composer install (environment setup)
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
    echo "Usage: source \"\${SCRIPT_DIR}/../templates/php.sh\""
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
: ${PHP_VERSION:="8.2"}
: ${CLONE_DIR:="$PACKAGE_NAME"}
: ${SKIP_TESTS:="false"}
: ${NOARCH:="false"}
: ${PACKAGIST_NAME:="$PACKAGE_NAME"}
: ${PHPUNIT_OPTS:=""}

# =============================================================================
# HELPER: Check if callback function exists
# =============================================================================
_has_callback() {
    type -t "$1" 2>/dev/null | grep -q "function"
}

# =============================================================================
# COMPOSER SETUP HELPER
# =============================================================================
_install_composer() {
    if check_command composer; then
        log_info "Composer already installed: $(composer --version)"
        return 0
    fi

    log_info "Installing Composer"
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    php composer-setup.php --install-dir=/usr/local/bin --filename=composer 2>/dev/null || \
        php composer-setup.php --install-dir="$HOME/.local/bin" --filename=composer
    rm composer-setup.php
    export PATH="$HOME/.local/bin:$PATH"
    log_info "Composer version: $(composer --version)"
}

_run_default_tests() {
    # Try running PHPUnit
    if [[ -f "vendor/bin/phpunit" ]]; then
        ./vendor/bin/phpunit ${PHPUNIT_OPTS} && return 0 || return 1
    fi

    # PHPUnit config exists but binary missing, install it
    if [[ -f "phpunit.xml" ]] || [[ -f "phpunit.xml.dist" ]]; then
        composer require --dev phpunit/phpunit --with-all-dependencies 2>/dev/null || true
        if [[ -f "vendor/bin/phpunit" ]]; then
            ./vendor/bin/phpunit ${PHPUNIT_OPTS} && return 0 || return 1
        fi
    fi

    # Try composer test script
    if composer run-script test 2>/dev/null; then
        return 0
    fi

    # No tests found
    return 2
}

# =============================================================================
# INITIALIZATION
# =============================================================================
detect_os

log_info "======================================================================"
log_info "Building $PACKAGE_NAME version $PACKAGE_VERSION"
log_info "PHP version: $PHP_VERSION"
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

log_info "PHP version: $(php --version | head -1)"

_install_composer

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
    # NOARCH: Install from Packagist instead of building from source
    local packagist_version="${PACKAGE_VERSION#v}"
    log_info "NOARCH mode: Installing ${PACKAGIST_NAME}:${packagist_version} from Packagist"
    if ! composer require "${PACKAGIST_NAME}:${packagist_version}" --no-interaction; then
        report_install_fail
    fi
else
    log_info "Installing package dependencies"

    if ! composer install --no-interaction; then
        log_info "Trying composer update before install"
        composer update --no-interaction || true
        if ! composer install --no-interaction; then
            report_install_fail
        fi
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

# Check if tests exist
if [[ ! -d "tests" ]] && [[ ! -d "test" ]] && ! find . -name "*Test.php" -type f 2>/dev/null | head -1 | grep -q .; then
    log_info "No tests found"
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

if [[ -n "${PHPUNIT_OPTS}" ]]; then
    log_info "Running tests with options: ${PHPUNIT_OPTS}"
else
    log_info "Running tests"
fi

test_status=0

if _has_callback custom_test_command; then
    log_info "Running custom_test_command hook..."
    custom_test_command && test_status=0 || test_status=$?
else
    _run_default_tests && test_status=0 || test_status=$?
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
case $test_status in
    0)
        report_success
        ;;
    2)
        log_info "No test runner found"
        # Container build before exit (report_no_tests exits the script)
        if _should_build_container "${SCRIPT_DIR}"; then
            build_container "${PACKAGE_VERSION}" "${SCRIPT_DIR}/Dockerfile"
        fi
        report_no_tests
        ;;
    *)
        report_test_fail
        ;;
esac
