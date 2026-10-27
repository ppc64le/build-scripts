#!/bin/bash
# =============================================================================
# python.sh - Invocable Python Build Template
# =============================================================================
# This template is SOURCED by user build scripts, not executed directly.
# It provides the standard Python build workflow with callback hooks for
# customization.
#
# REQUIRED variables (must be set before sourcing):
#   PACKAGE_NAME    - Name of the package
#   PACKAGE_VERSION - Version to build (usually from $1)
#   PACKAGE_URL     - Git repository URL
#   RH_DEP_PKGS     - Red Hat/Fedora dependencies
#   DEB_DEP_PKGS    - Debian/Ubuntu dependencies (optional)
#   SLES_DEP_PKGS   - SUSE dependencies (optional)
#
# OPTIONAL variables:
#   PYTHON_VERSION    - Python version number (e.g., "3.11") set by entrypoint for compatibility checks
#   CLONE_DIR         - Directory name for clone (default: PACKAGE_NAME)
#   SKIP_TESTS        - Set to "true" to skip test phase
#   NOARCH            - Set to "true" to install from PyPI instead of building
#   PYPI_NAME         - PyPI package name if different from PACKAGE_NAME
#   BUILD_WHEEL       - Set to "true" to build wheel artifact after tests
#   OUTPUT_DIR        - Directory for wheel output (default: current dir)
#   WHEEL_CLASSIFIERS - Array of classifiers to add to wheel metadata
#
# CALLBACK HOOKS (define as functions before sourcing):
#   pre_packages()         - Before package install (add extra repos)
#   pre_clone()            - Before git clone (extra deps, environment)
#   post_clone()           - After checkout (apply patches, modify source)
#   pre_build()            - Before pip install (environment setup)
#   post_build()           - After install, before test (verification)
#   pre_test()             - Before tests run (setup env, install test deps)
#   custom_test_command()  - Override default test logic
#   post_test()            - After tests pass (cleanup, artifacts)
#   custom_install()       - Override entire install logic
#   pre_wheel()            - Before wheel building (setup)
#   custom_wheel_metadata() - Custom wheel metadata modifications
#
# EXIT CODES:
#   0 - Success (build and test passed, or build passed with no tests)
#   1 - Clone or install failure
#   2 - Test failure (install succeeded)
#   3 - Wheel build failure (test succeeded)
# =============================================================================

# Ensure we're being sourced, not executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "ERROR: This script must be sourced, not executed directly."
    echo "Usage: source \"\${SCRIPT_DIR}/../templates/python.sh\""
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
source "${TEMPLATE_DIR}/lib/prereq-checks.sh"
source "${TEMPLATE_DIR}/lib/wheel-utils.sh"
source "${TEMPLATE_DIR}/lib/bundled-license-utils.sh"
source "${TEMPLATE_DIR}/lib/wheel-sbom.sh"
source "${TEMPLATE_DIR}/lib/container.sh"

# Source artifact helpers if BUILD_DEPS or PROVIDES_ARTIFACT is declared
# These variables trigger the native dependency system
if [[ -n "${BUILD_DEPS:-}" || -n "${PROVIDES_ARTIFACT:-}" ]]; then
    source "${TEMPLATE_DIR}/lib/artifacts.sh"

    # Auto-source BUILD_DEPS if declared (consistent with base.sh behavior)
    if [[ -n "${BUILD_DEPS:-}" ]]; then
        log_info "Auto-sourcing BUILD_DEPS: ${BUILD_DEPS}"
        for _dep in ${BUILD_DEPS}; do
            # Handle name:version format
            _dep_name="${_dep%%:*}"
            _dep_version="${_dep#*:}"
            [[ "$_dep_version" == "$_dep_name" ]] && _dep_version=""

            if ! source_artifact "$_dep_name" "$_dep_version"; then
                log_warn "Could not source artifact: ${_dep} (may need to build first)"
            fi
        done
        unset _dep _dep_name _dep_version
    fi
fi

# =============================================================================
# VALIDATE REQUIRED VARIABLES
# =============================================================================
validate_required_vars PACKAGE_NAME PACKAGE_VERSION PACKAGE_URL

# Set defaults for optional variables
# Note: PYTHON_VERSION is set by entrypoint as version number (e.g., "3.11") for compatibility checks
# The entrypoint sets up python/python3 symlinks to point to the correct version
: ${CLONE_DIR:="$PACKAGE_NAME"}
: ${SKIP_TESTS:="false"}
: ${NOARCH:="false"}
: ${PYPI_NAME:="$PACKAGE_NAME"}
: ${PYPI_VERSION:="$PYPI_VERSION"}
: ${BUILD_WHEEL:="false"}
: ${OUTPUT_DIR:="${PWD}"}

# =============================================================================
# HELPER: Check if callback function exists
# =============================================================================
_has_callback() {
    type -t "$1" 2>/dev/null | grep -q "function"
}

# =============================================================================
# HELPER: Process, repair, license, and generate SBOM for built wheels
# Arguments:
#   1. input_dir   - Directory containing raw built wheels (e.g., "dist")
#   2. output_dir  - Directory where final processed wheels should be stored
#   3. install     - Set to "true" to install the processed wheels in current env
# Returns: 0 on success, 1 on failure
# =============================================================================
_process_and_package_wheels() {
    local input_dir="$1"
    local output_dir="$2"
    local install="${3:-false}"

    local raw_wheels=($(find_wheel_files "$input_dir"))
    if [[ ${#raw_wheels[@]} -eq 0 ]]; then
        log_warn "No wheel files found in ${input_dir}"
        return 0
    fi

    log_info "Processing built wheels from ${input_dir}..."
    local wheelhouse_dir="${input_dir}/wheelhouse"
    mkdir -p "$wheelhouse_dir"

    local repair_success=true
    for wheel_file in "${raw_wheels[@]}"; do
        log_info "Repairing: $(basename "$wheel_file")"
        log_info "Current LD_LIBRARY_PATH: ${LD_LIBRARY_PATH:-}"
        auditwheel repair "$wheel_file" -w "$wheelhouse_dir" 2>&1 | tee /tmp/auditwheel.log
        local auditwheel_rc=${PIPESTATUS[0]}
        if [[ $auditwheel_rc -eq 0 ]]; then
            if grep -q "Fixed-up wheel written to" /tmp/auditwheel.log; then
                log_info "Wheel repaired successfully"
            else
                log_info "Wheel already compliant, no repair needed"
                cp "$wheel_file" "$wheelhouse_dir/"
            fi
        else
            if grep -q "This does not look like a platform wheel" /tmp/auditwheel.log; then
                log_info "Pure Python wheel, no repair needed"
                cp "$wheel_file" "$wheelhouse_dir/"
            else
                log_error "auditwheel repair failed for $(basename "$wheel_file")"
                repair_success=false
            fi
        fi
    done
    rm -f /tmp/auditwheel.log

    if [[ "$repair_success" == "false" ]]; then
        rm -rf "$wheelhouse_dir"
        return 1
    fi

    # Process bundled library licenses (adds license files to wheel)
    log_info "Processing bundled library licenses"
    process_bundled_licenses "$wheelhouse_dir"/*.whl

    # Generate SBOM and CVE reports
    log_info "Generating SBOM and CVE reports"
    generate_wheel_sbom "$wheelhouse_dir"/*.whl

    # Modify wheel metadata if classifiers are defined or custom callback exists
    if [[ ${#WHEEL_CLASSIFIERS[@]} -gt 0 ]] || _has_callback custom_wheel_metadata; then
        log_info "Modifying wheel metadata..."
        for wheel_file in "$wheelhouse_dir"/*.whl; do
            if ! modify_wheel_metadata "$wheel_file"; then
                log_warn "Failed to modify metadata for $(basename "$wheel_file")"
            fi
        done
    fi

    # Install wheel if requested
    if [[ "$install" == "true" ]]; then
        log_info "Installing wheel"
        if ! pip install "$wheelhouse_dir"/*.whl; then
            log_error "Failed to install wheel"
            rm -rf "$wheelhouse_dir"
            return 1
        fi
    fi

    # Copy processed wheels to final destination
    mkdir -p "$output_dir"
    cp "$wheelhouse_dir"/*.whl "$output_dir/"
    
    mkdir -p "${output_dir}/artifacts"
    # Create hard links instead of copying to prevent using double disk space
    for whl in "$output_dir"/*.whl; do
        ln -f "$whl" "${output_dir}/artifacts/" 2>/dev/null || cp "$whl" "${output_dir}/artifacts/"
    done

    # Clean up the temporary wheelhouse
    rm -rf "$wheelhouse_dir"

    return 0
}

# =============================================================================
# HELPER: Build wheel artifact with metadata modifications
# Returns: 0 on success, 1 on failure
# =============================================================================
_build_wheel_artifact() {
    local output_dir="${1:-$OUTPUT_DIR}"
    local wheel_build_status=0

    log_info "Building wheel artifact (BUILD_WHEEL=true)"

    # Activate build virtual environment if it exists
    local venv_activated=false
    if [[ -f ".venv-build/bin/activate" ]]; then
        log_info "Activating build virtual environment for wheel build"
        source .venv-build/bin/activate
        venv_activated=true
    fi

    # Run pre_wheel callback if defined
    if _has_callback pre_wheel; then
        log_info "Running pre_wheel hook..."
        if ! pre_wheel; then
            log_error "pre_wheel hook failed"
            [[ "$venv_activated" == "true" ]] && deactivate
            return 1
        fi
    fi

    # Build wheel into dist/ directory so it's clean and separate from output
    local build_dir="dist"
    mkdir -p "$build_dir"
    # Clean previous wheels in dist/ to avoid processing old ones
    rm -f "$build_dir"/*.whl

    local -a build_opts=()
    if [[ -n "${WHEEL_BUILD_OPTS:-}" ]]; then
        build_opts=(${WHEEL_BUILD_OPTS})
    fi

    if ! build_wheel "$build_dir" "${build_opts[@]}"; then
        log_error "Wheel build failed"
        [[ "$venv_activated" == "true" ]] && deactivate
        return 1
    fi

    # Process and package the built wheels
    if ! _process_and_package_wheels "$build_dir" "$output_dir" "false"; then
        log_error "Wheel processing failed"
        [[ "$venv_activated" == "true" ]] && deactivate
        return 1
    fi

    # Deactivate build virtual environment if we activated it
    if [[ "$venv_activated" == "true" ]]; then
        log_info "Deactivating build virtual environment"
        deactivate
    fi

    log_info "Wheel build complete: $output_dir"
    return 0
}

# =============================================================================
# INITIALIZATION
# =============================================================================
detect_os

log_info "======================================================================"
log_info "Building $PACKAGE_NAME version $PACKAGE_VERSION"
log_info "Python: $(python3 --version 2>&1)"
log_info "OS: $OS_NAME"
[[ "$NOARCH" == "true" ]] && log_info "Mode: NOARCH (install from PyPI)"
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
# CALLBACK: pre_clone
# =============================================================================
if _has_callback pre_clone; then
    log_info "Running pre_clone hook..."
    if ! pre_clone; then
        log_error "pre_clone hook failed"
        report_install_fail
        exit 1
    fi
fi

# =============================================================================
# CLONE REPOSITORY
# =============================================================================
clone_repository

# =============================================================================
# CALLBACK: post_clone (patches, source modifications)
# =============================================================================
if _has_callback post_clone; then
    log_info "Running post_clone hook..."
    if ! post_clone; then
        log_error "post_clone hook failed"
        report_install_fail
        exit 1
    fi
fi

# =============================================================================
# BUILD / INSTALL
# =============================================================================
# Skip venv creation only for NOARCH mode (PyPI install happens in test phase)
if [[ "$NOARCH" != "true" ]]; then
    # Create venv for both custom_install and standard build
    log_info "Creating build virtual environment"
    if ! python3 -m venv .venv-build; then
        log_error "Failed to create virtual environment"
        log_error "Ensure python3 has venv module (python3-venv package)"
        report_install_fail
        exit 1
    fi
    # Activate venv for build phase (for custom_install and standard build)
    log_info "Activating build virtual environment"
    source .venv-build/bin/activate
    log_info "Using Python: $(python --version) from ${VIRTUAL_ENV}"

    # Pin setuptools<70 by default - newer versions have API changes that break some packages
    # Override with SETUPTOOLS_VERSION in script: "" for latest, ">=70,<82" for specific range
    pip install --upgrade pip "setuptools${SETUPTOOLS_VERSION-<70}" build wheel pip-tools patchelf auditwheel

    # pre_build runs INSIDE venv - can pip install cython, etc.
    if _has_callback pre_build; then
        log_info "Running pre_build hook..."
        if ! pre_build; then
            log_error "pre_build hook failed"
            deactivate
            report_install_fail
            exit 1
        fi
    fi
fi

# Now handle the three build modes
if _has_callback custom_install; then
    # custom_install handles everything (runs inside venv if not NOARCH)
    log_info "Running custom_install hook..."
    if ! custom_install; then
        [[ -n "${VIRTUAL_ENV:-}" ]] && deactivate
        report_install_fail
        exit 1  # Belt-and-suspenders: explicit exit in case report function doesn't terminate
    fi

    # Check if custom_install built any wheels in dist/
    if ls dist/*.whl 1>/dev/null 2>&1; then
        log_info "Detected wheels built by custom_install. Processing..."
        if ! _process_and_package_wheels "dist" "${OUTPUT_DIR}" "true"; then
            [[ -n "${VIRTUAL_ENV:-}" ]] && deactivate
            report_test_success_wheel_fail
            exit 3
        fi
    fi

    [[ -n "${VIRTUAL_ENV:-}" ]] && deactivate
elif [[ "$NOARCH" == "true" ]]; then
    # NOARCH: Install from PyPI instead of building from source
    # pre_build can be used for dependency checks or installing build tools
    if _has_callback pre_build; then
        log_info "Running pre_build hook..."
        if ! pre_build; then
            log_error "pre_build hook failed"
            report_install_fail
            exit 1
        fi
    fi
    log_info "NOARCH mode: Skipping local build"
    log_info "Package will be installed from PyPI during test phase"
    # Note: Actual install happens in test venv below
else
    # Standard Python install workflow (venv already created and activated above)
    if [[ -f "pyproject.toml" ]]; then
        log_info "Installing pyproject.toml"
        pip install --upgrade build
    fi

    if [[ -f "requirements.txt" ]]; then
	    log_info "Installing runtime requirements"
	    pip install -r requirements.txt
    fi

    log_info "Building package"
    # Use --no-isolation so pre_build dependencies (cython, etc.) are available
    # during the build. Isolation creates a fresh venv which defeats pre_build.
    if ! python -m build --no-isolation ; then
        deactivate
        report_build_fail
        exit 1
    fi

    # Check if any wheels were built
    if ls dist/*.whl 1>/dev/null 2>&1; then
        if ! _process_and_package_wheels "dist" "${OUTPUT_DIR}" "true"; then
            deactivate
            report_test_success_wheel_fail
            exit 3
        fi

        # Extract package name from the built wheel
        wheel_files=($(find_wheel_files "${OUTPUT_DIR}/artifacts"))
        if [[ ${#wheel_files[@]} -gt 0 ]]; then
            import_name=$(basename "${wheel_files[0]}" | cut -d'-' -f1)
            pip show "${import_name}"
        fi
    else
        log_warn "No wheel files found in dist/"
    fi

    deactivate
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

    # Build wheel if BUILD_WHEEL=true (before exit)
    wheel_build_status=0
    if [[ "$BUILD_WHEEL" == "true" ]]; then
        _build_wheel_artifact "$OUTPUT_DIR" && wheel_build_status=0 || wheel_build_status=1
    fi

    # Container build before exit (report functions exit the script)
    if _should_build_container "${SCRIPT_DIR}"; then
        build_container "${PACKAGE_VERSION}" "${SCRIPT_DIR}/Dockerfile"
    fi

    # Report with wheel status if BUILD_WHEEL was enabled
    if [[ "$BUILD_WHEEL" == "true" ]]; then
        if [[ $wheel_build_status -eq 0 ]]; then
            report_no_tests_with_wheel
        else
            report_wheel_fail
        fi
    else
        report_no_tests
    fi
fi

# Standard Python test phase (only reached if no custom_install)
log_info "Creating test virtual environment"
if ! python3 -m venv .venv-test; then
    log_error "Failed to create test virtual environment"
    report_test_fail
    exit 2
fi
source .venv-test/bin/activate
if [[ -z "${VIRTUAL_ENV:-}" ]]; then
    log_error "Test virtual environment activation failed"
    report_test_fail
    exit 2
fi

# Ensure Rust environment is available for Rust/Python hybrid packages
# This is needed when tox/nox try to rebuild from sdist
if [[ -f "/opt/rust/cargo/env" ]]; then
    source /opt/rust/cargo/env
fi
if [[ -f "$HOME/.cargo/env" ]]; then
    source "$HOME/.cargo/env"
fi

log_info "Using Python: $(python --version) from ${VIRTUAL_ENV}"

# Install pytest, setuptools, and wheel in test venv
pip install --upgrade pip pytest "setuptools${SETUPTOOLS_VERSION-<70}" wheel

# CALLBACK: pre_test (install test deps or setup environment)
if _has_callback pre_test; then
    log_info "Running pre_test hook..."
    if ! pre_test; then
        log_error "pre_test hook failed"
        deactivate
        report_test_fail
        exit 2
    fi
fi

if [[ -f "requirements.txt" ]]; then
    log_info "Installing runtime requirements for testing"
    pip install -r requirements.txt
fi

if [[ -f "requirements-test.txt" ]]; then
    log_info "Installing testing requirements"
    pip install -r requirements-test.txt
fi

# Install the package in test environment
if [[ "$NOARCH" == "true" ]]; then
    # Check if PYPI_VERSION is explicitly passed, If not, take PACKAGE_VERSION and strip prefixes
    if [[ -z "${PYPI_VERSION}" ]]; then
	    # Install from PyPI (strip 'v' prefix from version if present)
	    PYPI_VERSION="${PACKAGE_VERSION#v}"
    fi
    log_info "Installing ${PYPI_NAME}==${PYPI_VERSION} from PyPI"
    if ! python -m pip install "${PYPI_NAME}==${PYPI_VERSION}"; then
        deactivate
        report_install_fail
        exit 1
    fi
else
    # Install the pre-built repaired wheel if available to avoid rebuilding from source
    wheel_installed=false
    if ls "${OUTPUT_DIR}"/*.whl 1>/dev/null 2>&1; then
        log_info "Installing pre-built wheel from ${OUTPUT_DIR}"
        if python -m pip install "${OUTPUT_DIR}"/*.whl; then
            wheel_installed=true
        fi
    elif ls dist/*.whl 1>/dev/null 2>&1; then
        log_info "Installing pre-built wheel from dist/"
        if python -m pip install dist/*.whl; then
            wheel_installed=true
        fi
    fi

    if [[ "$wheel_installed" == "false" ]]; then
        log_info "No pre-built wheels found, installing from local source"
        if ! python -m pip install --no-build-isolation .; then
            deactivate
            report_install_fail
            exit 1
        fi
    fi
fi

log_info "Running tests"

test_status=1  # 0 = success, non-zero = failure
used_custom_test=false

if _has_callback custom_test_command; then
    # User provides custom test command
    log_info "Running custom_test_command hook..."
    used_custom_test=true
    custom_test_command && test_status=0 || test_status=$?
else
    # Standard test discovery
    # Try pytest first
    if ls */test_*.py tests/test_*.py test_*.py 2>/dev/null | head -1 > /dev/null; then
        log_info "Running pytest..."
        # Remove plugins that may be installed by requirements-test.txt and cause conflicts
        pip uninstall -y pytest-cov pytest-xdist pytest-codspeed 2>/dev/null || true
        # Clear addopts (setup.cfg may have --cov flags)
        # Use --import-mode=importlib to avoid importing source tree instead of installed package
        # (fixes C extension packages where source dir shadows installed .so files)
        python -m pytest --import-mode=importlib -o "addopts=" && test_status=0 || test_status=$?
    fi

    # Try tox if pytest failed or no tests found
    if [[ -f "tox.ini" ]] && [[ $test_status -ne 0 ]]; then
        log_info "Running tox..."
        pip install tox
        # Pass through Rust/Cargo environment for Rust extension packages
        # Without this, tox's isolated environment can't find rustc when rebuilding
        export TOX_TESTENV_PASSENV="${TOX_TESTENV_PASSENV:-} PATH CARGO_HOME RUSTUP_HOME"
        python -m tox -e py3 && test_status=0 || test_status=$?
    fi

    # Try nox if still no success
    if [[ -f "noxfile.py" ]] && [[ $test_status -ne 0 ]]; then
        log_info "Running nox..."
        pip install nox
        python -m nox && test_status=0 || test_status=$?
    fi
fi

deactivate

# =============================================================================
# CALLBACK: post_test
# =============================================================================
if _has_callback post_test; then
    log_info "Running post_test hook..."
    post_test
fi

# =============================================================================
# WHEEL BUILD (optional)
# Build wheel artifact if:
#   - BUILD_WHEEL=true
#   - Build and tests passed (test_status == 0) OR tests were skipped (SKIP_TESTS=true)
# =============================================================================
wheel_build_status=0
if [[ "$BUILD_WHEEL" == "true" ]] && { [[ $test_status -eq 0 ]] || [[ "$SKIP_TESTS" == "true" ]]; }; then
    _build_wheel_artifact "$OUTPUT_DIR" && wheel_build_status=0 || wheel_build_status=1
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
    # Report success with wheel status if BUILD_WHEEL was enabled
    if [[ "$BUILD_WHEEL" == "true" ]]; then
        if [[ $wheel_build_status -eq 0 ]]; then
            report_success_with_wheel
        else
            report_test_success_wheel_fail
        fi
    else
        report_success
    fi
else
    # If custom_test_command was used and failed, it's a real failure
    # (the script author explicitly defined tests, so "no tests found" doesn't apply)
    if [[ "$used_custom_test" == "true" ]]; then
        report_test_fail
        exit 2
    fi
    # For standard test discovery, check if any tests were actually found
    if ls */test_*.py tests/test_*.py test_*.py tox.ini noxfile.py 2>/dev/null | head -1 > /dev/null; then
        report_test_fail
        exit 2
    else
        log_info "No tests found"
        # Container build before exit (report_no_tests exits the script)
        if _should_build_container "${SCRIPT_DIR}"; then
            build_container "${PACKAGE_VERSION}" "${SCRIPT_DIR}/Dockerfile"
        fi
        report_no_tests
    fi
fi
