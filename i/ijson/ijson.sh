#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package        : ijson
# Version        : 3.4.0
# Source repo    : https://github.com/ICRAR/ijson
# Tested on      : UBI:9.6
# Language       : Python
# CI Check       : True
# Script License :  Apache License, Version 2.0 or later
# Maintainer     : Shivansh.S1 <Shivansh.S1@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PACKAGE_NAME=ijson
PACKAGE_VERSION=${1:-v3.4.0}
PACKAGE_URL=https://github.com/ICRAR/ijson

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
RH_DEP_PKGS="gcc-toolset-13-gcc gcc-toolset-13-gcc-gfortran git make automake autoconf python3 python3-devel python3-pip cmake yajl"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""


# =============================================================================
# CALLBACK: post_clone — Read setuptools version constraint from pyproject.toml
# =============================================================================
post_clone() {
    log_info "Reading setuptools version from pyproject.toml"
    local setuptools_req
    setuptools_req="$(grep -o '"setuptools[><=!][^"]*"' pyproject.toml | head -1 | tr -d '"')"
    if [[ -n "${setuptools_req}" ]]; then
        SETUPTOOLS_VERSION="${setuptools_req#setuptools}"
        SETUPTOOLS_VERSION="${SETUPTOOLS_VERSION//[[:space:]]/}"
        log_info "Using setuptools${SETUPTOOLS_VERSION} (from pyproject.toml)"
    else
        log_info "setuptools not found in pyproject.toml, using template default"
    fi
}

source "${SCRIPT_DIR}/../../v2-templates/python.sh"