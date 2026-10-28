#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : opencv-python
# Version       : 93
# Source repo   : https://github.com/opencv/opencv-python
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2.0
# Maintainer    : Ira <ira.pandey1@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="opencv-python"
PACKAGE_VERSION="${1:-93}"
PACKAGE_URL="https://github.com/opencv/opencv-python"
CLONE_DIR="opencv-python"

# =============================================================================
# Artifact Dependencies
# openblas provides cblas.h, lapacke.h and libopenblas.so
# numpy sourced from pre-built artifact to avoid compiling from source on every run
# =============================================================================
NUMPY_ARTIFACT_VERSION="${NUMPY_ARTIFACT_VERSION:-v2.2.5}"
BUILD_DEPS=${BUILD_DEPS:-"numpy:${NUMPY_ARTIFACT_VERSION}"}

# =============================================================================
# REQUIRED: Dependencies
# gcc-toolset-13 provides the modern C++17 compiler required by OpenCV
# =============================================================================
RH_DEP_PKGS="wget gcc-toolset-13 gcc-toolset-13-gcc gcc-toolset-13-gcc-c++ \
    gcc-toolset-13-gcc-gfortran gcc-toolset-13-binutils gcc-toolset-13-binutils-devel \
    python3-pip python3-devel \
    ninja-build pkgconfig \
    zlib-devel"

DEB_DEP_PKGS="wget python3-pip python3-dev \
    python3-venv ninja-build pkg-config \
    zlib1g-dev"

SLES_DEP_PKGS="wget python3-pip python3-devel \
    ninja pkg-config \
    zlib-devel"

# =============================================================================
# CALLBACK: post_clone
# 1. Read setuptools version requirement from pyproject.toml (dynamic detection).
# 2. For tag 92 only: fix a missing ')' in vsx_utils.hpp line 261 (upstream
#    typo in the opencv submodule at commit b4c5ec40) that breaks compilation
#    of the Python bindings module (modules/python3).
# Note: VSX is disabled entirely via ENABLE_VSX=OFF in CMAKE_ARGS; the patch
#       only fixes the preprocessor syntax error, not VSX intrinsic usage.
# =============================================================================
post_clone() {
    # Read setuptools constraint directly from pyproject.toml if present
    log_info "Reading setuptools version requirement from pyproject.toml"
    if [[ -f "pyproject.toml" ]]; then
        local setuptools_req setuptools_ver
        # Extract the full setuptools requirement (e.g. "setuptools==59.2.0;python_version<'3.12'")
        setuptools_req="$(grep -o '"setuptools[^"]*"' pyproject.toml | head -1 | tr -d '"')"
        if [[ -n "$setuptools_req" ]]; then
            # Strip any PEP 508 environment marker at ';', keep version only
            setuptools_ver="${setuptools_req#setuptools}"    # e.g. ==59.2.0;python_version<'3.12'
            setuptools_ver="${setuptools_ver%%;*}"           # version only: ==59.2.0
            setuptools_ver="${setuptools_ver//[[:space:]]/}"
            # Skip any setuptools pin < 60 on Python 3.12+ — distutils was removed
            # in 3.12 and setuptools < 60 depends on it, regardless of any marker.
            local _py_minor _pin_major
            _py_minor="$(python -c 'import sys; print(sys.version_info.minor)')"
            _pin_major="$(echo "${setuptools_ver}" | grep -oP '(?<==)\d+' | head -1)"
            if [[ "${_py_minor}" -ge 12 ]] && [[ -n "${_pin_major}" ]] && [[ "${_pin_major}" -lt 60 ]]; then
                log_info "Skipping setuptools pin '${setuptools_ver}' (setuptools<60 incompatible with Python 3.${_py_minor}) — using template default"
                unset _py_minor _pin_major
            elif [[ -n "$setuptools_ver" ]]; then
                SETUPTOOLS_VERSION="${setuptools_ver}"
                log_info "Using SETUPTOOLS_VERSION='${SETUPTOOLS_VERSION}' from pyproject.toml"
            else
                log_info "No setuptools version pin found in pyproject.toml — using template default"
            fi
        else
            log_info "No setuptools pin found in pyproject.toml — using template default"
        fi
    else
        SETUPTOOLS_VERSION="<82"
        log_info "No pyproject.toml found — falling back to SETUPTOOLS_VERSION='${SETUPTOOLS_VERSION}'"
    fi

    # Use subshell so cd into opencv/ never leaves parent shell in wrong directory
    (
        cd opencv

        # ------------------------------------------------------------------
        # Tag 92 only: vsx_utils.hpp line 261 is missing a closing ')' in the
        # #if expression — upstream bug in opencv submodule commit b4c5ec40.
        # Tags 84 and 93 do not have this bug and must not have this patch applied.
        # ------------------------------------------------------------------
        if [[ "${PACKAGE_VERSION}" == "92" ]]; then
            local PATCH_FILE="${SCRIPT_DIR}/patches/opencv_92_vsx_utils.patch"
            log_info "Applying vsx_utils.hpp syntax fix for tag 92..."
            git apply "${PATCH_FILE}"
            log_info "Patch applied successfully"
        fi

    )
}

# =============================================================================
# CALLBACK: pre_test
# Install the numpy artifact wheel into the test venv before the template
# installs the opencv-python wheel into it.  Without this, pip resolves
# numpy as a missing dependency and compiles it from PyPI source — a full
# ~1 GB build that wastes time and can exhaust disk space.
# =============================================================================
pre_test() {
    if source_artifact numpy "${NUMPY_ARTIFACT_VERSION}" 2>/dev/null; then
        local numpy_wheel python_abi python_ver
        python_abi=$(python -c "import sys; print(f'cp{sys.version_info.major}{sys.version_info.minor}')")
        python_ver=$(python -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
        numpy_wheel=$(find "${NUMPY_PREFIX}/wheels" -name "numpy-*-${python_abi}-${python_abi}-*.whl" 2>/dev/null | head -1)
        if [[ -n "${numpy_wheel}" ]]; then
            log_info "Installing NumPy wheel into test venv from artifact: ${numpy_wheel}"
            python -m pip install --force-reinstall --no-deps "${numpy_wheel}"
        else
            log_warn "No ABI-matched NumPy wheel for ${python_abi} in artifact — test venv will resolve numpy from PyPI"
        fi
    else
        log_warn "numpy artifact not available for pre_test — test venv will resolve numpy from PyPI"
    fi
}

# =============================================================================
# CALLBACK: custom_install
# opencv-python uses scikit-build and requires CMAKE_ARGS to be exported
# before `python -m pip install .`.  The standard `python -m build` path does
# not honour CMAKE_ARGS, so we must drive the build ourselves.
#
# Steps:
#   1. Re-export gcc-toolset-13 paths (callbacks run in new scope)
#   2. Source openblas artifact (provides OPENBLAS_PREFIX, cblas.h, lapacke.h)
#   3. Export CMAKE_ARGS with all required -D flags
#   4. python -m pip install . --no-build-isolation
#   5. Build a .whl with pip wheel (reuses _skbuild/ cmake cache, no recompile)
# =============================================================================
custom_install() {
    log_info "Starting opencv-python custom build (version ${PACKAGE_VERSION})..."

    # ------------------------------------------------------------------
    # Source pre-built openblas artifact (provides OPENBLAS_PREFIX,
    # LD_LIBRARY_PATH, PKG_CONFIG_PATH, cblas.h, lapacke.h, libopenblas.so)
    # ------------------------------------------------------------------
    if ! source_artifact openblas; then
        log_error "openblas artifact not found — build openblas first"
        false
    fi
    log_info "OpenBLAS prefix: ${OPENBLAS_PREFIX}"

    # ------------------------------------------------------------------
    # Python tooling — versions inside the activated venv (.venv-build)
    # ------------------------------------------------------------------
    python -m pip install --upgrade pip
    python -m pip install cython scikit-build build wheel cmake

    # Install numpy from pre-built artifact wheel into the active venv.
    # Follows the same pattern as scipy.sh: source artifact, find the
    # ABI-matched wheel, pip install it into the venv, then strip the
    # artifact PYTHONPATH so the venv copy takes precedence.
    #
    # The numpy artifact is Python-version-specific (one cpXY ABI tag per
    # build). If the active Python does not match the artifact, the build
    # fails early with a clear message — run the numpy build script for
    # the required Python version first.
    if ! source_artifact numpy; then
        log_error "numpy artifact not found — build numpy first"
        false
    fi
    log_info "NumPy prefix: ${NUMPY_PREFIX}"
    local numpy_wheel python_abi python_ver numpy_artifact_site
    python_abi=$(python -c "import sys; print(f'cp{sys.version_info.major}{sys.version_info.minor}')")
    python_ver=$(python -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
    numpy_wheel=$(find "${NUMPY_PREFIX}/wheels" -name "numpy-*-${python_abi}-${python_abi}-*.whl" 2>/dev/null | head -1)
    if [[ -z "${numpy_wheel}" ]]; then
        log_error "No ABI-matched NumPy wheel for ${python_abi} found in artifact ${NUMPY_PREFIX}/wheels/"
        log_error "Build the numpy artifact for Python ${python_ver} first, then re-run this build"
        false
    fi
    log_info "Installing NumPy wheel from artifact: ${numpy_wheel}"
    python -m pip install --force-reinstall --no-deps "${numpy_wheel}"
    # Strip artifact site-packages from PYTHONPATH (wherever it appears) so the
    # venv-installed copy takes precedence over the artifact's site-packages.
    numpy_artifact_site="${NUMPY_PREFIX}/lib/python${python_ver}/site-packages"
    if [[ -n "${PYTHONPATH:-}" ]]; then
        local _new_pypath
        _new_pypath=$(echo "${PYTHONPATH}" | tr ':' '\n' | grep -v "^${numpy_artifact_site}$" | tr '\n' ':' | sed 's/:$//')
        if [[ -z "${_new_pypath}" ]]; then
            unset PYTHONPATH
        else
            export PYTHONPATH="${_new_pypath}"
        fi
        unset _new_pypath
    fi

    # Set numpy C-include path (required for cv2 Cython build)
    export C_INCLUDE_PATH
    C_INCLUDE_PATH=$(python -c "import numpy; print(numpy.get_include())")
    export CPLUS_INCLUDE_PATH="${C_INCLUDE_PATH}"

    # ------------------------------------------------------------------
    # Build the full (GUI-capable) variant; ENABLE_HEADLESS=0 means
    # the package name stays "opencv-python" (not "opencv-python-headless")
    # ------------------------------------------------------------------
    export ENABLE_HEADLESS=0

    # ------------------------------------------------------------------
    # CMAKE_ARGS — disable media / platform features not available in a
    # minimal UBI container, build protobuf from bundled sources to avoid
    # header-path conflicts with any system-installed version.
    # ------------------------------------------------------------------
    export CMAKE_ARGS="-DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_CXX_STANDARD=17 \
        -DCMAKE_CXX_STANDARD_REQUIRED=ON \
        -DENABLE_VSX=OFF \
        -DCV_ENABLE_INTRINSICS=OFF \
        -DCPU_BASELINE='' \
        -DCPU_DISPATCH='' \
        -DWITH_IPP=OFF \
        -DWITH_EIGEN=1 \
        -DBUILD_TESTS=0 \
        -DBUILD_DOCS=0 \
        -DBUILD_PERF_TESTS=0 \
        -DBUILD_ZLIB=0 \
        -DBUILD_TIFF=0 \
        -DBUILD_PNG=0 \
        -DBUILD_OPENEXR=1 \
        -DBUILD_JASPER=0 \
        -DWITH_ITT=1 \
        -DBUILD_JPEG=0 \
        -DBUILD_PROTOBUF=ON \
        -DBUILD_LIBPROTOBUF_FROM_SOURCES=ON \
        -DWITH_V4L=1 \
        -DWITH_OPENCL=0 \
        -DWITH_OPENCLAMDFFT=0 \
        -DWITH_OPENCLAMDBLAS=0 \
        -DWITH_OPENCL_D3D11_NV=0 \
        -DWITH_1394=0 \
        -DWITH_CARBON=0 \
        -DWITH_OPENNI=0 \
        -DWITH_FFMPEG=0 \
        -DHAVE_FFMPEG=0 \
        -DWITH_JASPER=0 \
        -DWITH_VA=0 \
        -DWITH_VA_INTEL=0 \
        -DWITH_GSTREAMER=0 \
        -DWITH_MATLAB=0 \
        -DWITH_TESSERACT=0 \
        -DWITH_VTK=0 \
        -DWITH_GTK=0 \
        -DWITH_QT=0 \
        -DWITH_GPHOTO2=0 \
        -DINSTALL_C_EXAMPLES=0 \
        -DWITH_LAPACK=0 \
        -DHAVE_LAPACK=0 \
        -DLAPACK_LAPACKE_H=${OPENBLAS_PREFIX}/include/lapacke.h \
        -DLAPACK_CBLAS_H=${OPENBLAS_PREFIX}/include/cblas.h"

    # Tag 93 (OpenCV 5.0.0) only: the upstream opencv submodule at this commit
    # includes SgemmKernelpower.h in two DNN source files, but that header was
    # never actually committed to the repo — so the DNN module fails to compile
    # on ppc64le. Disabling DNN is the only workaround until upstream fixes it.
    # Tags 84 and 92 use OpenCV 4.x which does not use this MLAS POWER kernel,
    # so they must NOT have this flag (their wheel build breaks if DNN is off).
    if [[ "${PACKAGE_VERSION}" == "93" ]]; then
        log_info "Tag 93: disabling DNN module (SgemmKernelpower.h missing from upstream repo)"
        export CMAKE_ARGS="${CMAKE_ARGS} -DBUILD_opencv_dnn=OFF"
    fi

    # ------------------------------------------------------------------
    # Build and install
    # --no-build-isolation ensures the venv's numpy C headers are visible
    # ------------------------------------------------------------------
    log_info "Running: python -m pip install . --no-build-isolation"
    if ! python -m pip install . --no-build-isolation; then
        log_error "opencv-python build failed"
        false
    fi

    # ------------------------------------------------------------------
    # Write wheel to dist/ so the template picks it up, runs auditwheel
    # repair, injects SBOM/license metadata, copies to OUTPUT_DIR, and
    # installs the repaired wheel into the test venv.
    # Uses pip wheel (not setup.py bdist_wheel) so it goes through the
    # pyproject.toml / scikit-build backend — compatible with all tags.
    # The _skbuild/ cmake cache from the install step above is reused,
    # so no recompilation occurs.
    # ------------------------------------------------------------------
    log_info "Writing wheel to dist/ for template post-processing..."
    mkdir -p dist
    if ! python -m pip wheel . --no-build-isolation --no-deps -w dist/; then
        log_error "Failed to write wheel to dist/"
        false
    fi

}

# =============================================================================
# CALLBACK: custom_test_command
# Skip test_video_capture: FFmpeg is disabled at build time, so video
# codec tests cannot succeed.
# =============================================================================
custom_test_command() {
    log_info "Running opencv-python tests (skipping test_video_capture)..."
    # test_video_capture: FFmpeg is disabled at build time, video codec tests cannot succeed
    python -m pytest tests/test.py \
        --import-mode=importlib \
        -o "addopts=" \
        -k "not test_video_capture" \
        -v
}

# =============================================================================
# Execute the build
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
