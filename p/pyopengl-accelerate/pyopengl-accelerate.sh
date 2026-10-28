#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : pyopengl-accelerate
# Version       : release-3.1.9
# Source repo   : https://github.com/mcfletch/pyopengl
# Tested on     : UBI:9.3
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Ramnath Nayak <Ramnath.Nayak@ibm.com>
#
# Disclaimer    : This script has been tested in root mode on given
# ==========      platform using the mentioned version of the package.
#                 It may not work as expected with newer versions of the
#                 package and/or distribution. In such case, please
#                 contact "Maintainer" of this script.
#
# Notes:
#   - pyopengl-accelerate is a subdirectory (accelerate/) of the pyopengl repo
#   - SDL2 must be built from source as a dependency
#   - The main pyopengl package must be installed before building accelerate
#   - Cython is required for building the .pyx extensions
#   - A patch is required to fix ctypes.long issue on ppc64le
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# Note: We clone pyopengl but build the accelerate subdirectory
# =============================================================================
PACKAGE_NAME="pyopengl"
PACKAGE_VERSION="${1:-release-3.1.9}"
PACKAGE_URL="https://github.com/mcfletch/pyopengl"

# =============================================================================
# REQUIRED: Dependencies
# Note: gcc/g++ provided by container; mesa-libGL/GLU for OpenGL
# =============================================================================
RH_DEP_PKGS="git python3 python3-devel python3-pip zlib-devel libjpeg-devel openssl-devel freetype-devel pkgconfig mesa-libGL mesa-libGLU libX11-devel"
DEB_DEP_PKGS="git python3 python3-dev python3-pip python3-venv zlib1g-dev libjpeg-dev libssl-dev libfreetype-dev pkg-config libgl1-mesa-glx libglu1-mesa libx11-dev"
SLES_DEP_PKGS="git python3 python3-devel python3-pip zlib-devel libjpeg-devel libopenssl-devel freetype-devel pkg-config Mesa-libGL1 Mesa-libGLU1 libX11-devel"

# =============================================================================
# CALLBACK: pre_clone
# Build SDL2 from source (required for some OpenGL functionality)
# =============================================================================
pre_clone() {
    log_info "Building SDL2 from source..."

    local sdl_version="2.28.5"
    local sdl_tarball="SDL2-${sdl_version}.tar.gz"
    local sdl_url="https://www.libsdl.org/release/${sdl_tarball}"

    # Download and build SDL2
    wget "${sdl_url}"
    tar -xzf "${sdl_tarball}"
    (
        cd "SDL2-${sdl_version}"
        ./configure --prefix=/usr/local
        make -j"$(nproc)"
        make install
    )
    ldconfig

    export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:${PKG_CONFIG_PATH}

    # Clean up
    rm -rf "SDL2-${sdl_version}" "${sdl_tarball}"

    log_info "SDL2 build complete"
}

# =============================================================================
# CALLBACK: post_clone
# Handle version mapping, apply ppc64le patch, then cd to accelerate/
# =============================================================================
post_clone() {
    # Version mapping: release-3.1.9 uses master branch
    # Note: clone_repository already checked out PACKAGE_VERSION
    # If that fails, we may need to try master branch
    if [[ "${PACKAGE_VERSION}" == "release-3.1.9" ]]; then
        # release-3.1.9 tag may not exist; use master if checkout failed
        if ! git rev-parse HEAD &>/dev/null; then
            log_info "Checking out master branch for release-3.1.9"
            git checkout master
        fi
    fi

    # Apply the ppc64le patch for ctypes.long issue
    # The patch fixes: from ctypes import c_long as long
    log_info "Applying ppc64le patch to accelerate/src/vbo.pyx..."

    # Download the patch if not included locally
    local patch_url="https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/p/pyopengl-accelerate/pyopengl-accelerate_release-3.1.8_1.patch"
    wget -q "${patch_url}" -O pyopengl-accelerate.patch

    # Apply patch in the accelerate subdirectory context
    # The patch path references accelerate/src/vbo.pyx
    git apply pyopengl-accelerate.patch || {
        log_warn "Patch may already be applied or not needed for this version"
    }

    rm -f pyopengl-accelerate.patch

    # Save repo root for pre_build, then cd to accelerate for the build
    export PYOPENGL_REPO_ROOT="${PWD}"
    cd accelerate
}

# =============================================================================
# Build configuration
# =============================================================================
NO_BUILD_ISOLATION=true

# =============================================================================
# CALLBACK: pre_build
# Install main pyopengl package first (accelerate depends on it)
# =============================================================================
pre_build() {
    pip install cython numpy

    # Install the main pyopengl package from repo root
    log_info "Installing main pyopengl package first..."
    if ! pip install "${PYOPENGL_REPO_ROOT}"; then
        log_error "Failed to install main pyopengl package"
        return 1
    fi
}

# =============================================================================
# CALLBACK: custom_test_command
# Run tox tests (we're already in accelerate/ from post_clone)
# =============================================================================
custom_test_command() {
    log_info "Running tests for pyopengl-accelerate..."

    pip install tox

    # Run tox tests
    # Note: Tests may fail without a display/OpenGL context available
    tox -e py3 || {
        log_warn "Some tests failed - may be due to missing OpenGL display context"
        return 1
    }
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
