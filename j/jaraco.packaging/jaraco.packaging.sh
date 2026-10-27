#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : jaraco.packaging
# Version       : v10.2.2
# Source repo   : https://github.com/jaraco/jaraco.packaging
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Ramnath Nayak <Ramnath.Nayak@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PACKAGE_NAME="jaraco.packaging"
PACKAGE_VERSION="${1:-v10.2.2}"
PACKAGE_URL="https://github.com/jaraco/jaraco.packaging"

NOARCH="true"

RH_DEP_PKGS="git"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: post_clone — patch source to fix two v10.2.2 incompatibilities
# 1. build.util.StrPath was removed in build>=1.0; pytest-checkdocs imports
#    metadata.py at plugin load time and crashes. The annotation is type-only;
#    replacing with str preserves full runtime behaviour.
# 2. pytest-ruff flags C408/N999/I001/RUF012 linting errors in the upstream
#    v10.2.2 source (docs/conf.py, make-tree.py, sphinx.py). These are style
#    issues in the released tag itself; removing pytest-ruff from test extras
#    skips those checks without affecting functional test coverage.
# =============================================================================
post_clone() {
    log_info "Patching metadata.py: replace util.StrPath annotation (removed in build>=1.0) with str"
    sed -i 's/source_dir: util\.StrPath,/source_dir: str,/' jaraco/packaging/metadata.py

    log_info "Patching pyproject.toml: remove pytest-ruff from test extras (ruff linting fails on upstream v10.2.2 source)"
    sed -i '/"pytest-ruff/d' pyproject.toml
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
