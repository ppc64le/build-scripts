#!/bin/bash
# =============================================================================
# distro-packages.sh - Multi-distro package installation with sudo
# =============================================================================
# This file provides functions for installing packages across different
# Linux distributions with proper sudo handling and prerequisite checks.
#
# Usage:
#   source "${SCRIPT_DIR}/lib/distro-packages.sh"
#
#   # Set packages for each distro family
#   RH_DEP_PKGS="git gcc make"
#   DEB_DEP_PKGS="git gcc make"
#   SLES_DEP_PKGS="git gcc make"
#
#   # Install packages
#   install_packages
#
# Supported distributions:
#   - Red Hat family: RHEL, CentOS, Fedora, UBI (dnf/yum)
#   - Debian family: Debian, Ubuntu (apt-get)
#   - SUSE family: SLES, openSUSE (zypper)
# =============================================================================

# Prevent multiple sourcing
[[ -n "$_DISTRO_PACKAGES_SH_SOURCED" ]] && return 0
_DISTRO_PACKAGES_SH_SOURCED=1

# =============================================================================
# PACKAGE LISTS BY DISTRIBUTION FAMILY
# Set these in your build script before calling install_packages
# =============================================================================
: ${RH_DEP_PKGS:=""}      # Red Hat family (yum/dnf)
: ${DEB_DEP_PKGS:=""}     # Debian family (apt)
: ${SLES_DEP_PKGS:=""}    # SUSE family (zypper)

# =============================================================================
# INTERNAL HELPER FUNCTIONS
# =============================================================================

# _check_rpm_packages: Check if all packages are installed (RPM-based)
# Returns 0 if all installed, 1 if any missing
_check_rpm_packages() {
    local packages="$1"
    local pkg

    for pkg in $packages; do
        if ! rpm -q "$pkg" &>/dev/null 2>&1; then
            return 1
        fi
    done
    return 0
}

# _check_deb_packages: Check if all packages are installed (DEB-based)
# Returns 0 if all installed, 1 if any missing
_check_deb_packages() {
    local packages="$1"
    local pkg

    for pkg in $packages; do
        if ! dpkg -l "$pkg" 2>/dev/null | grep -q "^ii"; then
            return 1
        fi
    done
    return 0
}

# =============================================================================
# MAIN INSTALLATION FUNCTION
# =============================================================================

# install_packages: Install packages based on detected OS
# Uses RH_DEP_PKGS, DEB_DEP_PKGS, SLES_DEP_PKGS variables
install_packages() {
    echo "[INFO] Checking package dependencies..."

    if command -v dnf &>/dev/null; then
        # Red Hat family with DNF (Fedora, RHEL 8+, CentOS Stream, UBI 8+)
        _install_redhat_dnf

    elif command -v yum &>/dev/null; then
        # Red Hat family with YUM (RHEL 7, CentOS 7)
        _install_redhat_yum

    elif command -v apt-get &>/dev/null; then
        # Debian family (Debian, Ubuntu)
        _install_debian

    elif command -v zypper &>/dev/null; then
        # SUSE family (SLES, openSUSE)
        _install_suse

    else
        echo "[WARN] Unknown package manager. Manual installation required."
        echo "       Red Hat packages: $RH_DEP_PKGS"
        echo "       Debian packages:  $DEB_DEP_PKGS"
        echo "       SUSE packages:    $SLES_DEP_PKGS"
        return 1
    fi
}

# =============================================================================
# DISTRIBUTION-SPECIFIC INSTALLATION FUNCTIONS
# =============================================================================

_install_redhat_dnf() {
    if [[ -z "$RH_DEP_PKGS" ]]; then
        echo "[INFO] No Red Hat packages specified"
        return 0
    fi

    if _check_rpm_packages "$RH_DEP_PKGS"; then
        echo "[INFO] All Red Hat packages already installed"
        return 0
    fi

    echo "[INFO] Installing Red Hat packages with dnf: $RH_DEP_PKGS"
    # shellcheck disable=SC2086
    sudo dnf install -y $RH_DEP_PKGS
}

_install_redhat_yum() {
    if [[ -z "$RH_DEP_PKGS" ]]; then
        echo "[INFO] No Red Hat packages specified"
        return 0
    fi

    if _check_rpm_packages "$RH_DEP_PKGS"; then
        echo "[INFO] All Red Hat packages already installed"
        return 0
    fi

    echo "[INFO] Installing Red Hat packages with yum: $RH_DEP_PKGS"
    # shellcheck disable=SC2086
    sudo yum install -y $RH_DEP_PKGS
}

_install_debian() {
    if [[ -z "$DEB_DEP_PKGS" ]]; then
        echo "[INFO] No Debian packages specified"
        return 0
    fi

    if _check_deb_packages "$DEB_DEP_PKGS"; then
        echo "[INFO] All Debian packages already installed"
        return 0
    fi

    echo "[INFO] Installing Debian packages: $DEB_DEP_PKGS"
    sudo apt-get update
    # shellcheck disable=SC2086
    sudo apt-get install -y $DEB_DEP_PKGS
}

_install_suse() {
    if [[ -z "$SLES_DEP_PKGS" ]]; then
        echo "[INFO] No SUSE packages specified"
        return 0
    fi

    if _check_rpm_packages "$SLES_DEP_PKGS"; then
        echo "[INFO] All SUSE packages already installed"
        return 0
    fi

    echo "[INFO] Installing SUSE packages: $SLES_DEP_PKGS"
    # shellcheck disable=SC2086
    sudo zypper install -y $SLES_DEP_PKGS
}

# =============================================================================
# ADDITIONAL PACKAGE MANAGEMENT FUNCTIONS
# =============================================================================

# install_extra_repos: Add extra repositories (Red Hat only)
# Usage: install_extra_repos "repo_url1" "repo_url2"
install_extra_repos() {
    if ! command -v dnf &>/dev/null && ! command -v yum &>/dev/null; then
        echo "[WARN] install_extra_repos only supported on Red Hat family"
        return 1
    fi

    local repo_url
    for repo_url in "$@"; do
        echo "[INFO] Adding repository: $repo_url"
        if command -v dnf &>/dev/null; then
            sudo dnf config-manager --add-repo "$repo_url" || true
        else
            sudo yum-config-manager --add-repo "$repo_url" || true
        fi
    done
}

# import_rpm_key: Import an RPM GPG key
# Usage: import_rpm_key "key_url"
import_rpm_key() {
    local key_url="$1"

    echo "[INFO] Importing RPM key: $key_url"
    sudo rpm --import "$key_url"
}

# install_epel: Install EPEL repository (RHEL/CentOS only)
install_epel() {
    if ! command -v dnf &>/dev/null && ! command -v yum &>/dev/null; then
        echo "[WARN] EPEL only available on Red Hat family"
        return 1
    fi

    if rpm -q epel-release &>/dev/null; then
        echo "[INFO] EPEL already installed"
        return 0
    fi

    echo "[INFO] Installing EPEL repository"
    if command -v dnf &>/dev/null; then
        sudo dnf install -y epel-release || \
            sudo dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
    else
        sudo yum install -y epel-release || \
            sudo yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
    fi
}
