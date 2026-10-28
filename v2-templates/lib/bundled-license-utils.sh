#!/bin/bash
# =============================================================================
# bundled-license-utils.sh - License handling for auditwheel-bundled libraries
# =============================================================================
# This library processes Python wheels after auditwheel repair to identify
# and document licenses for bundled shared libraries (.so files).
#
# Usage:
#   source "${TEMPLATE_DIR}/lib/bundled-license-utils.sh"
#   # Called by postprocess_wheel_single_pass inside wheel-utils.sh:
#   #   _generate_license_files "$pkg_dir" "$dist_info"
#
# The process:
#   1. Inspect .libs/ directories inside extracted wheel
#   2. For each bundled .so file:
#      a. Check artifact system manifests (custom-built libs)
#      b. Check RPM ownership and license (system libs, UBI/RHEL only)
#      c. Search filesystem for bundled LICENSE/COPYING files
#   3. Generate license files in .dist-info/:
#      - UBI_BUNDLED_LICENSES.txt (RPM-derived licenses)
#      - BUNDLED_LICENSES.txt (project licenses and fallback markers)
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
                    for file in "${artifact_path}"/*; do
                        [[ ! -f "$file" ]] && continue
                        local fname
                        fname=$(basename "$file")
                        if [[ "$fname" =~ ^(LICENSE|COPYING|LICENCE|COPYRIGHT|license|copying|licence|copyright)(\..*)?$ ]]; then
                            echo ""
                            cat "$file"
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

    # Search for the library in likely build and system locations
    local search_dirs=("$PWD" "${WORK_DIR:-$PWD}" /opt /usr/local /usr)
    local lib_path=""
    for s_dir in "${search_dirs[@]}"; do
        [[ ! -d "$s_dir" ]] && continue
        lib_path=$(find "$s_dir" -maxdepth 6 -name "$normalized" -type f 2>/dev/null | grep -v "\.whl" | head -1)
        [[ -n "$lib_path" ]] && break
    done

    [[ -z "$lib_path" ]] && return 1

    # Traverse upward looking for LICENSE/COPYING
    local dir
    dir=$(dirname "$lib_path")
    local depth=0
    local max_depth=10

    while [[ "$dir" != "/" ]] && [[ $depth -lt $max_depth ]]; do
        for file in "$dir"/*; do
            [[ ! -f "$file" ]] && continue
            local fname
            fname=$(basename "$file")
            if [[ "$fname" =~ ^(LICENSE|COPYING|LICENCE|COPYRIGHT|license|copying|licence|copyright)(\..*)?$ ]]; then
                cat "$file"
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
}

log_info "Bundled license utilities loaded"

