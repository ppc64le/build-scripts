#!/bin/bash
# =============================================================================
# common.sh - Core variables and functions for all build scripts
# =============================================================================
# This file should be sourced by all build script templates.
# It provides common functionality for OS detection, output handling,
# and shared configuration variables.
#
# Usage:
#   source "${SCRIPT_DIR}/lib/common.sh"
#
# Required variables (set before sourcing):
#   PACKAGE_NAME    - Name of the package being built
#   PACKAGE_VERSION - Version of the package
#   PACKAGE_URL     - Source repository URL
#
# Optional variables:
#   VERSION_TRACKER - Path to output file (automation sets this)
#   PYTHON_VERSION  - Python interpreter to use (default: python3)
# =============================================================================

# Prevent multiple sourcing
[[ -n "$_COMMON_SH_SOURCED" ]] && return 0
_COMMON_SH_SOURCED=1

# =============================================================================
# SCRIPT METADATA VARIABLES
# These should be overridden by each build script
# =============================================================================
: ${PACKAGE_NAME:=""}
: ${PACKAGE_VERSION:=""}
: ${PACKAGE_URL:=""}

# =============================================================================
# OUTPUT CONFIGURATION
# =============================================================================
# OUTPUT_DIR: Directory for build artifacts (wheels, logs, etc.)
# CI sets this; for users running locally, default to ./output
: ${OUTPUT_DIR:="${PWD}/output"}

# VERSION_TRACKER: When set by automation, output is written to this file
# When unset (user mode), output goes to stdout only
: ${VERSION_TRACKER:=""}

# =============================================================================
# PYTHON CONFIGURATION
# =============================================================================
# PYTHON_VERSION: The Python interpreter to use
# Automation sets this to specific versions (python3.9, python3.14, etc.)
# Default is python3 (system default)
: ${PYTHON_VERSION:="python3"}

# =============================================================================
# OS DETECTION
# =============================================================================
# Populated by detect_os() function
OS_NAME=""
OS_ID=""
OS_VERSION=""

detect_os() {
    if [[ -f /etc/os-release ]]; then
        # shellcheck source=/dev/null
        . /etc/os-release
        OS_NAME="${PRETTY_NAME:-Unknown}"
        OS_ID="${ID:-unknown}"
        OS_VERSION="${VERSION_ID:-unknown}"
    else
        OS_NAME="Unknown"
        OS_ID="unknown"
        OS_VERSION="unknown"
    fi
    export OS_NAME OS_ID OS_VERSION
}

# =============================================================================
# DIRECTORY MANAGEMENT
# =============================================================================
# Preserve SCRIPT_DIR if already set by the calling script
: "${SCRIPT_DIR:=}"
: "${WORK_DIR:=}"

ensure_workdir() {
    # Get the directory containing the calling script
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)"
    WORK_DIR="${WORK_DIR:-$PWD}"
    export SCRIPT_DIR WORK_DIR
}

# =============================================================================
# OUTPUT FUNCTIONS
# =============================================================================

# output_status: Write status message to VERSION_TRACKER (if set) and stdout
# Usage: output_status "message"
output_status() {
    local message="$1"

    # Always write to stdout
    echo "$message"

    # Also write to VERSION_TRACKER file if set
    if [[ -n "$VERSION_TRACKER" ]]; then
        # Ensure directory exists
        local tracker_dir
        tracker_dir="$(dirname "$VERSION_TRACKER")"
        if [[ ! -d "$tracker_dir" ]]; then
            mkdir -p "$tracker_dir" 2>/dev/null || true
        fi
        echo "$message" >> "$VERSION_TRACKER"
    fi
}

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

# log_info: Print informational message
log_info() {
    echo "[INFO] $*"
}

# log_warn: Print warning message
log_warn() {
    echo "[WARN] $*" >&2
}

# log_error: Print error message
log_error() {
    echo "[ERROR] $*" >&2
}

# validate_required_vars: Check that required variables are set
# Usage: validate_required_vars PACKAGE_NAME PACKAGE_VERSION PACKAGE_URL
validate_required_vars() {
    local var_name
    local missing=()

    for var_name in "$@"; do
        if [[ -z "${!var_name:-}" ]]; then
            missing+=("$var_name")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Required variables not set: ${missing[*]}"
        return 1
    fi
    return 0
}

# =============================================================================
# STUB FUNCTIONS FOR UNSUPPORTED BUILD TOOLS
# =============================================================================

# stub_unsupported_tool: Create a stub executable that fails with a clear message
# Usage: stub_unsupported_tool "bazel" "Bazel build system"
# Usage: stub_unsupported_tool "cmake" "CMake with external C++ deps" "/path/to/stub/dir"
#
# This allows the build to proceed through all validation steps (deps, clone,
# version checkout, venv creation) and only fail when the actual unsupported
# tool is invoked. Provides clear diagnostics about what's missing.
stub_unsupported_tool() {
    local tool_name="$1"
    local description="${2:-$tool_name}"
    local stub_dir="${3:-${HOME}/.local/bin}"

    mkdir -p "$stub_dir"

    cat > "${stub_dir}/${tool_name}" << STUB
#!/bin/bash
echo "=======================================================" >&2
echo "BLOCKED: ${tool_name} is not yet supported" >&2
echo "=======================================================" >&2
echo "Package: \${PACKAGE_NAME:-unknown}" >&2
echo "Reason: ${description}" >&2
echo "" >&2
echo "This package requires build tooling that is not yet" >&2
echo "integrated into the template system." >&2
echo "=======================================================" >&2
exit 1
STUB
    chmod +x "${stub_dir}/${tool_name}"

    # Ensure stub dir is in PATH
    if [[ ":$PATH:" != *":${stub_dir}:"* ]]; then
        export PATH="${stub_dir}:${PATH}"
    fi

    log_info "Stubbed unsupported tool: ${tool_name}"
}

# =============================================================================
# CLONE AND CHECKOUT FUNCTIONS
# =============================================================================

# init_submodules: Initialize git submodules if .gitmodules file exists
# Usage: init_submodules
# Should be called after clone/checkout, while in the repository directory
init_submodules() {
    if [[ -f ".gitmodules" ]]; then
        log_info "Initializing git submodules"
        git submodule update --init --recursive
    fi
}

# clone_repository: Clone, checkout version, init submodules, and cd into repo
# Usage: clone_repository
# Requires: PACKAGE_URL, CLONE_DIR, PACKAGE_VERSION variables to be set
# On success: Current directory is changed to CLONE_DIR
# On failure: Calls report_clone_fail (exits script)
#
# CI Environment Support:
#   If already inside a git repo (e.g., CI pre-cloned to /workspace),
#   uses current directory instead of cloning. Checks out the requested
#   version if not already on it.
clone_repository() {
    log_info "Cloning $PACKAGE_URL"
    log_info "clone_repository: PWD=${PWD} CLONE_DIR=${CLONE_DIR} PACKAGE_VERSION=${PACKAGE_VERSION}"

    # Check if we're already inside a git repository (CI environment)
    if git rev-parse --git-dir > /dev/null 2>&1; then
        local current_dir="$PWD"
        local git_root
        git_root="$(git rev-parse --show-toplevel 2>/dev/null)"
        log_info "clone_repository: detected git repo, git_root=${git_root}"

        # If we're at the git root, use it directly (CI pre-clone case)
        if [[ "$current_dir" == "$git_root" ]]; then
            log_info "Already in git repository at $git_root, using existing clone"

            # Check if we need to checkout the requested version
            local current_ref
            current_ref="$(git describe --tags --exact-match 2>/dev/null || git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'unknown')"
            log_info "clone_repository: current_ref=${current_ref}"
            if [[ "$current_ref" != "$PACKAGE_VERSION" ]]; then
                log_info "Checking out $PACKAGE_VERSION"
                local checkout_out
                checkout_out="$(git checkout "$PACKAGE_VERSION" 2>&1)"
                local checkout_rc=$?
                log_info "clone_repository: git checkout exit=${checkout_rc} output=${checkout_out}"
                if [[ $checkout_rc -ne 0 ]]; then
                    mkdir -p "${OUTPUT_DIR}"
                    git tag --sort=-version:refname | paste -sd, > "${OUTPUT_DIR}/available_versions.txt"
                    report_clone_fail
                fi
            fi

            init_submodules
            return 0
        fi
    fi

    # Standard clone path
    if [[ -d "$CLONE_DIR" ]]; then
        log_info "Directory $CLONE_DIR already exists, using existing clone"
        cd "$CLONE_DIR"
        log_info "clone_repository: PWD is now ${PWD}"
        log_info "clone_repository: git remote: $(git remote -v 2>&1 | head -2 | tr '\n' ' ')"
        log_info "clone_repository: HEAD before reset: $(git log --oneline -1 2>&1)"
        log_info "clone_repository: git status before reset: $(git status --short 2>&1 | head -10 | tr '\n' '|')"
        # Reset any leftover state from a previous build run so that the
        # subsequent checkout cannot be blocked by modified or untracked files.
        local reset_out; reset_out="$(git reset --hard HEAD 2>&1)"; log_info "clone_repository: git reset: ${reset_out}"
        local clean_out; clean_out="$(git clean -fd 2>&1)";        log_info "clone_repository: git clean: ${clean_out}"
        # Fetch latest tags so the requested version is present in local refs
        # even if a prior run of a different version used the same directory.
        # Only fetch if the requested tag isn't already present locally.
        if ! git rev-parse "refs/tags/${PACKAGE_VERSION}" > /dev/null 2>&1; then
            local fetch_out; fetch_out="$(git fetch --tags 2>&1)"; log_info "clone_repository: git fetch --tags: ${fetch_out:-ok}"
        else
            log_info "clone_repository: tag ${PACKAGE_VERSION} already present locally, skipping fetch"
        fi
        log_info "clone_repository: HEAD after reset: $(git log --oneline -1 2>&1)"
        log_info "clone_repository: available tags (newest 10): $(git tag --sort=-version:refname 2>/dev/null | head -10 | tr '\n' ' ')"
    else
        if ! git clone --no-single-branch --recurse-submodules "$PACKAGE_URL" "$CLONE_DIR"; then
            report_clone_fail
        fi
        cd "$CLONE_DIR"
    fi

    local checkout_out
    checkout_out="$(git checkout "$PACKAGE_VERSION" 2>&1)"
    local checkout_rc=$?
    log_info "clone_repository: git checkout '${PACKAGE_VERSION}' exit=${checkout_rc} output=${checkout_out}"
    if [[ $checkout_rc -ne 0 ]]; then
        mkdir -p "${OUTPUT_DIR}"
        git tag --sort=-version:refname | paste -sd, > "${OUTPUT_DIR}/available_versions.txt"
        report_clone_fail
    fi

    init_submodules
}
