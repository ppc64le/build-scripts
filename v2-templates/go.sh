#!/bin/bash
# =============================================================================
# go.sh - Invocable Go Build Template
# =============================================================================
# This template is SOURCED by user build scripts, not executed directly.
# It provides the standard Go build workflow with callback hooks for
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
#   GO_VERSION      - Go version to install (default: 1.23.4)
#   GOROOT          - Go installation directory (default: /usr/local/go)
#   GOPATH          - Go workspace (default: $HOME/go)
#   CLONE_DIR       - Directory name for clone (default: PACKAGE_NAME)
#   SKIP_TESTS      - Set to "true" to skip test phase
#   NOARCH          - Set to "true" to use go install from module proxy
#                     (Note: Go code still compiles; this fetches from proxy)
#   GO_MODULE_PATH  - Module path for NOARCH install (e.g., github.com/org/pkg)
#
# CALLBACK HOOKS (define as functions before sourcing):
#   pre_packages()         - Before package install (add extra repos)
#   pre_clone()            - Before git clone (extra deps, environment)
#   post_clone()           - After checkout (apply patches, modify source)
#   pre_build()            - Before go build (environment setup)
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
    echo "Usage: source \"\${SCRIPT_DIR}/../templates/go.sh\""
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
source "${TEMPLATE_DIR}/lib/artifacts.sh"
source "${TEMPLATE_DIR}/lib/container.sh"

# =============================================================================
# VALIDATE REQUIRED VARIABLES
# =============================================================================
validate_required_vars PACKAGE_NAME PACKAGE_VERSION PACKAGE_URL

# Set defaults for optional variables
: ${GO_VERSION:="1.25.1"}
: ${GOROOT:="/usr/local/go"}
: ${GOPATH:="$HOME/go"}
: ${CLONE_DIR:="$PACKAGE_NAME"}
: ${SKIP_TESTS:="false"}
: ${NOARCH:="false"}
: ${GO_MODULE_PATH:=""}
: ${GO_TEST_OPTS:=""}

# TEMP FIX: If GOROOT contains a version (e.g., /usr/local/go-1.26.1),
# derive GO_VERSION from it to avoid version mismatch issues.
# This handles cases where harness sets mismatched GO_VERSION and GOROOT.
if [[ "$GOROOT" =~ go-([0-9]+\.[0-9]+(\.[0-9]+)?)$ ]]; then
    _goroot_version="${BASH_REMATCH[1]}"
    if [[ "$_goroot_version" != "$GO_VERSION" ]]; then
        log_info "TEMP FIX: Overriding GO_VERSION=${GO_VERSION} with ${_goroot_version} (from GOROOT=${GOROOT})"
        GO_VERSION="$_goroot_version"
    fi
    unset _goroot_version
fi

export GOROOT GOPATH
export PATH="$PATH:$GOROOT/bin:$GOPATH/bin"

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
log_info "Go version: $GO_VERSION"
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
# INSTALL GO
# =============================================================================
# Strategy:
# 1. Check if requested version is already available
# 2. If not, try to download it
# 3. If download fails, fall back to container's default Go (if available)

_go_install_needed=false
_current_go_version=""

if check_command go; then
    _current_go_version="$(go version 2>/dev/null | awk '{print $3}' | sed 's/go//')"
    if [[ "$_current_go_version" == "$GO_VERSION" ]]; then
        log_info "Go ${GO_VERSION} already available"
    else
        log_info "Go ${_current_go_version} available, but ${GO_VERSION} requested"
        _go_install_needed=true
    fi
else
    log_info "Go not found in PATH, will install"
    _go_install_needed=true
fi

if [[ "$_go_install_needed" == "true" ]]; then
    log_info "Installing Go $GO_VERSION"

    # Determine architecture
    ARCH=$(uname -m)
    case "$ARCH" in
        x86_64)  GO_ARCH="amd64" ;;
        aarch64) GO_ARCH="arm64" ;;
        ppc64le) GO_ARCH="ppc64le" ;;
        s390x)   GO_ARCH="s390x" ;;
        *)       log_error "Unsupported architecture: $ARCH"; exit 1 ;;
    esac

    GO_TARBALL="go${GO_VERSION}.linux-${GO_ARCH}.tar.gz"
    GO_URL="https://go.dev/dl/${GO_TARBALL}"

    log_info "Downloading Go from ${GO_URL}"
    _download_ok=false
    if wget -q "$GO_URL" -O "/tmp/${GO_TARBALL}" && [[ -s "/tmp/${GO_TARBALL}" ]]; then
        _download_ok=true
    fi

    if [[ "$_download_ok" == "true" ]]; then
        log_info "Extracting Go to ${GOROOT}"
        if [[ "$GOROOT" == "/usr/local/go" ]]; then
            sudo rm -rf /usr/local/go
            if ! sudo tar -C /usr/local -xzf "/tmp/${GO_TARBALL}"; then
                log_warn "Failed to extract Go tarball"
                _download_ok=false
            fi
        else
            # Tarball extracts to 'go/', need to move to custom GOROOT path
            rm -rf "$GOROOT"
            local parent_dir="$(dirname "$GOROOT")"
            mkdir -p "${parent_dir}"
            rm -rf "${parent_dir}/go"
            if tar -C "${parent_dir}" -xzf "/tmp/${GO_TARBALL}"; then
                # Rename extracted 'go' directory to match GOROOT
                if [[ "${parent_dir}/go" != "$GOROOT" ]]; then
                    mv "${parent_dir}/go" "$GOROOT"
                fi
            else
                log_warn "Failed to extract Go tarball"
                _download_ok=false
            fi
        fi
        rm -f "/tmp/${GO_TARBALL}"
    fi

    # Verify installation or fall back
    if [[ "$_download_ok" == "true" ]] && [[ -x "${GOROOT}/bin/go" ]]; then
        export PATH="${GOROOT}/bin:${PATH}"
        log_info "Go ${GO_VERSION} installed successfully"
    else
        # Fall back to container default if available
        if [[ -n "$_current_go_version" ]]; then
            log_warn "Failed to install Go ${GO_VERSION}, falling back to container default (${_current_go_version})"
            GO_VERSION="$_current_go_version"
        elif check_command go; then
            _current_go_version="$(go version 2>/dev/null | awk '{print $3}' | sed 's/go//')"
            log_warn "Failed to install Go ${GO_VERSION}, falling back to container default (${_current_go_version})"
            GO_VERSION="$_current_go_version"
        else
            log_error "Go ${GO_VERSION} not available and no fallback found"
            exit 1
        fi
    fi

    unset _download_ok
fi

unset _go_install_needed _current_go_version

# Final verification - Go must be available
if ! check_command go; then
    log_error "Go not available after installation attempts"
    exit 1
fi

log_info "Go version: $(go version)"

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
# BUILD
# =============================================================================
if _has_callback custom_build; then
    log_info "Running custom_build hook..."
    if ! custom_build; then
        report_build_fail
    fi
elif [[ "$NOARCH" == "true" ]]; then
    # NOARCH: Use go install from module proxy (still compiles, but fetches source remotely)
    if [[ -z "$GO_MODULE_PATH" ]]; then
        # Try to derive from PACKAGE_URL
        GO_MODULE_PATH=$(echo "$PACKAGE_URL" | sed 's|https://||; s|\.git$||')
    fi
    local go_version="${PACKAGE_VERSION}"
    log_info "NOARCH mode: Installing ${GO_MODULE_PATH}@${go_version} from module proxy"
    if ! go install "${GO_MODULE_PATH}@${go_version}"; then
        report_build_fail
    fi
else
    log_info "Building package"

    # Download dependencies
    go mod tidy 2>/dev/null || true
    go mod download 2>/dev/null || true

    if ! go build ./...; then
        report_build_fail
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

if [[ -n "${GO_TEST_OPTS}" ]]; then
    log_info "Running tests with options: ${GO_TEST_OPTS}"
else
    log_info "Running tests"
fi

test_status=1

if _has_callback custom_test_command; then
    log_info "Running custom_test_command hook..."
    custom_test_command && test_status=0 || test_status=$?
else
    go test ./... ${GO_TEST_OPTS} && test_status=0 || test_status=$?
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
    report_build_test_success
else
    report_build_success_test_fail
fi
