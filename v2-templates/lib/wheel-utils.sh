#!/bin/bash
# =============================================================================
# wheel-utils.sh - Python wheel building and metadata utilities
# =============================================================================
# This file provides functions for building Python wheels and modifying
# wheel metadata (classifiers, etc.).
#
# Usage:
#   source "${TEMPLATE_DIR}/lib/wheel-utils.sh"
#
#   # Build a wheel
#   build_wheel "/output/dir"
#
#   # Modify wheel metadata
#   WHEEL_CLASSIFIERS=("Environment :: IBM Power" "Platform :: ppc64le")
#   modify_wheel_metadata "/path/to/package.whl"
#
# Extensibility:
#   - WHEEL_CLASSIFIERS array: Add classifiers to inject
#   - custom_wheel_metadata() callback: Full control over metadata modifications
# =============================================================================

# Prevent multiple sourcing
[[ -n "$_WHEEL_UTILS_SH_SOURCED" ]] && return 0
_WHEEL_UTILS_SH_SOURCED=1

# =============================================================================
# WHEEL BUILD CONFIGURATION
# =============================================================================

# WHEEL_CLASSIFIERS: Array of classifiers to add to wheel metadata
# Override or extend this in your build script
declare -a WHEEL_CLASSIFIERS=(
    "Environment :: MetaData :: IBM Python Ecosystem"
)

# =============================================================================
# WHEEL BUILDING
# =============================================================================

# build_wheel: Build a Python wheel from the current directory
# Usage: build_wheel [output_dir] [build_opts...]
# Returns: 0 on success, 1 on failure
build_wheel() {
    local output_dir="${1:-.}"
    if [[ $# -gt 0 ]]; then
        shift 1
    fi
    local build_opts=("$@")
    local build_success=1

    log_info "Building wheel to $output_dir"

    # Ensure output directory exists
    mkdir -p "$output_dir"

    # Ensure build tool is available
    pip install --quiet --upgrade build wheel

    # If setup.py exists and custom build options are passed, build via setup.py directly
    if [[ -f "setup.py" && ${#build_opts[@]} -gt 0 ]]; then
        log_info "Attempting wheel build via setup.py with options: ${build_opts[*]}"
        if python setup.py bdist_wheel "${build_opts[@]}" --dist-dir "$output_dir"; then
            build_success=0
        fi
    else
        # Try building without isolation first (faster, uses installed deps)
        log_info "Attempting wheel build without isolation..."
        if python -m build --wheel --no-isolation --outdir="$output_dir" "${build_opts[@]}" 2>/dev/null; then
            build_success=0
        else
            # Fall back to isolated build
            log_info "Attempting wheel build with isolation..."
            if python -m build --wheel --outdir="$output_dir" "${build_opts[@]}"; then
                build_success=0
            fi
        fi
    fi

    if [[ $build_success -eq 0 ]]; then
        log_info "Wheel built successfully"
        ls -la "$output_dir"/*.whl 2>/dev/null || true
    else
        log_error "Wheel build failed"
    fi

    return $build_success
}

# find_wheel_files: Find wheel files in a directory
# Usage: find_wheel_files [directory]
# Outputs: List of .whl file paths
find_wheel_files() {
    local dir="${1:-.}"
    find "$dir" -maxdepth 1 -name "*.whl" -type f 2>/dev/null
}

# =============================================================================
# WHEEL METADATA MODIFICATION
# =============================================================================

# modify_wheel_metadata: Modify metadata in a wheel file
# Usage: modify_wheel_metadata wheel_path
#
# This function:
#   1. Extracts the wheel
#   2. Adds classifiers from WHEEL_CLASSIFIERS array
#   3. Calls custom_wheel_metadata() callback if defined
#   4. Repacks the wheel
#
# Returns: 0 on success, 1 on failure
modify_wheel_metadata() {
    local wheel_path="$1"

    if [[ ! -f "$wheel_path" ]]; then
        log_error "Wheel file not found: $wheel_path"
        return 1
    fi

    # Convert to absolute path so we can access it after cd'ing into temp_dir
    wheel_path="$(cd "$(dirname "$wheel_path")" && pwd)/$(basename "$wheel_path")"

    # Check for required tools
    if ! command -v unzip &>/dev/null || ! command -v zip &>/dev/null; then
        log_warn "zip/unzip not available, skipping metadata modification"
        return 0
    fi

    local wheel_name
    wheel_name=$(basename "$wheel_path")
    local wheel_dir
    wheel_dir=$(dirname "$wheel_path")
    local temp_dir
    temp_dir=$(mktemp -d)

    log_info "Modifying metadata in $wheel_name"

    # Extract wheel
    if ! unzip -q "$wheel_path" -d "$temp_dir"; then
        log_error "Failed to extract wheel"
        rm -rf "$temp_dir"
        return 1
    fi

    # Find METADATA file
    local metadata_file
    metadata_file=$(find "$temp_dir" -name "METADATA" -path "*.dist-info/*" | head -1)

    if [[ -z "$metadata_file" ]]; then
        log_error "METADATA file not found in wheel"
        rm -rf "$temp_dir"
        return 1
    fi

    # Add classifiers from WHEEL_CLASSIFIERS array
    _inject_classifiers "$metadata_file"

    # Call custom callback if defined
    if type -t custom_wheel_metadata 2>/dev/null | grep -q "function"; then
        log_info "Running custom_wheel_metadata hook..."
        custom_wheel_metadata "$metadata_file" "$temp_dir"
    fi

    # Repack wheel
    local original_dir="$PWD"
    cd "$temp_dir"

    # Remove old wheel and create new one
    rm -f "$wheel_path"
    if ! zip -q -r "$wheel_path" .; then
        log_error "Failed to repack wheel"
        cd "$original_dir"
        rm -rf "$temp_dir"
        return 1
    fi

    cd "$original_dir"
    rm -rf "$temp_dir"

    log_info "Metadata modification complete"
    return 0
}

# _inject_classifiers: Add classifiers to METADATA file
# Usage: _inject_classifiers metadata_file
# Internal function - uses WHEEL_CLASSIFIERS array
_inject_classifiers() {
    local metadata_file="$1"
    local classifiers_added=0

    for classifier in "${WHEEL_CLASSIFIERS[@]}"; do
        local full_classifier="Classifier: $classifier"

        # Skip if already present
        if grep -qF "$full_classifier" "$metadata_file"; then
            log_info "Classifier already present: $classifier"
            continue
        fi

        # Find the last Classifier line and insert after it
        # If no Classifier lines exist, add at the end
        if grep -q "^Classifier:" "$metadata_file"; then
            # Insert after last Classifier line
            local last_line
            last_line=$(grep -n "^Classifier:" "$metadata_file" | tail -1 | cut -d: -f1)
            sed -i "${last_line}a\\${full_classifier}" "$metadata_file"
        else
            # Append to end
            echo "$full_classifier" >> "$metadata_file"
        fi

        log_info "Added classifier: $classifier"
        ((classifiers_added++))
    done

    [[ $classifiers_added -gt 0 ]] && log_info "Added $classifiers_added classifier(s)"
    return 0
}

# =============================================================================
# CONVENIENCE FUNCTIONS
# =============================================================================

# add_wheel_classifier: Add a classifier to WHEEL_CLASSIFIERS array
# Usage: add_wheel_classifier "Environment :: Production"
# Call this before sourcing the template to add custom classifiers
add_wheel_classifier() {
    WHEEL_CLASSIFIERS+=("$1")
}

# clear_wheel_classifiers: Clear all default classifiers
# Usage: clear_wheel_classifiers
# Use this if you want to start with an empty classifier list
clear_wheel_classifiers() {
    WHEEL_CLASSIFIERS=()
}

# set_wheel_classifiers: Replace all classifiers
# Usage: set_wheel_classifiers "Classifier1" "Classifier2" ...
set_wheel_classifiers() {
    WHEEL_CLASSIFIERS=("$@")
}

# =============================================================================
# WHEEL VALIDATION
# =============================================================================

# validate_wheel: Basic validation of a wheel file
# Usage: validate_wheel wheel_path
# Returns: 0 if valid, 1 if invalid
validate_wheel() {
    local wheel_path="$1"

    if [[ ! -f "$wheel_path" ]]; then
        log_error "Wheel file not found: $wheel_path"
        return 1
    fi

    # Check it's a valid zip
    if ! unzip -t "$wheel_path" &>/dev/null; then
        log_error "Wheel is not a valid zip file"
        return 1
    fi

    # Check for required files
    if ! unzip -l "$wheel_path" | grep -q "\.dist-info/METADATA"; then
        log_error "Wheel missing METADATA file"
        return 1
    fi

    if ! unzip -l "$wheel_path" | grep -q "\.dist-info/WHEEL"; then
        log_error "Wheel missing WHEEL file"
        return 1
    fi

    log_info "Wheel validation passed: $(basename "$wheel_path")"
    return 0
}
