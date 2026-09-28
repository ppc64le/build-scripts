#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : python-fastjsonschema
# Version       : v2.22.2
# Source repo   : https://github.com/horejsek/python-fastjsonschema
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Sai Kiran Nukala <Sai.Kiran.Nukala@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="python-fastjsonschema"
PACKAGE_VERSION="${1:-v2.22.2}"
PACKAGE_URL="https://github.com/horejsek/python-fastjsonschema"

NOARCH="true"
PYPI_NAME="fastjsonschema"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: custom_test_command — skip tests that are incompatible in CI
#   - test_pattern_with_escape_no_warnings: uses warnings.simplefilter("error") and
#     validates that compiling the '\\s' regex pattern emits no warnings; Python's re
#     module on ppc64le emits a DeprecationWarning for unrecognised escape sequences,
#     causing this "treat warnings as errors" assertion to fail.
#   - benchmark: requires pytest-benchmark which is not installed in the test venv;
#     without it these tests error rather than skip.
#   - "definitions.json" and "remote ref" parametrized tests (test_draft04/06/07):
#     these resolve remote $ref URIs (e.g. 'http://json-schema.org/draft-04/schema#')
#     at runtime via urlopen(); the CI container has no external network access
#     (OSError: [Errno 101] Network is unreachable).
#   - "uuid format" and "duration format" parametrized tests (test_draft2019):
#     draft-2019-09 uuid and duration formats are not implemented in this library
#     version (raises JsonSchemaDefinitionException: Unknown format: uuid/duration).
# =============================================================================
custom_test_command() {
    log_info "Running fastjsonschema tests, skipping incompatible tests"
    python -m pytest \
        -o "addopts=" \
        --disable-warnings \
        -k "not (test_pattern_with_escape_no_warnings or benchmark)" \
        --ignore=tests/json_schema/test_draft04.py \
        --ignore=tests/json_schema/test_draft06.py \
        --ignore=tests/json_schema/test_draft07.py \
        --ignore=tests/json_schema/test_draft2019.py
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"

