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

readonly LICENSE_PATTERN='^(LICENSE|COPYING)(\..*)?$'
readonly LICENSE_SEPARATOR='----'

# Track missing licenses for reporting
declare -a _MISSING_LICENSES=()

# =============================================================================
# OS DETECTION
# =============================================================================

_is_rpm_available() {
    [[ -f /etc/redhat-release ]] && command -v rpm &>/dev/null
}

# =============================================================================
# LIBRARY NAME NORMALIZATION
# =============================================================================

# _normalize_so_name: Remove auditwheel hash from library filename
# Example: libgfortran-37ae8338.so.5.0.0 -> libgfortran.so.5.0.0
_normalize_so_name() {
    local original="$1"
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

                    # Collect all license files and join with LICENSE_SEPARATOR.
                    local artifact_license_files=()
                    for file in "${artifact_path}"/*; do
                        [[ ! -f "$file" ]] && continue
                        local fname
                        fname=$(basename "$file")
                        [[ "$fname" =~ $LICENSE_PATTERN ]] && artifact_license_files+=("$file")
                    done

                    local first=true
                    for lf in "${artifact_license_files[@]}"; do
                        [[ "$first" == "true" ]] && first=false || printf '\n\n%s\n\n' "$LICENSE_SEPARATOR"
                        cat "$lf"
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
    local normalized="$1"

    if ! _is_rpm_available; then
        return 1
    fi

    # Search for the library on the filesystem
    local lib_path
    lib_path=$(find /usr/lib64 /usr/lib /lib64 /lib -name "$normalized" -type f 2>/dev/null | head -1)

    [[ -z "$lib_path" ]] && return 1

    # Check RPM ownership
    local rpm_name
    if ! rpm_name=$(rpm -qf "$lib_path" 2>/dev/null) || [[ "$rpm_name" == *"not owned"* ]]; then
        return 1
    fi

    # Get license from RPM
    local license
    license=$(rpm -q --qf "%{LICENSE}\n" "$rpm_name" 2>/dev/null)

    if [[ -n "$license" ]] && [[ "$license" != "(none)" ]]; then
        echo "$license"
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
    local normalized="$1"

    # Search . first, fall back to / if nothing found — then filter site-packages.
    # If all found paths were in site-packages, report and return.
    local all_paths
    all_paths=$(find . -type f -name "$normalized" 2>/dev/null | grep -v "\.whl")
    [[ -z "$all_paths" ]] && all_paths=$(find / -type f -name "$normalized" 2>/dev/null | grep -v "\.whl")

    local lib_path
    lib_path=$(printf '%s' "$all_paths" | grep -v "site-packages" | head -1)
    if [[ -z "$lib_path" ]] && [[ -n "$all_paths" ]]; then
        log_error "All paths for ${normalized} were in site-packages, no valid build path found"
        return 1
    fi

    [[ -z "$lib_path" ]] && return 1

    # Walk up from the .so location; at the first directory containing license
    # file(s), collect all of them and join with LICENSE_SEPARATOR.
    local dir
    dir=$(dirname "$lib_path")
    local depth=0
    local max_depth=10

    while [[ "$dir" != "/" ]] && [[ $depth -lt $max_depth ]]; do
        local license_files=()
        for file in "$dir"/*; do
            [[ ! -f "$file" ]] && continue
            local fname
            fname=$(basename "$file")
            [[ "$fname" =~ $LICENSE_PATTERN ]] \
                && license_files+=("$file")
        done

        if [[ ${#license_files[@]} -gt 0 ]]; then
            local first=true
            for lf in "${license_files[@]}"; do
                [[ "$first" == "true" ]] && first=false || printf '\n\n%s\n\n' "$LICENSE_SEPARATOR"
                cat "$lf"
            done
            return 0
        fi

        dir=$(dirname "$dir")
        ((depth++))
    done

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

# _append_license_entry: Write a single grouped license entry to an output file.
# Separator and single/multi-line formatting match append_license_entry() in post_process_wheel.py.
# Arguments: out_file files_csv text_file
_append_license_entry() {
    local out_file="$1" files_val="$2" text_file="$3"
    local license_text
    license_text=$(cat "$text_file")

    [[ -s "$out_file" ]] && printf '\n\n\n%s\n\n\n\n' "$LICENSE_SEPARATOR" >> "$out_file"

    local stripped
    stripped=$(printf '%s' "$license_text" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    local line_count
    line_count=$(printf '%s\n' "$stripped" | wc -l)

    {
        printf 'Files: %s\n' "$files_val"
        if [[ $line_count -gt 1 ]]; then
            printf '\n%s' "$license_text"
            [[ "$license_text" != *$'\n' ]] && printf '\n'
        else
            printf 'License: %s\n' "$stripped"
        fi
    } >> "$out_file"
}

# _generate_license_files: Create license files in .dist-info
# Groups .so files sharing identical license text into a single entry,
# avoiding duplicate content across UBI_BUNDLED_LICENSES.txt and BUNDLED_LICENSES.txt.
# Arguments: wheel_dir dist_info_dir
_generate_license_files() {
    local wheel_dir="$1"
    local dist_info="$2"

    local ubi_licenses="${dist_info}/UBI_BUNDLED_LICENSES.txt"
    local bundled_licenses="${dist_info}/BUNDLED_LICENSES.txt"

    # Start both files empty so the first entry gets no leading separator.
    > "$ubi_licenses"
    > "$bundled_licenses"

    local has_ubi_licenses=false
    local has_bundled_licenses=false

    # Keyed by SHA256 of license text; values are space-separated .so filenames.
    # License text blobs are written to tmpdir/<prefix>_<key> to avoid multiline key issues.
    declare -A _ubi_files
    declare -A _bundled_files
    local tmpdir
    tmpdir=$(mktemp -d)

    # Pass 1: resolve each .so and accumulate filenames under the license text key.
    while IFS= read -r so_file; do
        [[ -z "$so_file" ]] && continue

        local so_name
        so_name=$(basename "$so_file")
        local normalized
        normalized=$(_normalize_so_name "$so_name")

        log_info "Processing bundled library: ${so_name}"

        local license_text key
        # Try RPM first — maps to rpm_licenses dict in post_process_wheel.py.
        if license_text=$(_resolve_license_from_rpm "$normalized"); then
            key=$(printf '%s' "$license_text" | sha256sum | cut -d' ' -f1)
            has_ubi_licenses=true
            [[ -z "${_ubi_files[$key]+x}" ]] && printf '%s' "$license_text" > "${tmpdir}/ubi_${key}"
            _ubi_files[$key]+="${_ubi_files[$key]:+, }${so_name}"
        # Try artifact system and filesystem — maps to bundled_licenses dict.
        elif license_text=$(_resolve_license_from_artifact "$so_name" "$normalized") || \
             license_text=$(_resolve_license_from_filesystem "$normalized"); then
            key=$(printf '%s' "$license_text" | sha256sum | cut -d' ' -f1)
            has_bundled_licenses=true
            [[ -z "${_bundled_files[$key]+x}" ]] && printf '%s' "$license_text" > "${tmpdir}/bundled_${key}"
            _bundled_files[$key]+="${_bundled_files[$key]:+, }${so_name}"
        else
            _MISSING_LICENSES+=("$so_name")
            has_bundled_licenses=true
            key=$(printf '%s' "${so_name}_license_not_found" | sha256sum | cut -d' ' -f1)
            printf '%s' "${so_name}_license_not_found" > "${tmpdir}/bundled_${key}"
            _bundled_files[$key]="$so_name"
            log_warn "License not found for: ${so_name}"
        fi
    done < <(_find_bundled_libs "$wheel_dir")

    # Pass 2: write one grouped entry per unique license text.
    for key in "${!_ubi_files[@]}"; do
        _append_license_entry "$ubi_licenses" "${_ubi_files[$key]}" "${tmpdir}/ubi_${key}"
    done

    for key in "${!_bundled_files[@]}"; do
        _append_license_entry "$bundled_licenses" "${_bundled_files[$key]}" "${tmpdir}/bundled_${key}"
    done

    rm -rf "$tmpdir"

    [[ "$has_ubi_licenses" != "true" ]] && rm -f "$ubi_licenses"
    [[ "$has_bundled_licenses" != "true" ]] && rm -f "$bundled_licenses"

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
