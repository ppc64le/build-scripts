#!/bin/bash
# =============================================================================
# ruby.sh - Invocable Ruby Build Template
# =============================================================================
# This template is SOURCED by user build scripts, not executed directly.
# It provides the standard Ruby build workflow with callback hooks for
# customization. Uses system Ruby or rbenv if needed.
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
#   RUBY_VERSION    - Ruby version via rbenv (default: 3.2.0)
#   CLONE_DIR       - Directory name for clone (default: PACKAGE_NAME)
#   SKIP_TESTS      - Set to "true" to skip test phase
#   NOARCH          - Set to "true" to install from RubyGems instead of building
#   GEM_NAME        - RubyGems package name if different from PACKAGE_NAME
#
# CALLBACK HOOKS (define as functions before sourcing):
#   pre_packages()         - Before package install (add extra repos)
#   pre_clone()            - Before git clone (extra deps, environment)
#   post_clone()           - After checkout (apply patches, modify source)
#   pre_build()            - Before bundle install (environment setup)
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
    echo "Usage: source \"\${SCRIPT_DIR}/../templates/ruby.sh\""
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
: ${RUBY_VERSION:="3.2.0"}
: ${CLONE_DIR:="$PACKAGE_NAME"}
: ${SKIP_TESTS:="false"}
: ${NOARCH:="false"}
: ${GEM_NAME:="$PACKAGE_NAME"}
: ${RSPEC_OPTS:=""}

# Locale settings
export LC_ALL=C.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8

# =============================================================================
# HELPER: Check if callback function exists
# =============================================================================
_has_callback() {
    type -t "$1" 2>/dev/null | grep -q "function"
}

# =============================================================================
# RUBY SETUP HELPER
# =============================================================================
_setup_ruby() {
    # Check if we already have a suitable Ruby
    if check_command ruby; then
        CURRENT_RUBY=$(ruby --version | awk '{print $2}')
        log_info "Using system Ruby: $CURRENT_RUBY"
        return 0
    fi

    # Install rbenv if Ruby not available
    if [[ ! -d "$HOME/.rbenv" ]]; then
        log_info "Installing rbenv"
        git clone https://github.com/rbenv/rbenv.git "$HOME/.rbenv"
        git clone https://github.com/rbenv/ruby-build.git "$HOME/.rbenv/plugins/ruby-build"
    fi

    export PATH="$HOME/.rbenv/bin:$HOME/.rbenv/shims:$PATH"
    eval "$(rbenv init - bash)"

    if ! rbenv versions | grep -q "$RUBY_VERSION"; then
        log_info "Installing Ruby $RUBY_VERSION via rbenv"
        rbenv install "$RUBY_VERSION"
    fi

    rbenv global "$RUBY_VERSION"
    log_info "Ruby version: $(ruby --version)"
}

_run_default_tests() {
    # Check for CI script
    if [[ -f "script/cibuild" ]]; then
        chmod +x script/cibuild
        script/cibuild && return 0 || return 1
    fi

    # Check for rspec
    if [[ -f ".rspec" ]]; then
        bundle exec rspec ${RSPEC_OPTS} && return 0 || return 1
    fi

    # Check for Rakefile
    if [[ -f "Rakefile" ]]; then
        bundle exec rake test ${RSPEC_OPTS} 2>/dev/null && return 0
        bundle exec rake spec ${RSPEC_OPTS} 2>/dev/null && return 0
        bundle exec rake ${RSPEC_OPTS} && return 0 || return 1
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
log_info "Ruby version: $RUBY_VERSION"
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

# =============================================================================
# CALLBACK: pre_clone
# =============================================================================
if _has_callback pre_clone; then
    log_info "Running pre_clone hook..."
    pre_clone
fi

# =============================================================================
# SETUP RUBY
# =============================================================================
_setup_ruby

log_info "Installing bundler"
gem install bundler --no-document

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
    # NOARCH: Install from RubyGems instead of building from source
    local gem_version="${PACKAGE_VERSION#v}"
    log_info "NOARCH mode: Installing ${GEM_NAME} ${gem_version} from RubyGems"
    if ! gem install "${GEM_NAME}" -v "${gem_version}"; then
        report_install_fail
    fi
else
    log_info "Installing package dependencies"

    bundle config set --local path 'vendor/bundle'
    bundle config set --local disable_checksum_validation true

    if ! bundle install; then
        report_install_fail
    fi

    bundle config set --local disable_checksum_validation false
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

if [[ -n "${RSPEC_OPTS}" ]]; then
    log_info "Running tests with options: ${RSPEC_OPTS}"
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
        log_info "No tests found"
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
