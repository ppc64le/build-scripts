#!/bin/bash
# =============================================================================
# bundled-license-utils.sh - License handling for auditwheel-bundled libraries
# =============================================================================
# This library processes Python wheels after auditwheel repair to identify
# and document licenses for bundled shared libraries (.so files).
#
# Usage:
#   source "${TEMPLATE_DIR}/lib/bundled-license-utils.sh"
#   process_bundled_licenses wheelhouse/*.whl
#
# The process:
#   1. Extract wheel and find .libs/ directories
#   2. For each bundled .so file:
#      a. Check artifact system manifests (custom-built libs)
#      b. Check RPM ownership and license (system libs, UBI/RHEL only)
#      c. Search filesystem for bundled LICENSE/COPYING files
#   3. Generate license files in .dist-info/:
#      - UBI_BUNDLED_LICENSES.txt (RPM-derived licenses)
#      - BUNDLED_LICENSES.txt (project licenses and fallback markers)
#   4. Update RECORD and repack wheel
#
# Environment:
#   ARTIFACT_DIR - Base directory for artifact system (default: /opt/artifacts)
#
# =============================================================================

# Prevent multiple sourcing
[[ -n "$_BUNDLED_LICENSE_UTILS_SOURCED" ]] && return 0
_BUNDLED_LICENSE_UTILS_SOURCED=1

# =============================================================================
# CONFIGURATION
# =============================================================================

: "${ARTIFACT_DIR:=/opt/artifacts}"

# Track missing licenses for reporting
declare -a _MISSING_LICENSES=()

# =============================================================================
# OS DETECTION
# =============================================================================

_is_rpm_available() {
    [[ -f /etc/redhat-release ]] && command -v rpm &>/dev/null
}

_is_ubuntu() {
    [[ -f /etc/lsb-release ]] && grep -q "Ubuntu" /etc/lsb-release 2>/dev/null
}

# =============================================================================
# LIBRARY NAME NORMALIZATION
# =============================================================================

# _normalize_so_name: Remove auditwheel hash from library filename
# Example: libgfortran-37ae8338.so.5.0.0 -> libgfortran.so.5.0.0
_normalize_so_name() {
    local original="$1"
    # Remove pattern: -<8+ hex chars> before .so or version suffix
    echo "$original" | sed -E 's/-[0-9a-f]{8,}(\.so)/\1/g'
}

# =============================================================================
# LICENSE RESOLUTION - ARTIFACT SYSTEM
# =============================================================================

# _resolve_license_from_artifact: Check if library came from artifact system
# Returns license text on stdout, returns 0 if found
_resolve_license_from_artifact() {
    local so_name="$1"
    local normalized="$2"

    # Extract base library name (e.g., libopenblas -> openblas)
    local lib_base
    lib_base=$(echo "$normalized" | sed -E 's/^lib//; s/\.so.*$//')

    # Search artifact directories for matching library
    for artifact_path in "${ARTIFACT_DIR}"/*; do
        [[ ! -d "$artifact_path" ]] && continue

        local manifest="${artifact_path}/manifest.json"
        [[ ! -f "$manifest" ]] && continue

        # Check if this artifact contains our library
        if find "$artifact_path" -name "$normalized" -type f 2>/dev/null | grep -q .; then
            # Found it - extract license from manifest
            if command -v jq &>/dev/null; then
                local spdx
                spdx=$(jq -r '.license_spdx // empty' "$manifest" 2>/dev/null)
                local name
                name=$(jq -r '.name // empty' "$manifest" 2>/dev/null)

                if [[ -n "$spdx" ]]; then
                    echo "License: ${spdx}"
                    echo "Source: Artifact system (${name})"

                    # Also check for full license file
                    for license_file in LICENSE LICENSE.txt LICENSE.md COPYING; do
                        if [[ -f "${artifact_path}/${license_file}" ]]; then
                            echo ""
                            cat "${artifact_path}/${license_file}"
                            break
                        fi
                    done
                    return 0
                fi
            fi
        fi
    done

    return 1
}

# =============================================================================
# LICENSE RESOLUTION - RPM
# =============================================================================

# _resolve_license_from_rpm: Check RPM ownership and get license
# Returns license text on stdout, returns 0 if found
_resolve_license_from_rpm() {
    local so_name="$1"
    local normalized="$2"

    if ! _is_rpm_available; then
        return 1
    fi

    # Search for the library on the filesystem
    local lib_path
    lib_path=$(find /usr/lib64 /usr/lib /lib64 /lib -name "$normalized" -type f 2>/dev/null | head -1)

    [[ -z "$lib_path" ]] && return 1

    # Check RPM ownership
    local rpm_name
    rpm_name=$(rpm -qf "$lib_path" 2>/dev/null)

    if [[ $? -ne 0 ]] || [[ "$rpm_name" == *"not owned"* ]]; then
        return 1
    fi

    # Get license from RPM
    local license
    license=$(rpm -q --qf "%{LICENSE}\n" "$rpm_name" 2>/dev/null)

    if [[ -n "$license" ]] && [[ "$license" != "(none)" ]]; then
        echo "License: ${license}"
        echo "Source: RPM (${rpm_name})"
        return 0
    fi

    return 1
}

# =============================================================================
# LICENSE RESOLUTION - FILESYSTEM SEARCH
# =============================================================================

# _resolve_license_from_filesystem: Search for bundled LICENSE/COPYING files
# Returns license text on stdout, returns 0 if found
_resolve_license_from_filesystem() {
    local so_name="$1"
    local normalized="$2"

    # Search for the library on the filesystem
    local lib_path
    lib_path=$(find / -name "$normalized" -type f 2>/dev/null | grep -v "\.whl" | head -1)

    [[ -z "$lib_path" ]] && return 1

    # Traverse upward looking for LICENSE/COPYING
    local dir
    dir=$(dirname "$lib_path")
    local depth=0
    local max_depth=10

    while [[ "$dir" != "/" ]] && [[ $depth -lt $max_depth ]]; do
        for license_pattern in LICENSE COPYING LICENSE.txt LICENSE.md COPYING.txt; do
            local license_file="${dir}/${license_pattern}"
            if [[ -f "$license_file" ]]; then
                cat "$license_file"
                return 0
            fi
        done
        dir=$(dirname "$dir")
        ((depth++))
    done

    return 1
}

# =============================================================================
# MAIN LICENSE RESOLUTION
# =============================================================================

# _resolve_library_license: Try all methods to resolve license for a .so
# Arguments: original_name normalized_name
# Returns: license text on stdout, return code indicates success
_resolve_library_license() {
    local original="$1"
    local normalized="$2"
    local license_text=""
    local source=""

    # Try artifact system first (highest priority for custom builds)
    if license_text=$(_resolve_license_from_artifact "$original" "$normalized"); then
        echo "$license_text"
        return 0
    fi

    # Try RPM lookup (for system libraries on UBI/RHEL)
    if license_text=$(_resolve_license_from_rpm "$original" "$normalized"); then
        echo "$license_text"
        return 0
    fi

    # Try filesystem search (for bundled project licenses)
    if license_text=$(_resolve_license_from_filesystem "$original" "$normalized"); then
        echo "$license_text"
        return 0
    fi

    # No license found
    return 1
}

# =============================================================================
# WHEEL PROCESSING
# =============================================================================

# _find_bundled_libs: Find all bundled .so files in extracted wheel
# Arguments: extracted_wheel_dir
# Outputs: list of .so file paths
_find_bundled_libs() {
    local wheel_dir="$1"

    # Find .libs directories and collect eligible .so files
    find "$wheel_dir" -type d -name "*.libs" 2>/dev/null | while read -r libs_dir; do
        find "$libs_dir" -type f -name "lib*.so*" 2>/dev/null
    done
}

# _generate_license_files: Create license files in .dist-info
# Arguments: wheel_dir dist_info_dir
_generate_license_files() {
    local wheel_dir="$1"
    local dist_info="$2"

    local ubi_licenses="${dist_info}/UBI_BUNDLED_LICENSES.txt"
    local bundled_licenses="${dist_info}/BUNDLED_LICENSES.txt"

    # Initialize files
    cat > "$ubi_licenses" << 'EOF'
# UBI/RPM-derived licenses for bundled shared libraries
# Generated by bundled-license-utils.sh
EOF

    cat > "$bundled_licenses" << 'EOF'
# Bundled shared library licenses
# Generated by bundled-license-utils.sh
EOF

    local has_ubi_licenses=false
    local has_bundled_licenses=false

    # Process each bundled library
    while IFS= read -r so_file; do
        [[ -z "$so_file" ]] && continue

        local so_name
        so_name=$(basename "$so_file")
        local normalized
        normalized=$(_normalize_so_name "$so_name")

        log_info "Processing bundled library: ${so_name}"

        local license_text
        if license_text=$(_resolve_library_license "$so_name" "$normalized"); then
            # Determine if RPM-derived or bundled
            if echo "$license_text" | grep -q "Source: RPM"; then
                has_ubi_licenses=true
                {
                    echo ""
                    echo "----"
                    echo "Files: ${so_name}"
                    echo "$license_text"
                } >> "$ubi_licenses"
            else
                has_bundled_licenses=true
                {
                    echo ""
                    echo "----"
                    echo "Files: ${so_name}"
                    echo "$license_text"
                } >> "$bundled_licenses"
            fi
        else
            # No license found - record as missing
            _MISSING_LICENSES+=("$so_name")
            has_bundled_licenses=true
            {
                echo ""
                echo "----"
                echo "Files: ${so_name}"
                echo "${so_name}_license_not_found"
            } >> "$bundled_licenses"
            log_warn "License not found for: ${so_name}"
        fi
    done < <(_find_bundled_libs "$wheel_dir")

    # Remove empty license files
    if [[ "$has_ubi_licenses" != "true" ]]; then
        rm -f "$ubi_licenses"
    fi
    if [[ "$has_bundled_licenses" != "true" ]]; then
        rm -f "$bundled_licenses"
    fi
}

# _update_wheel_record: Regenerate RECORD file with new entries
# Arguments: wheel_dir dist_info_dir
_update_wheel_record() {
    local wheel_dir="$1"
    local dist_info="$2"
    local record_file="${dist_info}/RECORD"

    # Remove old RECORD
    rm -f "$record_file"

    # Generate new RECORD
    # Format: path,sha256=hash,size
    while IFS= read -r file; do
        [[ -z "$file" ]] && continue
        [[ "$file" == "$record_file" ]] && continue

        local rel_path="${file#${wheel_dir}/}"
        local hash
        hash=$(sha256sum "$file" | cut -d' ' -f1)
        local size
        size=$(stat -c%s "$file")

        echo "${rel_path},sha256=${hash},${size}" >> "$record_file"
    done < <(find "$wheel_dir" -type f)

    # RECORD itself has no hash
    echo "${dist_info##*/}/RECORD,," >> "$record_file"
}

# =============================================================================
# MAIN ENTRY POINT
# =============================================================================

# process_bundled_licenses: Process wheel to add licenses for bundled .so files
# Arguments: wheel_path [wheel_path ...]
# Returns: 0 on success, 1 on failure
process_bundled_licenses() {
    local wheel_paths=("$@")

    [[ ${#wheel_paths[@]} -eq 0 ]] && return 0

    # Check for required tools
    if ! command -v unzip &>/dev/null || ! command -v zip &>/dev/null; then
        log_warn "zip/unzip not available, skipping bundled license processing"
        return 0
    fi

    # Log OS detection status
    if _is_rpm_available; then
        log_info "RPM available - will query system package licenses"
    elif _is_ubuntu; then
        log_warn "Running on Ubuntu - RPM license lookup not available"
        log_warn "Licenses will be resolved from artifact system and filesystem only"
        log_warn "See templates/docs/WHEEL_LICENSE_GAPS.md for more information"
    else
        log_warn "Non-RPM system detected - some licenses may not be resolved"
    fi

    # Reset missing licenses tracker
    _MISSING_LICENSES=()

    for wheel_path in "${wheel_paths[@]}"; do
        [[ ! -f "$wheel_path" ]] && continue

        local wheel_name
        wheel_name=$(basename "$wheel_path")
        log_info "Processing bundled licenses in: ${wheel_name}"

        # Create temp directory for extraction
        local temp_dir
        temp_dir=$(mktemp -d)

        # Extract wheel
        if ! unzip -q "$wheel_path" -d "$temp_dir"; then
            log_error "Failed to extract wheel: ${wheel_name}"
            rm -rf "$temp_dir"
            continue
        fi

        # Find .dist-info directory
        local dist_info
        dist_info=$(find "$temp_dir" -maxdepth 1 -type d -name "*.dist-info" | head -1)

        if [[ -z "$dist_info" ]]; then
            log_warn "No .dist-info found in wheel: ${wheel_name}"
            rm -rf "$temp_dir"
            continue
        fi

        # Check if wheel has bundled libraries
        local libs_count
        libs_count=$(_find_bundled_libs "$temp_dir" | wc -l)

        if [[ "$libs_count" -eq 0 ]]; then
            log_info "No bundled libraries found in: ${wheel_name}"
            rm -rf "$temp_dir"
            continue
        fi

        log_info "Found ${libs_count} bundled libraries"

        # Generate license files
        _generate_license_files "$temp_dir" "$dist_info"

        # Update RECORD
        _update_wheel_record "$temp_dir" "$dist_info"

        # Repack wheel - convert to absolute path before cd
        local wheel_path_abs
        wheel_path_abs="$(cd "$(dirname "$wheel_path")" && pwd)/$(basename "$wheel_path")"

        rm -f "$wheel_path_abs"

        local original_dir="$PWD"
        cd "$temp_dir"

        if ! zip -q -r "$wheel_path_abs" .; then
            log_error "Failed to repack wheel: ${wheel_name}"
            cd "$original_dir"
            rm -rf "$temp_dir"
            return 1
        fi

        cd "$original_dir"
        rm -rf "$temp_dir"

        log_info "Bundled license processing complete: ${wheel_name}"
    done

    # Report any missing licenses
    if [[ ${#_MISSING_LICENSES[@]} -gt 0 ]]; then
        log_warn "========================================"
        log_warn "LICENSE GAPS DETECTED"
        log_warn "The following bundled libraries have unresolved licenses:"
        for lib in "${_MISSING_LICENSES[@]}"; do
            log_warn "  - ${lib}"
        done
        log_warn "========================================"
        log_warn "These are marked as '*_license_not_found' in BUNDLED_LICENSES.txt"
        log_warn "Manual review may be required for compliance."
    fi

    return 0
}

log_info "Bundled license utilities loaded"
