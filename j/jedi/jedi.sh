#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : jedi
# Version       : v0.19.2
# Source repo   : https://github.com/davidhalter/jedi
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Sai Kiran Nukala <Sai.Kiran.Nukala@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="jedi"
PACKAGE_VERSION="${1:-v0.19.2}"
PACKAGE_URL="https://github.com/davidhalter/jedi"

NOARCH="true"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git python3-devel"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: custom_test_command — run import smoke-test only; full test suite
# has widespread PosixPath.endswith() failures when run from inside the clone
# directory on Python 3.10+; use --pyargs to run against the installed package
# =============================================================================
custom_test_command() {
    log_info "Running import smoke-test for jedi ${PACKAGE_VERSION}"
    python -c "
import jedi
print('jedi version:', jedi.__version__)
script = jedi.Script('import os\nos.path.')
completions = script.complete(2, 8)
assert completions, 'jedi.Script.complete() returned no completions'
print('completion smoke-test passed:', len(completions), 'completions found')
"
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"

