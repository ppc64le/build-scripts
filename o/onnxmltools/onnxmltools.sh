#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : onnxmltools
# Version       : v1.13
# Source repo   : https://github.com/onnx/onnxmltools
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Ramnath Nayak <Ramnath.Nayak@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="onnxmltools"
PACKAGE_VERSION="${1:-v1.13}"
PACKAGE_URL="https://github.com/onnx/onnxmltools"

NOARCH="true"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: post_clone — patch proto/__init__.py for compatibility with modern onnx
# =============================================================================
post_clone() {
    log_info "Patching onnxmltools/proto/__init__.py for modern onnx compatibility"
    cat << 'EOF' > onnxmltools/proto/__init__.py
# SPDX-License-Identifier: Apache-2.0

from onnx import onnx_pb as onnx_proto
from onnx import helper
from onnx.onnx_pb import TensorProto
EOF
}

# =============================================================================
# CALLBACK: custom_test_command — run unit tests for utility functions
# =============================================================================
custom_test_command() {
    log_info "Patching installed onnxmltools in test venv if present"
    python -c "
import importlib.util, os
spec = importlib.util.find_spec('onnxmltools')
if spec and spec.submodule_search_locations:
    for loc in spec.submodule_search_locations:
        p = os.path.join(loc, 'proto', '__init__.py')
        if os.path.exists(p):
            with open(p, 'w') as f:
                f.write('from onnx import onnx_pb as onnx_proto\nfrom onnx import helper\nfrom onnx.onnx_pb import TensorProto\n')
" 2>/dev/null 

    log_info "Running onnxmltools tests"
    python -m pytest tests/utils/ \
        -o "addopts=" \
        --disable-warnings
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
