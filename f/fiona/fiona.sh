#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : Fiona
# Version       : 1.10.1
# Source repo   : https://github.com/Toblerity/Fiona
# Tested on     : UBI:9.6
# Language      : Python, Cython
# Script License: Apache License, Version 2 or later
# Maintainer    : Anumala Rajesh <Anumala.Rajesh@ibm.com>
#
# Disclaimer    : This script has been tested in root mode on given
# ==========      platform using the mentioned version of the package.
#                 It may not work as expected with newer versions of the
#                 package and/or distribution. In such case, please
#                 contact "Maintainer" of this script.
#
# Notes:
#   - Fiona requires GDAL, PROJ, and GEOS C libraries built from source
#   - Tests are skipped because tiledb (a test dependency) has CMake issues
#     on ppc64le/ARM architectures
#   - Container environment provides: gcc-toolset-13, cmake, make
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="Fiona"
PACKAGE_VERSION="${1:-1.10.1}"
PACKAGE_URL="https://github.com/Toblerity/Fiona"

# Skip tests - tiledb (test dependency) fails to build with CMake on ppc64le/ARM
SKIP_TESTS="true"

# =============================================================================
# REQUIRED: Dependencies
# System packages needed for building PROJ, GDAL, GEOS, and Fiona
# Note: gcc-toolset-13 provides modern compiler required for GDAL
# =============================================================================
RH_DEP_PKGS="git wget tar unzip make cmake gcc-toolset-13"
RH_DEP_PKGS+=" sqlite sqlite-devel libtiff libtiff-devel libcurl-devel curl-devel"
RH_DEP_PKGS+=" libjpeg-devel freetype-devel zlib zlib-devel libpng libpng-devel"
RH_DEP_PKGS+=" json-c libjpeg-turbo libjpeg-turbo-devel libomp-devel zip"
RH_DEP_PKGS+=" openssl-devel bzip2-devel libffi-devel meson ninja-build"
RH_DEP_PKGS+=" gcc-gfortran openblas-devel python3-devel python3-pip"

DEB_DEP_PKGS="git wget tar unzip make cmake build-essential"
DEB_DEP_PKGS+=" libsqlite3-dev libtiff-dev libcurl4-openssl-dev"
DEB_DEP_PKGS+=" libjpeg-dev libfreetype6-dev zlib1g-dev libpng-dev"
DEB_DEP_PKGS+=" libjson-c-dev libomp-dev zip"
DEB_DEP_PKGS+=" libssl-dev libbz2-dev libffi-dev meson ninja-build"
DEB_DEP_PKGS+=" gfortran libopenblas-dev python3-dev python3-pip python3-venv"

SLES_DEP_PKGS="git wget tar unzip make cmake gcc gcc-c++"
SLES_DEP_PKGS+=" sqlite3-devel libtiff-devel libcurl-devel"
SLES_DEP_PKGS+=" libjpeg-devel freetype-devel zlib-devel libpng-devel"
SLES_DEP_PKGS+=" libjson-c-devel libomp-devel zip"
SLES_DEP_PKGS+=" libopenssl-devel libbz2-devel libffi-devel meson ninja"
SLES_DEP_PKGS+=" gcc-fortran openblas-devel python3-devel python3-pip"

# Future dependency system
# BUILD_DEPS="proj gdal geos"
# Note: PROJ, GDAL, GEOS built from source in custom_install

# =============================================================================
# Version configuration for C library dependencies
# =============================================================================
PROJ_VERSION="9.4.0"
GDAL_VERSION="3.7.1"

# =============================================================================
# CALLBACK: pre_clone
# Set up gcc-toolset-13 compiler environment (Red Hat only)
# =============================================================================
pre_clone() {
    log_info "Setting up build environment..."

    # Enable gcc-toolset-13 on RHEL/UBI
    if [[ -f "/opt/rh/gcc-toolset-13/enable" ]]; then
        source /opt/rh/gcc-toolset-13/enable
        export PATH="/opt/rh/gcc-toolset-13/root/usr/bin:$PATH"
    fi

    export CC=$(which gcc)
    export CXX=$(which g++)

    log_info "Using compiler: $(gcc --version | head -1)"
}

# =============================================================================
# CALLBACK: custom_install
# Build PROJ, GDAL, and GEOS from source, then build Fiona
# =============================================================================
custom_install() {
    local BUILD_PREFIX="/usr/local/src"
    local ARTIFACT_DIR="${OUTPUT_DIR:-/tmp}/artifacts"
    local FIONA_DIR="$(pwd)"  # Save Fiona repo directory (we're inside it)

    # Ensure gcc-toolset-13 is enabled
    if [[ -f "/opt/rh/gcc-toolset-13/enable" ]]; then
        source /opt/rh/gcc-toolset-13/enable
        export PATH="/opt/rh/gcc-toolset-13/root/usr/bin:$PATH"
    fi
    export CC=$(which gcc)
    export CXX=$(which g++)

    # =========================================================================
    # Build PROJ
    # =========================================================================
    local PROJ_PREFIX="${ARTIFACT_DIR}/proj"

    if [[ -f "${PROJ_PREFIX}/env.sh" ]]; then
        log_info "Found existing PROJ artifact, sourcing environment..."
        source "${PROJ_PREFIX}/env.sh"
    else
        log_info "Building PROJ ${PROJ_VERSION}..."
        cd "${BUILD_PREFIX}"

        if [[ ! -f "proj-${PROJ_VERSION}.tar.gz" ]]; then
            wget "https://download.osgeo.org/proj/proj-${PROJ_VERSION}.tar.gz"
        fi
        tar -xzf "proj-${PROJ_VERSION}.tar.gz"
        cd "proj-${PROJ_VERSION}"

        mkdir -p build && cd build
        cmake .. -DCMAKE_INSTALL_PREFIX="$PROJ_PREFIX" -DCMAKE_EXE_LINKER_FLAGS="-lm"
        make -j$(nproc)
        make install
        ldconfig

        # Create env.sh for artifact reuse
        cat > "${PROJ_PREFIX}/env.sh" << EOF
export PROJ_DIR="${PROJ_PREFIX}"
export PROJ_LIB="${PROJ_PREFIX}/share/proj"
export PKG_CONFIG_PATH="${PROJ_PREFIX}/lib64/pkgconfig:${PROJ_PREFIX}/lib/pkgconfig:\${PKG_CONFIG_PATH:-}"
export LD_LIBRARY_PATH="${PROJ_PREFIX}/lib64:${PROJ_PREFIX}/lib:\${LD_LIBRARY_PATH:-}"
EOF
        log_info "Created ${PROJ_PREFIX}/env.sh for artifact reuse"
        source "${PROJ_PREFIX}/env.sh"
        log_info "PROJ installed successfully"
    fi

    # =========================================================================
    # Build GDAL
    # =========================================================================
    local GDAL_PREFIX="${ARTIFACT_DIR}/gdal"

    if [[ -f "${GDAL_PREFIX}/env.sh" ]]; then
        log_info "Found existing GDAL artifact, sourcing environment..."
        source "${GDAL_PREFIX}/env.sh"
    else
        log_info "Building GDAL ${GDAL_VERSION}..."
        cd "${BUILD_PREFIX}"

        if [[ ! -f "gdal-${GDAL_VERSION}.tar.gz" ]]; then
            wget "https://github.com/OSGeo/gdal/releases/download/v${GDAL_VERSION}/gdal-${GDAL_VERSION}.tar.gz"
        fi
        tar -xzf "gdal-${GDAL_VERSION}.tar.gz"
        cd "gdal-${GDAL_VERSION}"

        mkdir -p build && cd build
        cmake .. \
            -DCMAKE_INSTALL_PREFIX="$GDAL_PREFIX" \
            -DCMAKE_BUILD_TYPE=Release \
            -DGDAL_USE_PROJ=ON \
            -DPROJ_INCLUDE_DIR="${PROJ_PREFIX}/include" \
            -DPROJ_LIBRARY="${PROJ_PREFIX}/lib/libproj.so" \
            -DGDAL_USE_PNG=ON \
            -DGDAL_USE_GEOTIFF_INTERNAL=ON \
            -DGDAL_USE_JSONC_INTERNAL=ON

        make -j$(nproc)
        make install

        # Configure library paths
        echo "${GDAL_PREFIX}/lib64" > /etc/ld.so.conf.d/gdal.conf 2>/dev/null || true
        ldconfig

        # Create env.sh for artifact reuse
        cat > "${GDAL_PREFIX}/env.sh" << EOF
export PKG_CONFIG_PATH="${GDAL_PREFIX}/lib64/pkgconfig:${GDAL_PREFIX}/lib/pkgconfig:\${PKG_CONFIG_PATH:-}"
export LD_LIBRARY_PATH="${GDAL_PREFIX}/lib64:${GDAL_PREFIX}/lib:\${LD_LIBRARY_PATH:-}"
export GDAL_CONFIG="${GDAL_PREFIX}/bin/gdal-config"
EOF
        log_info "Created ${GDAL_PREFIX}/env.sh for artifact reuse"
        source "${GDAL_PREFIX}/env.sh"
        log_info "GDAL version: $("${GDAL_PREFIX}/bin/gdalinfo" --version)"
    fi

    # =========================================================================
    # Build GEOS
    # =========================================================================
    local GEOS_PREFIX="${ARTIFACT_DIR}/geos"

    if [[ -f "${GEOS_PREFIX}/env.sh" ]]; then
        log_info "Found existing GEOS artifact, sourcing environment..."
        source "${GEOS_PREFIX}/env.sh"
    else
        log_info "Building GEOS (latest from git)..."
        cd "${BUILD_PREFIX}"

        if [[ ! -d "geos" ]]; then
            git clone https://github.com/libgeos/geos.git
        fi
        cd geos

        mkdir -p build && cd build
        cmake .. -DCMAKE_INSTALL_PREFIX="$GEOS_PREFIX"
        make -j$(nproc)
        make install

        # Configure library paths
        echo "${GEOS_PREFIX}/lib64" > /etc/ld.so.conf.d/geos.conf 2>/dev/null || true
        ldconfig

        # Create env.sh for artifact reuse
        cat > "${GEOS_PREFIX}/env.sh" << EOF
export GEOS_INCLUDE_DIR="${GEOS_PREFIX}/include"
export GEOS_LIBRARY="${GEOS_PREFIX}/lib64/libgeos_c.so"
export GEOS_CONFIG="${GEOS_PREFIX}/bin/geos-config"
export LD_LIBRARY_PATH="${GEOS_PREFIX}/lib64:${GEOS_PREFIX}/lib:\${LD_LIBRARY_PATH:-}"
export PKG_CONFIG_PATH="${GEOS_PREFIX}/lib64/pkgconfig:${GEOS_PREFIX}/lib/pkgconfig:\${PKG_CONFIG_PATH:-}"
EOF
        log_info "Created ${GEOS_PREFIX}/env.sh for artifact reuse"
        source "${GEOS_PREFIX}/env.sh"
        log_info "GEOS version: $("${GEOS_CONFIG}" --version)"
    fi

    # =========================================================================
    # Build Fiona
    # =========================================================================
    log_info "Building Fiona..."
    cd "${FIONA_DIR}"

    # Create virtual environment
    ${PYTHON_VERSION} -m venv .venv-build
    source .venv-build/bin/activate

    # Install build dependencies
    pip install --upgrade pip setuptools wheel
    pip install "Cython~=3.0.2" numpy oldest-supported-numpy build

    # Set numpy include path for Cython extensions
    export CFLAGS="-I$(python -c 'import numpy; print(numpy.get_include())') $CFLAGS"

    # Install pyproj (needs PROJ)
    pip install pyproj
    python -c "import pyproj; print('pyproj version:', pyproj.__version__)"

    # Install dev dependencies if available
    if [[ -f "requirements-dev.txt" ]]; then
        pip install -r requirements-dev.txt || log_warn "Some dev deps failed - continuing"
    fi

    # Build extensions
    log_info "Building Cython extensions..."
    python setup.py build_ext --inplace

    # Install the package
    log_info "Installing Fiona..."
    if ! pip install .; then
        deactivate
        return 1
    fi

    # Verify installation
    python -c "import fiona; print('Fiona version:', fiona.__version__)"

    deactivate
    return 0
}

# =============================================================================
# Source the Python template to execute the build workflow
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
