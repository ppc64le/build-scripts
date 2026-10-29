#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : runai-model-streamer
# Version       : 0.16.1
# Source repo   : https://github.com/run-ai/runai-model-streamer
# Tested on     : UBI:9.6
# Language      : Python, C++
# Ci-Check      : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Daniel Schenker <daniel.schenker@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="runai-model-streamer"
PACKAGE_VERSION="${1:-0.16.1}"
PACKAGE_URL="https://github.com/run-ai/runai-model-streamer"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
# bazel 7.6.1 is pinned upstream (cpp/.bazelversion). torch and numpy are wheel
# dependencies with no ppc64le wheel on PyPI. openblas, abseil-cpp and
# libprotobuf are the libraries torch was linked against; the pytorch artifact's
# env.sh does not add them to LD_LIBRARY_PATH, so `import torch` needs them here.
BUILD_DEPS="bazel:7.6.1 pytorch:v2.6.0 numpy:v2.2.5 openblas:v0.3.29 abseil-cpp:20240116.2 libprotobuf:v26.1"
RH_DEP_PKGS="git gcc gcc-c++ cmake ninja-build java-21-openjdk-devel \
    libcurl-devel openssl-devel libuuid-devel unzip zip patch python3-devel python3-pip"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: post_clone — apply the ppc64le patches (Makefiles, .bazelrc, freeres.cc)
# =============================================================================
# Hooks run under `if !`, which disables `set -e`; the && chain makes the first
# failing patch the hook's exit status.
post_clone() {
    log_info "Applying ppc64le patches to runai-model-streamer ${PACKAGE_VERSION}"

    git apply "${SCRIPT_DIR}/patches/0001-makefile-ppc64le.patch" &&
    git apply "${SCRIPT_DIR}/patches/0002-bazelrc-ppc64le.patch" &&
    git apply "${SCRIPT_DIR}/patches/0003-freeres-visibility.patch" &&
    git apply "${SCRIPT_DIR}/patches/0004-cpp-makefile-streamer-only.patch" &&
    git apply "${SCRIPT_DIR}/patches/0005-py-makefile-base-wheel-only.patch" &&
    log_info "All 5 ppc64le patches applied"
}

# =============================================================================
# CALLBACK: custom_install — build the core wheel (libstreamer.so, no S3) via Bazel + make
# =============================================================================
# `python -m build` cannot be used: the build is Bazel + make. bazel comes from
# the `bazel` artifact (BUILD_DEPS) and needs JAVA_HOME at run time. The last
# test fails the hook (and the job) when no wheel was produced.
custom_install() {
    export JAVA_HOME=/usr/lib/jvm/java-21-openjdk
    export BAZEL_JAVAC_OPTS="-J-Xmx2g -J-Xms200m"
    export PATH="${JAVA_HOME}/bin:${PATH}"
    log_info "Using bazel: $(command -v bazel) ($(bazel --version 2>&1 | head -1))"

    log_info "Building runai-model-streamer core wheel for ppc64le (version ${PACKAGE_VERSION})"
    export USE_SYSTEM_LIBS=1
    export PACKAGE_VERSION

    mkdir -p "${OUTPUT_DIR}"
    make build &&
    find py -name "runai_model_streamer-${PACKAGE_VERSION}-*.whl" -exec cp {} "${OUTPUT_DIR}/" \;

    [[ -n "$(find py -name "runai_model_streamer-${PACKAGE_VERSION}-*.whl" -print -quit)" ]]
}

# =============================================================================
# CALLBACK: pre_test — install the wheel without dependencies (torch/numpy come from artifacts)
# =============================================================================
# torch and numpy are on PYTHONPATH through the artifacts' env.sh, so pip must
# not try to fetch them (no ppc64le wheels). The template installs the same wheel
# again; PIP_NO_DEPS=1 makes that second install skip the dependency check too.
# torch's pure-Python dependencies come from PyPI.
pre_test() {
    log_info "Installing runtime dependencies into the test venv" \
     python -m pip install --upgrade pip setuptools wheel \
     python -m pip install humanize "safetensors>=0.5.3" \
        filelock typing_extensions sympy networkx jinja2 fsspec \
     log_info "Installing runai_model_streamer wheel with --no-deps (torch/numpy come from artifacts)" \
     python -m pip install --no-deps "${OUTPUT_DIR}"/runai_model_streamer-*.whl \
     export PIP_NO_DEPS=1
}

# =============================================================================
# Helper: list shared libraries torch cannot resolve
# =============================================================================
# `import torch` stops at the first missing .so; ldd lists all of them at once.
# Diagnostic only, it never fails.
_report_missing_libs() {
    local torch_dir
    torch_dir="$(python - <<'PYEOF'
import importlib.util
spec = importlib.util.find_spec("torch")
print(spec.submodule_search_locations[0] if spec and spec.submodule_search_locations else "")
PYEOF
)"
    if [[ -n "${torch_dir}" ]]; then
        log_info "ldd check of ${torch_dir} (lines below = shared libraries not found; none = all resolved)"
        find "${torch_dir}" -maxdepth 2 -name '*.so*' -type f -exec ldd {} + 2>/dev/null \
            | grep 'not found' | sort -u
    else
        log_info "torch not found on PYTHONPATH; skipping ldd check"
    fi
    true
}

# =============================================================================
# CALLBACK: custom_test_command — run the upstream unit tests against the installed wheel
# =============================================================================
# First a dependency check (ldd, imports, libstreamer.so load), then the unit
# tests that ship inside the wheel. pytest collects them by package name, so no
# module is listed by hand; the dist_test_*.py files (need torchrun) are not
# collected. `python -P` keeps the current directory off sys.path while
# PYTHONPATH still works for the torch/numpy artifacts, so the installed wheel
# is tested and not the source tree.
#
# Deselected: TestSafetensorsStreamerMock (9 tests in safetensors_streamer/tests/test_mock.py).
# Its setUp() reads tests/test_files/test.safetensors, which is in the git tree
# but not shipped in the wheel (setup.py package_data lists only the shared
# library), so every test fails with FileNotFoundError. This is an upstream
# packaging limitation, not a ppc64le defect. test_valid_file skips itself for
# the same reason.
custom_test_command() {
    log_info "Checking runtime dependencies (torch, numpy, safetensors, humanize, libstreamer)" \
    && _report_missing_libs \
    && python - <<'PYEOF' \
    && log_info "Running upstream unit tests from the installed wheel" \
    && python -P -m pytest --pyargs runai_model_streamer -v -p no:cacheprovider -o "addopts=" --disable-warnings -k "not TestSafetensorsStreamerMock"
import sys
from importlib import metadata

print(f"Python: {sys.version}")

import torch
print(f"torch       : {torch.__version__}  ({torch.__file__})")
import numpy
print(f"numpy       : {numpy.__version__}  ({numpy.__file__})")
import safetensors
print(f"safetensors : {safetensors.__version__}")
import humanize
print(f"humanize    : {metadata.version('humanize')}")

from runai_model_streamer.libstreamer import dll
print("libstreamer : loaded OK")
PYEOF
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
