#!/bin/bash
# =============================================================================
# base.sh - Invocable Native C/C++ Library Build Template
# =============================================================================
# This template is SOURCED by user build scripts, not executed directly.
# It provides the standard native library build workflow with callback hooks
# for customization and automatic build system detection.
#
# REQUIRED variables (must be set before sourcing):
#   PACKAGE_NAME     - Name of the package
#   PACKAGE_VERSION  - Version to build (usually from $1)
#   PACKAGE_URL      - Git repository URL
#   PROVIDES_ARTIFACT - Artifact name this package provides
#   RH_DEP_PKGS      - Red Hat/Fedora dependencies
#   DEB_DEP_PKGS     - Debian/Ubuntu dependencies (optional)
#   SLES_DEP_PKGS    - SUSE dependencies (optional)
#
# OPTIONAL variables:
#   CLONE_DIR        - Directory name for clone (default: PACKAGE_NAME)
#   SKIP_TESTS       - Set to "true" to skip test phase
#   BUILD_DEPS       - Space-separated artifact dependencies (e.g., "protobuf:v25.3 hdf5")
#   LICENSE_FILE     - Name of license file (default: auto-detect)
#   LICENSE_SPDX     - SPDX license identifier (default: "UNKNOWN")
#   ARTIFACT_VERSION - Version string for artifact (default: PACKAGE_VERSION stripped of 'v' prefix)
#
# BUILD SYSTEM CONFIG (optional - overrides auto-detection):
#   BUILD_SYSTEM     - Force build system: "autoconf", "cmake", "meson", "make"
#   CONFIGURE_OPTS   - Extra options for ./configure (autoconf)
#   CMAKE_OPTS       - Extra options for cmake (cmake)
#   MESON_OPTS       - Extra options for meson setup (meson)
#   MAKE_OPTS        - Extra options for make
#   MAKE_TARGET      - Custom make target (default: empty, uses default target)
#   INSTALL_TARGET   - Custom install target (default: "install")
#
# CALLBACK HOOKS (define as functions before sourcing):
#   pre_packages()         - Before package install (add extra repos)
#   pre_clone()            - Before git clone (extra deps, environment)
#   post_clone()           - After checkout (apply patches, modify source)
#   pre_build()            - Before build (environment setup)
#   post_build()           - After build, before test (verification)
#   custom_install()       - Override entire build+install logic
#   custom_test_command()  - Override default test logic
#   post_test()            - After tests pass (cleanup, artifacts)
#
# EXIT CODES:
#   0 - Success (build and test passed, or build passed with no tests)
#   1 - Clone or install failure
#   2 - Test failure (install succeeded)
#   3 - Artifact packaging failure
# =============================================================================

# Ensure we're being sourced, not executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "ERROR: This script must be sourced, not executed directly."
    echo "Usage: source \"\${SCRIPT_DIR}/../templates/base.sh\""
    exit 1
fi

# =============================================================================
# SOURCE COMMON LIBRARIES
# =============================================================================
# SCRIPT_DIR should be set by the sourcing script
if [[ -z "${SCRIPT_DIR}" ]]; then
    echo "ERROR: SCRIPT_DIR must be set before sourcing this template"
    exit 1
fi

# Determine template directory (where this file lives)
TEMPLATE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${TEMPLATE_DIR}/lib/common.sh"
source "${TEMPLATE_DIR}/lib/distro-packages.sh"
source "${TEMPLATE_DIR}/lib/automation-stanzas.sh"
source "${TEMPLATE_DIR}/lib/artifacts.sh"
source "${TEMPLATE_DIR}/lib/container.sh"

# =============================================================================
# VALIDATE REQUIRED VARIABLES
# =============================================================================
validate_required_vars PACKAGE_NAME PACKAGE_VERSION PACKAGE_URL PROVIDES_ARTIFACT

# =============================================================================
# CONTAINER-ONLY MODE
# Skip build/test and just build the container image
# Usage: CONTAINER_ONLY=1 ./package.sh version
# =============================================================================
if [[ "${CONTAINER_ONLY:-}" == "1" ]]; then
    log_info "Container-only mode: skipping build and tests"
    if [[ ! -f "${SCRIPT_DIR}/Dockerfile" ]]; then
        log_error "No Dockerfile found at ${SCRIPT_DIR}/Dockerfile"
        exit 1
    fi
    container_only_build "${SCRIPT_DIR}"
    exit $?
fi

# Set defaults for optional variables
: ${CLONE_DIR:="$PACKAGE_NAME"}
: ${SKIP_TESTS:="false"}
: ${LICENSE_SPDX:="UNKNOWN"}

# Strip 'v' prefix from version for artifact directory by default
: ${ARTIFACT_VERSION:="${PACKAGE_VERSION#v}"}

# Build system defaults (empty = auto-detect)
: ${BUILD_SYSTEM:=""}
: ${CONFIGURE_OPTS:=""}
: ${CMAKE_OPTS:=""}
: ${MESON_OPTS:=""}
: ${MAKE_OPTS:=""}
: ${MAKE_TARGET:=""}
: ${INSTALL_TARGET:="install"}

# =============================================================================
# HELPER: Check if callback function exists
# =============================================================================
_has_callback() {
    type -t "$1" 2>/dev/null | grep -q "function"
}

# =============================================================================
# BUILD SYSTEM DETECTION
# =============================================================================
# Detects the build system based on files present in the source directory.
# Priority order:
#   1. configure (pre-generated autoconf) - highest priority
#   2. configure.ac or configure.in (autoconf requiring autoreconf)
#   3. CMakeLists.txt (cmake)
#   4. meson.build (meson)
#   5. Makefile (plain make) - lowest priority
#
# Returns detected build system via echo. Caller should capture with $()
# =============================================================================
_detect_build_system() {
    # If user explicitly set BUILD_SYSTEM, use it
    if [[ -n "${BUILD_SYSTEM}" ]]; then
        echo "${BUILD_SYSTEM}"
        return 0
    fi

    # Priority 1: Pre-generated configure script (ready to use)
    if [[ -x "./configure" ]]; then
        echo "autoconf"
        return 0
    fi

    # Priority 2: Autoconf (requires autoreconf to generate configure)
    if [[ -f "./configure.ac" ]] || [[ -f "./configure.in" ]]; then
        echo "autoconf"
        return 0
    fi

    # Priority 3: CMake
    if [[ -f "./CMakeLists.txt" ]]; then
        echo "cmake"
        return 0
    fi

    # Priority 4: Meson
    if [[ -f "./meson.build" ]]; then
        echo "meson"
        return 0
    fi

    # Priority 5: Plain Makefile (fallback)
    if [[ -f "./Makefile" ]] || [[ -f "./makefile" ]] || [[ -f "./GNUmakefile" ]]; then
        echo "make"
        return 0
    fi

    # No recognized build system
    echo "unknown"
    return 1
}

# =============================================================================
# AUTOCONF BUILD
# =============================================================================
# Handles autoconf-based builds:
#   1. Runs autoreconf if configure doesn't exist
#   2. Runs ./configure with standard prefix and user options
#   3. Runs make && make install
# =============================================================================
_build_autoconf() {
    local prefix="$1"

    log_info "Building with autoconf (configure && make)"

    # Generate configure if it doesn't exist
    if [[ ! -x "./configure" ]]; then
        log_info "Running autoreconf to generate configure script"
        if [[ -f "./autogen.sh" ]]; then
            ./autogen.sh || return $?
        else
            autoreconf -fiv || return $?
        fi
    fi

    # Run configure with prefix and user options
    # shellcheck disable=SC2086
    ./configure \
        --prefix="${prefix}" \
        ${CONFIGURE_OPTS} || return $?

    # Build
    # shellcheck disable=SC2086
    make -j"$(nproc)" ${MAKE_TARGET} ${MAKE_OPTS} || return $?

    # Install
    # shellcheck disable=SC2086
    make ${INSTALL_TARGET} || return $?
}

# =============================================================================
# CMAKE BUILD
# =============================================================================
# Handles CMake-based builds:
#   1. Creates build directory
#   2. Runs cmake with standard options and user options
#   3. Runs cmake --build && cmake --install
# =============================================================================
_build_cmake() {
    local prefix="$1"

    log_info "Building with cmake"

    # Create build directory
    mkdir -p build
    cd build || return 1

    # Configure with cmake
    # Standard options:
    #   -DCMAKE_INSTALL_PREFIX: Install location
    #   -DCMAKE_BUILD_TYPE=Release: Optimized build
    #   -DBUILD_SHARED_LIBS=ON: Build shared libraries
    #   -DCMAKE_POSITION_INDEPENDENT_CODE=ON: Required for shared libs
    # shellcheck disable=SC2086
    if ! cmake .. \
        -DCMAKE_INSTALL_PREFIX="${prefix}" \
        -DCMAKE_BUILD_TYPE=Release \
        -DBUILD_SHARED_LIBS=ON \
        -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
        ${CMAKE_OPTS}; then
        cd ..
        return 1
    fi

    # Build
    if ! cmake --build . --parallel "$(nproc)"; then
        cd ..
        return 1
    fi

    # Install
    if ! cmake --install .; then
        cd ..
        return 1
    fi

    # Return to source directory
    cd ..
}

# =============================================================================
# MESON BUILD
# =============================================================================
# Handles Meson-based builds:
#   1. Runs meson setup with standard options
#   2. Runs meson compile
#   3. Runs meson install
# =============================================================================
_build_meson() {
    local prefix="$1"

    log_info "Building with meson"

    # Configure with meson
    # Standard options:
    #   --prefix: Install location
    #   --buildtype=release: Optimized build
    #   --default-library=shared: Build shared libraries
    # shellcheck disable=SC2086
    meson setup builddir \
        --prefix="${prefix}" \
        --buildtype=release \
        --default-library=shared \
        ${MESON_OPTS} || return $?

    # Build
    meson compile -C builddir || return $?

    # Install
    meson install -C builddir || return $?
}

# =============================================================================
# PLAIN MAKE BUILD
# =============================================================================
# Handles plain Makefile builds:
#   1. Runs make with PREFIX set
#   2. Runs make install
#
# Note: This is a fallback. Many Makefiles don't support PREFIX.
# Consider using custom_install() for non-standard Makefiles.
# =============================================================================
_build_make() {
    local prefix="$1"

    log_info "Building with plain make"

    # Build with prefix
    # shellcheck disable=SC2086
    make -j"$(nproc)" PREFIX="${prefix}" ${MAKE_TARGET} ${MAKE_OPTS} || return $?

    # Install
    # shellcheck disable=SC2086
    make PREFIX="${prefix}" ${INSTALL_TARGET} || return $?
}

# Standard artifact helpers are now globally defined and inherited from templates/lib/artifacts.sh

# =============================================================================
# SOURCE BUILD DEPENDENCIES
# =============================================================================
# If BUILD_DEPS is set, source each dependency's env.sh to make it available
# during the build. Format: "name:version name2" or just "name name2"
# =============================================================================
_source_build_deps() {
    if [[ -z "${BUILD_DEPS:-}" ]]; then
        return 0
    fi

    log_info "Sourcing build dependencies: ${BUILD_DEPS}"

    for dep in ${BUILD_DEPS}; do
        local dep_name="${dep%%:*}"
        local dep_version=""
        if [[ "${dep}" == *":"* ]]; then
            dep_version="${dep#*:}"
        fi

        if ! source_artifact "${dep_name}" "${dep_version}"; then
            log_error "Failed to source dependency: ${dep}"
            report_dependency_fail
        fi
    done
}

# =============================================================================
# DEFAULT BUILD FUNCTION
# =============================================================================
# The main build logic that:
#   1. Detects build system
#   2. Runs the appropriate build commands
#   3. Generates env.sh and manifest
#   4. Cleans up the artifact
# =============================================================================
_default_build() {
    local ARTIFACT_DIR
    ARTIFACT_DIR="$(artifact_dir "${PROVIDES_ARTIFACT}" "${ARTIFACT_VERSION}")"

    # Check if already built
    if [[ -f "${ARTIFACT_DIR}/env.sh" ]]; then
        log_info "Artifact already exists at ${ARTIFACT_DIR}"
        return 0
    fi

    log_info "Building ${PACKAGE_NAME} ${PACKAGE_VERSION} to ${ARTIFACT_DIR}"
    mkdir -p "${ARTIFACT_DIR}"

    # Detect build system
    local build_system
    build_system="$(_detect_build_system)"

    if [[ "${build_system}" == "unknown" ]]; then
        log_error "Could not detect build system. No configure, CMakeLists.txt, meson.build, or Makefile found."
        log_error "Define custom_install() to handle this package's build system."
        report_build_fail
    fi

    log_info "Detected build system: ${build_system}"

    # Run the appropriate build
    local build_status=0
    case "${build_system}" in
        autoconf)
            _build_autoconf "${ARTIFACT_DIR}" || build_status=$?
            ;;
        cmake)
            _build_cmake "${ARTIFACT_DIR}" || build_status=$?
            ;;
        meson)
            _build_meson "${ARTIFACT_DIR}" || build_status=$?
            ;;
        make)
            _build_make "${ARTIFACT_DIR}" || build_status=$?
            ;;
        *)
            log_error "Unknown build system: ${build_system}"
            report_build_fail
            ;;
    esac

    if [[ ${build_status} -ne 0 ]]; then
        log_error "Build compilation/installation failed with exit code ${build_status}"
        return ${build_status}
    fi

    # Post-build cleanup
    _cleanup_artifact "${ARTIFACT_DIR}"

    # Copy license file
    _copy_license "${ARTIFACT_DIR}"

    # Generate env.sh
    _generate_env_sh "${ARTIFACT_DIR}" "${PROVIDES_ARTIFACT}" "${ARTIFACT_VERSION}"

    # Generate manifest with dependencies
    local deps_array=()
    if [[ -n "${BUILD_DEPS:-}" ]]; then
        for dep in ${BUILD_DEPS}; do
            deps_array+=("${dep}")
        done
    fi

    generate_artifact_manifest "${ARTIFACT_DIR}" \
        "${PROVIDES_ARTIFACT}" "${ARTIFACT_VERSION}" \
        "${PACKAGE_URL}" "${LICENSE_SPDX}" \
        "${deps_array[@]}"

    log_info "Build complete: ${ARTIFACT_DIR}"
}

# =============================================================================
# DEFAULT TEST FUNCTION
# =============================================================================
# Runs basic verification tests:
#   1. Check that shared libraries exist and are loadable
#   2. Check that pkg-config files work (if present)
#   3. Run make check/test if available
# =============================================================================
_default_test() {
    local ARTIFACT_DIR
    ARTIFACT_DIR="$(artifact_dir "${PROVIDES_ARTIFACT}" "${ARTIFACT_VERSION}")"

    # Source our own env.sh to set up paths
    source "${ARTIFACT_DIR}/env.sh"

    log_info "Running basic artifact verification"

    # Check for shared libraries
    local lib_count=0
    for lib in "${ARTIFACT_DIR}"/lib/*.so* "${ARTIFACT_DIR}"/lib64/*.so*; do
        if [[ -f "${lib}" ]]; then
            ((lib_count++))
            log_info "Found library: $(basename "${lib}")"
        fi
    done

    if [[ ${lib_count} -eq 0 ]]; then
        log_warn "No shared libraries found in artifact"
    else
        log_info "Found ${lib_count} shared library files"
    fi

    # Check pkg-config if available
    local pc_file
    for pc_file in "${ARTIFACT_DIR}"/lib/pkgconfig/*.pc "${ARTIFACT_DIR}"/lib64/pkgconfig/*.pc; do
        if [[ -f "${pc_file}" ]]; then
            local pc_name
            pc_name="$(basename "${pc_file}" .pc)"
            log_info "Verifying pkg-config: ${pc_name}"
            if pkg-config --exists "${pc_name}"; then
                log_info "  pkg-config ${pc_name}: OK"
                log_info "  Version: $(pkg-config --modversion "${pc_name}")"
                log_info "  Cflags: $(pkg-config --cflags "${pc_name}")"
                log_info "  Libs: $(pkg-config --libs "${pc_name}")"
            else
                log_warn "  pkg-config ${pc_name}: FAILED"
            fi
        fi
    done

    log_info "Basic verification complete"
    return 0
}

# =============================================================================
# INITIALIZATION
# =============================================================================
detect_os

log_info "======================================================================"
log_info "Building $PACKAGE_NAME version $PACKAGE_VERSION"
log_info "Provides artifact: $PROVIDES_ARTIFACT"
log_info "OS: $OS_NAME"
log_info "======================================================================"

# =============================================================================
# CALLBACK: pre_packages (add extra repos before package install)
# =============================================================================
if _has_callback pre_packages; then
    log_info "Running pre_packages hook..."
    pre_packages
fi

# =============================================================================
# INSTALL DEPENDENCIES
# =============================================================================
install_packages

# =============================================================================
# SOURCE BUILD DEPENDENCIES
# =============================================================================
_source_build_deps

# =============================================================================
# CALLBACK: pre_clone
# =============================================================================
if _has_callback pre_clone; then
    log_info "Running pre_clone hook..."
    if ! pre_clone; then
        log_error "pre_clone hook failed"
        report_install_fail
    fi
fi

# =============================================================================
# CLONE REPOSITORY
# =============================================================================
clone_repository

# Save the source directory for later use (tests may need it)
SOURCE_DIR="${PWD}"
export SOURCE_DIR

# =============================================================================
# CALLBACK: post_clone (patches, source modifications)
# =============================================================================
if _has_callback post_clone; then
    log_info "Running post_clone hook..."
    if ! post_clone; then
        log_error "post_clone hook failed"
        report_install_fail
    fi
fi

# =============================================================================
# CALLBACK: pre_build (environment setup)
# =============================================================================
if _has_callback pre_build; then
    log_info "Running pre_build hook..."
    if ! pre_build; then
        log_error "pre_build hook failed"
        report_install_fail
    fi
fi

# =============================================================================
# BUILD / INSTALL
# =============================================================================
if _has_callback custom_install; then
    log_info "Running custom_install hook..."
    if ! custom_install; then
        report_build_fail
    fi
else
    # Use default auto-detecting build
    if ! _default_build; then
        report_build_fail
    fi
fi

# =============================================================================
# CALLBACK: post_build (verification)
# =============================================================================
if _has_callback post_build; then
    log_info "Running post_build hook..."
    post_build
fi

# =============================================================================
# TEST PHASE
# =============================================================================
if [[ "$SKIP_TESTS" == "true" ]]; then
    log_info "Tests skipped (SKIP_TESTS=true)"
    # Container build before exit (report_install_only_success exits the script)
    if _should_build_container "${SCRIPT_DIR}"; then
        build_container "${PACKAGE_VERSION}" "${SCRIPT_DIR}/Dockerfile"
    fi
    report_install_only_success
fi

log_info "Running tests"

test_status=0

if _has_callback custom_test_command; then
    log_info "Running custom_test_command hook..."
    custom_test_command && test_status=0 || test_status=$?
else
    # Use default verification tests
    _default_test && test_status=0 || test_status=$?
fi

# =============================================================================
# CALLBACK: post_test
# =============================================================================
if _has_callback post_test; then
    log_info "Running post_test hook..."
    post_test
fi

# =============================================================================
# CONTAINER BUILD (optional)
# Build container image if:
#   - Dockerfile exists in package directory
#   - docker_build: true in build_info.json OR BUILD_CONTAINER=1
#   - Build and tests passed (test_status == 0)
# =============================================================================
if [[ $test_status -eq 0 ]] && _should_build_container "${SCRIPT_DIR}"; then
    build_container "${PACKAGE_VERSION}" "${SCRIPT_DIR}/Dockerfile"
fi

# =============================================================================
# REPORT RESULTS
# =============================================================================
if [[ $test_status -eq 0 ]]; then
    report_build_test_success
else
    report_build_success_test_fail
fi
