#!/bin/bash
# =============================================================================
# prereq-checks.sh - Prerequisite checking functions
# =============================================================================
# This file provides functions for checking if prerequisites are met
# before attempting operations that would require sudo.
#
# Usage:
#   source "${SCRIPT_DIR}/lib/prereq-checks.sh"
#
#   if check_command rustc; then
#       echo "Rust is installed"
#   else
#       install_rust
#   fi
# =============================================================================

# Prevent multiple sourcing
[[ -n "$_PREREQ_CHECKS_SH_SOURCED" ]] && return 0
_PREREQ_CHECKS_SH_SOURCED=1

# =============================================================================
# COMMAND CHECKING
# =============================================================================

# check_command: Check if a command exists in PATH
# Usage: check_command rustc
check_command() {
    local cmd="$1"
    command -v "$cmd" &>/dev/null
}

# require_command: Check if command exists, exit with error if not
# Usage: require_command git "Git is required for cloning"
require_command() {
    local cmd="$1"
    local message="${2:-$cmd is required but not installed}"

    if ! check_command "$cmd"; then
        echo "[ERROR] $message"
        return 1
    fi
    return 0
}

# =============================================================================
# PACKAGE CHECKING
# =============================================================================

# check_rpm_package: Check if a package is installed (RPM-based systems)
# Usage: check_rpm_package gcc
check_rpm_package() {
    local pkg="$1"
    rpm -q "$pkg" &>/dev/null
}

# check_deb_package: Check if a package is installed (DEB-based systems)
# Usage: check_deb_package gcc
check_deb_package() {
    local pkg="$1"
    dpkg -l "$pkg" 2>/dev/null | grep -q "^ii"
}

# check_package: Check if a package is installed (auto-detect system)
# Usage: check_package gcc
check_package() {
    local pkg="$1"

    if command -v rpm &>/dev/null; then
        check_rpm_package "$pkg"
    elif command -v dpkg &>/dev/null; then
        check_deb_package "$pkg"
    else
        # Unknown system, assume not installed
        return 1
    fi
}

# =============================================================================
# SERVICE CHECKING
# =============================================================================

# check_service_running: Check if a systemd service is running
# Usage: check_service_running docker
check_service_running() {
    local service="$1"
    systemctl is-active --quiet "$service" 2>/dev/null
}

# check_service_enabled: Check if a systemd service is enabled
# Usage: check_service_enabled docker
check_service_enabled() {
    local service="$1"
    systemctl is-enabled --quiet "$service" 2>/dev/null
}

# =============================================================================
# FILE AND DIRECTORY CHECKING
# =============================================================================

# check_file_exists: Check if a file exists
# Usage: check_file_exists /etc/config.conf
check_file_exists() {
    local path="$1"
    [[ -f "$path" ]]
}

# check_dir_exists: Check if a directory exists
# Usage: check_dir_exists /opt/myapp
check_dir_exists() {
    local path="$1"
    [[ -d "$path" ]]
}

# check_file_readable: Check if a file exists and is readable
# Usage: check_file_readable /etc/config.conf
check_file_readable() {
    local path="$1"
    [[ -r "$path" ]]
}

# check_file_writable: Check if a file/dir is writable
# Usage: check_file_writable /opt/myapp
check_file_writable() {
    local path="$1"
    [[ -w "$path" ]]
}

# =============================================================================
# FILE OWNERSHIP CHECKING
# =============================================================================

# check_ownership: Check if file has specific owner:group
# Usage: check_ownership /opt/myapp myuser mygroup
check_ownership() {
    local path="$1"
    local expected_user="$2"
    local expected_group="$3"

    if [[ ! -e "$path" ]]; then
        return 1
    fi

    local current_owner
    # Try GNU stat first, then BSD stat
    current_owner=$(stat -c '%U:%G' "$path" 2>/dev/null || stat -f '%Su:%Sg' "$path" 2>/dev/null)

    [[ "$current_owner" == "$expected_user:$expected_group" ]]
}

# =============================================================================
# VERSION CHECKING
# =============================================================================

# check_version_ge: Check if version A >= version B
# Usage: check_version_ge "3.10.0" "3.9.0"  # returns true
check_version_ge() {
    local version_a="$1"
    local version_b="$2"

    # Use sort -V for version comparison
    printf '%s\n%s\n' "$version_b" "$version_a" | sort -V -C
}

# get_python_version: Get the version of a Python interpreter
# Usage: get_python_version python3.11  # outputs "3.11.x"
get_python_version() {
    local python_cmd="${1:-python3}"

    if check_command "$python_cmd"; then
        "$python_cmd" --version 2>&1 | awk '{print $2}'
    else
        echo ""
    fi
}

# =============================================================================
# NETWORK CHECKING
# =============================================================================

# check_url_reachable: Check if a URL is reachable
# Usage: check_url_reachable "https://github.com"
check_url_reachable() {
    local url="$1"
    local timeout="${2:-5}"

    if check_command curl; then
        curl -s --head --connect-timeout "$timeout" "$url" &>/dev/null
    elif check_command wget; then
        wget -q --spider --timeout="$timeout" "$url" &>/dev/null
    else
        # Can't check, assume reachable
        return 0
    fi
}

# =============================================================================
# ENVIRONMENT CHECKING
# =============================================================================

# check_env_var: Check if an environment variable is set
# Usage: check_env_var HOME
check_env_var() {
    local var_name="$1"
    [[ -n "${!var_name:-}" ]]
}

# check_in_path: Check if a directory is in PATH
# Usage: check_in_path "/usr/local/bin"
check_in_path() {
    local dir="$1"
    [[ ":$PATH:" == *":$dir:"* ]]
}

# check_is_root: Check if running as root
check_is_root() {
    [[ $EUID -eq 0 ]]
}

# check_has_sudo: Check if user can run sudo
check_has_sudo() {
    sudo -n true 2>/dev/null
}
