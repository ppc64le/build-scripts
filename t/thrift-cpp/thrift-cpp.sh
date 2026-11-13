#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : thrift-cpp
# Version       : 0.21.0
# Source repo   : https://github.com/apache/thrift
# Tested on     : UBI:9.6
# Language      : C++ / Python Wheel
# Script License: Apache License, Version 2 or later
# Maintainer    : Haritha Nagothu <haritha.nagothu2@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="thrift-cpp"
PACKAGE_VERSION="${1:-0.21.0}"
PACKAGE_URL="https://github.com/apache/thrift"
PYPI_NAME="thriftcpp"

# =============================================================================
# Artifact Declaration
# PROVIDES_ARTIFACT="thrift" registers the installed libs in the artifact
# system so downstream packages (arrow, grpc_cpp) can source_artifact thrift
# =============================================================================
PROVIDES_ARTIFACT="thrift"
BUILD_DEPS="${BUILD_DEPS:-boost}"

# =============================================================================
# REQUIRED: Dependencies
# Note: bison and flex are provided by the base container image
# =============================================================================
# Note: ninja-build added — cmake build is faster and installs libthrift.so
# (unversioned linker symlink) correctly. Autotools with -release uses
# libthrift-VERSION.so naming which FindThriftAlt.cmake cannot locate.
RH_DEP_PKGS="cmake ninja-build git libevent-devel openssl-devel zlib-devel python3 python3-devel python3-pip"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: custom_install
# Compiles thrift C++ library via cmake and prepares python package layout.
# cmake build correctly installs libthrift.so (unversioned symlink) which
# FindThriftAlt.cmake requires. Autotools uses -release naming (libthrift-0.21.0.so)
# with no unversioned symlink, causing FindThriftAlt to fail.
# =============================================================================
custom_install() {
    local SOURCE_DIR
    SOURCE_DIR="$(pwd)"

    # -------------------------------------------------------------------------
    # Stale artifact detection: old pipeline runs left artifacts whose
    # ThriftConfig.cmake had hardcoded build-time paths (/workspace/...).
    # Those paths don't exist at consumer build time, causing set_and_check()
    # to fatal-error when find_package(Thrift) is called by FindThriftAlt.cmake.
    # Detect this by checking for the hardcoded prefix and force a rebuild.
    # -------------------------------------------------------------------------
    local ARTIFACT_DIR_CHECK
    ARTIFACT_DIR_CHECK="$(artifact_dir "${PROVIDES_ARTIFACT}" "${PACKAGE_VERSION}")"
    local thrift_cmake_check="${ARTIFACT_DIR_CHECK}/lib/cmake/thrift/ThriftConfig.cmake"

    if [[ -f "${thrift_cmake_check}" ]]; then
        if grep -q 'set_and_check(THRIFT_INCLUDE_DIR "/' "${thrift_cmake_check}" && \
           ! grep -q 'PACKAGE_PREFIX_DIR' "${thrift_cmake_check}"; then
            log_warn "Detected stale ThriftConfig.cmake with hardcoded paths in ${ARTIFACT_DIR_CHECK}"
            log_warn "Removing stale thrift artifact and rebuilding..."
            rm -rf "${ARTIFACT_DIR_CHECK}"
        elif ! [[ -f "${ARTIFACT_DIR_CHECK}/lib/libthrift.so" ]]; then
            log_warn "Thrift artifact at ${ARTIFACT_DIR_CHECK} is missing libthrift.so — rebuilding"
            rm -rf "${ARTIFACT_DIR_CHECK}"
        else
            log_info "Thrift artifact already exists and is valid at ${ARTIFACT_DIR_CHECK}"
            return 0
        fi
    fi

    local PREFIX_DIR="${SOURCE_DIR}/prefix"
    mkdir -p "${PREFIX_DIR}" build

    local generator="Unix Makefiles"
    command -v ninja >/dev/null 2>&1 && generator="Ninja"

    log_info "Configuring Thrift C++ build with cmake..."
    cd build
    cmake -G "${generator}" \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX="${PREFIX_DIR}" \
        -DCMAKE_INSTALL_LIBDIR=lib \
        -DBUILD_SHARED_LIBS=ON \
        -DBUILD_TESTING=OFF \
        -DBUILD_TUTORIALS=OFF \
        -DWITH_PYTHON=OFF \
        -DWITH_CPP=ON \
        -DWITH_JAVA=OFF \
        -DWITH_JAVASCRIPT=OFF \
        -DWITH_NODEJS=OFF \
        -DWITH_RUBY=OFF \
        -DWITH_KOTLIN=OFF \
        -DWITH_ERLANG=OFF \
        -DWITH_HASKELL=OFF \
        -DWITH_RS=OFF \
        -DWITH_C_GLIB=OFF \
        -DWITH_LIBEVENT=ON \
        -DWITH_OPENSSL=ON \
        -DWITH_ZLIB=ON \
        -DBoost_ROOT="${BOOST_PREFIX:-}" \
        -DBOOST_ROOT="${BOOST_PREFIX:-}" \
        .. || { log_error "CMake configuration failed"; return 1; }

    log_info "Compiling and installing Thrift C++ library..."
    cmake --build . --parallel "$(nproc)" \
        || { log_error "Build failed"; return 1; }
    cmake --install . \
        || { log_error "Install failed"; return 1; }
    cd ..

    # Copy build output to the shared artifact dir so source_artifact thrift works
    local ARTIFACT_DIR
    ARTIFACT_DIR="$(artifact_dir "${PROVIDES_ARTIFACT}" "${PACKAGE_VERSION}")"
    mkdir -p "${ARTIFACT_DIR}"
    cp -r "${PREFIX_DIR}"/* "${ARTIFACT_DIR}/"

    # ThriftConfig.cmake has two bugs that break downstream consumers:
    #
    # 1. Hardcoded build-time absolute paths baked in via @VAR@ substitution.
    #    Fix: replace set_and_check(...) values with ${PACKAGE_PREFIX_DIR}/...
    #
    # 2. find_dependency(Libevent) calls return() on failure (CMake macro
    #    behaviour), which exits ThriftConfig.cmake before the CMAKE_MODULE_PATH
    #    save/restore block can run. This wipes Arrow's cmake_modules/ from
    #    CMAKE_MODULE_PATH, causing find_package(ProtobufAlt) to fail.
    #    Fix: replace find_dependency(Libevent) with find_package(Libevent QUIET)
    #    which never calls return(), so CMAKE_MODULE_PATH is always restored.
    local thrift_cmake_config="${ARTIFACT_DIR}/lib/cmake/thrift/ThriftConfig.cmake"
    if [[ -f "${thrift_cmake_config}" ]]; then
        log_info "Patching ThriftConfig.cmake..."
        sed -i \
            -e 's|set_and_check(THRIFT_INCLUDE_DIR "[^"]*")|set_and_check(THRIFT_INCLUDE_DIR "${PACKAGE_PREFIX_DIR}/include/thrift")|g' \
            -e 's|set_and_check(THRIFT_CMAKE_DIR "[^"]*")|set_and_check(THRIFT_CMAKE_DIR "${PACKAGE_PREFIX_DIR}/lib/cmake/thrift")|g' \
            -e 's|set_and_check(THRIFT_BIN_DIR "[^"]*")|set_and_check(THRIFT_BIN_DIR "${PACKAGE_PREFIX_DIR}/bin")|g' \
            -e 's|find_dependency(Libevent)|find_package(Libevent QUIET)|g' \
            "${thrift_cmake_config}"
    fi

    _generate_env_sh "${ARTIFACT_DIR}" "${PROVIDES_ARTIFACT}" "${PACKAGE_VERSION}"
    generate_artifact_manifest "${ARTIFACT_DIR}" \
        "${PROVIDES_ARTIFACT}" "${PACKAGE_VERSION}" \
        "${PACKAGE_URL}" "${LICENSE_SPDX}" "boost"

    # Export LD_LIBRARY_PATH (including boost prefix) so wheel tools can resolve dependencies
    export LD_LIBRARY_PATH="${PREFIX_DIR}/lib:${BOOST_PREFIX}/lib:${LD_LIBRARY_PATH:-}"

    # Prepare python packaging layout
    log_info "Preparing thriftcpp python packaging layout..."
    mkdir -p local/thriftcpp
    touch local/thriftcpp/__init__.py
    cp -r "${PREFIX_DIR}"/* local/thriftcpp/

    # Clean version string to make it PEP-440 compliant
    local CLEAN_VERSION
    CLEAN_VERSION="${PACKAGE_VERSION//-/.}"

    # Copy pyproject.toml from the script directory and replace the version placeholder
    log_info "Preparing pyproject.toml..."
    if [[ -f "${SCRIPT_DIR}/pyproject.toml" ]]; then
        sed "s/{PACKAGE_VERSION}/${CLEAN_VERSION}/g" "${SCRIPT_DIR}/pyproject.toml" > pyproject.toml
    else
        log_error "Static pyproject.toml template not found in ${SCRIPT_DIR}"
        false
    fi

    # Build wheel into dist/ so template and powercore can collect, repair, and process it
    log_info "Building wheel into dist/..."
    mkdir -p dist
    python -m pip wheel --no-deps -w dist .
    python -m pip install dist/*.whl
}

# =============================================================================
# CALLBACK: custom_test_command — verify imported package
# =============================================================================
custom_test_command() {
    log_info "Verifying thriftcpp package import..."
    python -c "import thriftcpp; print('thriftcpp imported successfully')"
}

# =============================================================================
# Build Configuration
# =============================================================================
BUILD_WHEEL="true"
LICENSE_SPDX="Apache-2.0"

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
