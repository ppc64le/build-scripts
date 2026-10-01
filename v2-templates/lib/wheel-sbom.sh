#!/bin/bash
# =============================================================================
# wheel-sbom.sh - Generate CycloneDX SBOM and CVE reports for Python wheels
# =============================================================================
# This library generates:
#   - CycloneDX 1.5 SBOM (machine-readable JSON)
#   - Summary JSON (CI/CD integration)
#   - CVE report JSON (vulnerabilities found)
#
# Usage:
#   source "${TEMPLATE_DIR}/lib/wheel-sbom.sh"
#   generate_wheel_sbom wheelhouse/*.whl
#
# Output files are written to ${OUTPUT_DIR}:
#   - <wheel_name>.sbom.json
#   - <wheel_name>.summary.json
#   - <wheel_name>.cves.json (if CVEs found)
#
# Design principles:
#   - NEVER fails/exits - always produces what it can
#   - Missing tools = warning, not error
#   - Missing licenses = red flag in output
#   - Local only - no internet fetches for license text
#
# See templates/docs/WHEEL_SBOM_STRATEGY.md for design details.
# =============================================================================

# Prevent multiple sourcing
[[ -n "$_WHEEL_SBOM_SH_SOURCED" ]] && return 0
_WHEEL_SBOM_SH_SOURCED=1

# =============================================================================
# CONFIGURATION
# =============================================================================

: "${OUTPUT_DIR:=${PWD}/output}"
: "${SBOM_SPEC_VERSION:=1.5}"

# Track issues for summary
declare -a _SBOM_WARNINGS=()
declare -a _SBOM_RED_FLAGS=()

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

# _sbom_warn: Record a warning (non-fatal issue)
_sbom_warn() {
    local msg="$1"
    _SBOM_WARNINGS+=("$msg")
    log_warn "[SBOM] $msg"
}

# _sbom_red_flag: Record a red flag (requires manual review)
_sbom_red_flag() {
    local msg="$1"
    _SBOM_RED_FLAGS+=("$msg")
    log_warn "[SBOM RED FLAG] $msg"
}

# _json_escape: Escape string for JSON
_json_escape() {
    local str="$1"
    # Escape backslashes, quotes, and control characters
    printf '%s' "$str" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/\t/\\t/g' | tr -d '\n\r'
}

# _normalize_so_name: Remove auditwheel hash from library filename
# Example: libgfortran-37ae8338.so.5.0.0 -> libgfortran.so.5.0.0
_normalize_so_name() {
    echo "$1" | sed -E 's/-[0-9a-f]{8,}(\.so)/\1/g'
}

# _compute_sha256: Compute SHA-256 hash of a file
_compute_sha256() {
    sha256sum "$1" 2>/dev/null | cut -d' ' -f1
}

# _generate_uuid: Generate a UUID (v4-like)
_generate_uuid() {
    if command -v uuidgen &>/dev/null; then
        uuidgen | tr '[:upper:]' '[:lower:]'
    else
        # Fallback using /dev/urandom
        od -x /dev/urandom | head -1 | awk '{OFS="-"; print $2$3,$4,$5,$6,$7$8$9}'
    fi
}

# _get_timestamp: Get ISO 8601 timestamp
_get_timestamp() {
    date -u +"%Y-%m-%dT%H:%M:%SZ"
}

# =============================================================================
# METADATA EXTRACTION
# =============================================================================

# _extract_wheel_metadata: Parse METADATA file from .dist-info
# Sets global variables: _META_NAME, _META_VERSION, _META_LICENSE, etc.
_extract_wheel_metadata() {
    local metadata_file="$1"

    _META_NAME=""
    _META_VERSION=""
    _META_LICENSE=""
    _META_LICENSE_EXPR=""
    _META_AUTHOR=""
    _META_HOMEPAGE=""
    _META_SUMMARY=""
    declare -g -a _META_REQUIRES=()
    declare -g -a _META_LICENSE_FILES=()

    if [[ ! -f "$metadata_file" ]]; then
        _sbom_warn "METADATA file not found: $metadata_file"
        return 1
    fi

    # Parse key-value pairs from METADATA (RFC 822 style headers)
    while IFS=: read -r key value; do
        # Trim whitespace
        key=$(echo "$key" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        value=$(echo "$value" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

        case "$key" in
            Name) _META_NAME="$value" ;;
            Version) _META_VERSION="$value" ;;
            License) _META_LICENSE="$value" ;;
            License-Expression) _META_LICENSE_EXPR="$value" ;;
            Author|Author-email) [[ -z "$_META_AUTHOR" ]] && _META_AUTHOR="$value" ;;
            Home-page) _META_HOMEPAGE="$value" ;;
            Summary) _META_SUMMARY="$value" ;;
            Requires-Dist) _META_REQUIRES+=("$value") ;;
        esac
    done < "$metadata_file"

    # Validate required fields
    if [[ -z "$_META_NAME" ]]; then
        _sbom_red_flag "Package name not found in METADATA"
        _META_NAME="UNKNOWN"
    fi
    if [[ -z "$_META_VERSION" ]]; then
        _sbom_red_flag "Package version not found in METADATA"
        _META_VERSION="0.0.0"
    fi

    return 0
}

# =============================================================================
# LICENSE HANDLING
# =============================================================================

# _is_clear_spdx_license: Check if license is a clear SPDX identifier
# Returns 0 if clear (no need for full text), 1 if ambiguous
_is_clear_spdx_license() {
    local license="$1"

    # Normalize to uppercase for comparison
    local lic_upper="${license^^}"

    # Clear SPDX identifiers that don't need full text
    case "$lic_upper" in
        MIT|ISC|UNLICENSE|CC0-1.0|WTFPL|0BSD)
            return 0
            ;;
        BSD-2-CLAUSE|BSD-3-CLAUSE|BSD-4-CLAUSE)
            return 0
            ;;
        APACHE-2.0|"APACHE LICENSE 2.0"|"APACHE LICENSE, VERSION 2.0")
            return 0
            ;;
        GPL-2.0|GPL-2.0-ONLY|GPL-2.0-OR-LATER)
            return 0
            ;;
        GPL-3.0|GPL-3.0-ONLY|GPL-3.0-OR-LATER)
            return 0
            ;;
        LGPL-2.1|LGPL-2.1-ONLY|LGPL-2.1-OR-LATER)
            return 0
            ;;
        LGPL-3.0|LGPL-3.0-ONLY|LGPL-3.0-OR-LATER)
            return 0
            ;;
        MPL-2.0|EPL-1.0|EPL-2.0)
            return 0
            ;;
        *)
            # AGPL needs version clarity, BSD needs clause clarity
            # Anything else is ambiguous
            return 1
            ;;
    esac
}

# _extract_license_text: Get full license text from wheel
# Outputs license text to stdout
_extract_license_text() {
    local dist_info="$1"
    local license_text=""

    # Look for LICENSE files in dist-info
    for pattern in LICENSE LICENSE.txt LICENSE.md COPYING COPYING.txt NOTICE; do
        local license_file="${dist_info}/${pattern}"
        if [[ -f "$license_file" ]]; then
            cat "$license_file"
            return 0
        fi
    done

    # Check for license files recorded in METADATA
    # (PEP 639 style: License-File: header)
    if [[ -f "${dist_info}/METADATA" ]]; then
        local license_files
        license_files=$(grep "^License-File:" "${dist_info}/METADATA" | cut -d: -f2 | xargs)
        for lf in $license_files; do
            local full_path="${dist_info}/${lf}"
            if [[ -f "$full_path" ]]; then
                cat "$full_path"
                return 0
            fi
        done
    fi

    return 1
}

# =============================================================================
# BINARY SCANNING
# =============================================================================

# _scan_wheel_binaries: Find all .so files and resolve provenance
# Populates _BINARIES array with JSON objects
_scan_wheel_binaries() {
    local wheel_dir="$1"
    declare -g -a _BINARIES=()

    local rpm_available=false
    if [[ -f /etc/redhat-release ]] && command -v rpm &>/dev/null; then
        rpm_available=true
    fi

    # Find all .so files
    while IFS= read -r -d '' so_file; do
        local filename=$(basename "$so_file")
        local normalized=$(_normalize_so_name "$filename")
        local rel_path="${so_file#${wheel_dir}/}"
        local sha256=$(_compute_sha256 "$so_file")
        local size=$(stat -c%s "$so_file" 2>/dev/null || echo "0")

        local source="unknown"
        local rpm_package=""
        local rpm_version=""
        local license=""

        # Try RPM provenance
        if [[ "$rpm_available" == "true" ]]; then
            # Search system paths for matching library
            local lib_path=""
            for search_dir in /usr/lib64 /usr/lib /lib64 /lib; do
                if [[ -f "${search_dir}/${normalized}" ]]; then
                    lib_path="${search_dir}/${normalized}"
                    break
                fi
            done

            if [[ -n "$lib_path" ]]; then
                rpm_package=$(rpm -qf "$lib_path" 2>/dev/null || echo "")
                if [[ -n "$rpm_package" && "$rpm_package" != *"not owned"* ]]; then
                    source="rpm"
                    license=$(rpm -q --qf "%{LICENSE}" "$rpm_package" 2>/dev/null || echo "")
                    # Extract version from RPM name (name-version-release.arch)
                    rpm_version=$(rpm -q --qf "%{VERSION}" "$rpm_package" 2>/dev/null || echo "")
                fi
            fi
        fi

        # If not from RPM, check artifact system
        if [[ "$source" == "unknown" && -d "${ARTIFACT_DIR:-/opt/artifacts}" ]]; then
            for artifact_path in "${ARTIFACT_DIR:-/opt/artifacts}"/*; do
                [[ ! -d "$artifact_path" ]] && continue
                if find "$artifact_path" -name "$normalized" -type f 2>/dev/null | grep -q .; then
                    source="artifact"
                    # Try to get license from manifest
                    if [[ -f "${artifact_path}/manifest.json" ]] && command -v jq &>/dev/null; then
                        license=$(jq -r '.license_spdx // empty' "${artifact_path}/manifest.json" 2>/dev/null || echo "")
                    fi
                    break
                fi
            done
        fi

        # If still unknown, mark as source-built
        if [[ "$source" == "unknown" ]]; then
            source="source-built"
        fi

        # Flag missing license as red flag
        if [[ -z "$license" ]]; then
            _sbom_red_flag "No license found for binary: $filename (source: $source)"
        fi

        # Build JSON object for this binary
        _BINARIES+=("{
            \"filename\": \"$(_json_escape "$filename")\",
            \"normalized_name\": \"$(_json_escape "$normalized")\",
            \"path_in_wheel\": \"$(_json_escape "$rel_path")\",
            \"sha256\": \"$sha256\",
            \"size\": $size,
            \"source\": \"$source\",
            \"rpm_package\": \"$(_json_escape "$rpm_package")\",
            \"rpm_version\": \"$(_json_escape "$rpm_version")\",
            \"license\": \"$(_json_escape "$license")\"
        }")

    done < <(find "$wheel_dir" -name "*.so*" -type f -print0 2>/dev/null)
}

# =============================================================================
# CVE DETECTION
# =============================================================================

# _run_pip_audit: Run pip-audit and capture results
# Returns JSON array of findings
_run_pip_audit() {
    local package_name="$1"
    local package_version="$2"

    # Check if pip-audit is available
    if ! command -v pip-audit &>/dev/null; then
        # Try to install it
        if ! pip install --quiet pip-audit 2>/dev/null; then
            _sbom_warn "pip-audit not available and could not be installed"
            echo "[]"
            return
        fi
    fi

    # Create temporary requirements file
    local req_file=$(mktemp)
    echo "${package_name}==${package_version}" > "$req_file"

    # Run pip-audit with timeout
    local result
    result=$(timeout 120 pip-audit -r "$req_file" --format json 2>/dev/null || echo "")

    rm -f "$req_file"

    if [[ -z "$result" ]]; then
        echo "[]"
        return
    fi

    # Extract vulnerabilities
    if command -v jq &>/dev/null; then
        echo "$result" | jq -c '[.dependencies[]? | select(.vulns | length > 0) | .vulns[] | {
            cve_id: .id,
            severity: (.aliases[0] // "UNKNOWN"),
            description: .description,
            fixed_versions: .fix_versions
        }]' 2>/dev/null || echo "[]"
    else
        echo "[]"
    fi
}

# _run_cve_bin_tool: Run cve-bin-tool on wheel
# Returns JSON array of findings
_run_cve_bin_tool() {
    local wheel_path="$1"

    # Check if cve-bin-tool is available
    if ! command -v cve-bin-tool &>/dev/null; then
        # Try to install it
        if ! pip install --quiet cve-bin-tool 2>/dev/null; then
            _sbom_warn "cve-bin-tool not available and could not be installed"
            echo "[]"
            return
        fi
    fi

    # Run cve-bin-tool with timeout
    local result
    result=$(timeout 300 cve-bin-tool --format json "$wheel_path" 2>/dev/null || echo "")

    if [[ -z "$result" ]]; then
        echo "[]"
        return
    fi

    # cve-bin-tool output varies by version, try to normalize
    if command -v jq &>/dev/null; then
        # Try to extract CVE data
        echo "$result" | jq -c 'if type == "array" then [.[] | select(.cve_number?) | {
            cve_id: .cve_number,
            severity: .severity,
            component: .product,
            component_version: .version
        }] else [] end' 2>/dev/null || echo "[]"
    else
        echo "[]"
    fi
}

# =============================================================================
# CYCLONEDX GENERATION
# =============================================================================

# _generate_cyclonedx: Generate CycloneDX 1.5 SBOM
_generate_cyclonedx() {
    local wheel_name="$1"
    local license_text="$2"

    local uuid=$(_generate_uuid)
    local timestamp=$(_get_timestamp)

    # Build components array
    local components="[]"
    if command -v jq &>/dev/null; then
        # Main package component
        local main_comp=$(cat <<EOF
{
    "type": "library",
    "bom-ref": "pkg:pypi/${_META_NAME}@${_META_VERSION}",
    "name": "$(_json_escape "$_META_NAME")",
    "version": "$(_json_escape "$_META_VERSION")",
    "purl": "pkg:pypi/$(_json_escape "$_META_NAME")@$(_json_escape "$_META_VERSION")"
}
EOF
)
        # Add license if available
        if [[ -n "$_META_LICENSE" ]]; then
            main_comp=$(echo "$main_comp" | jq --arg lic "$_META_LICENSE" '. + {licenses: [{license: {name: $lic}}]}')
        fi

        components=$(echo "[$main_comp]" | jq -c '.')

        # Add dependencies
        for req in "${_META_REQUIRES[@]}"; do
            # Parse requirement: name[extras]version_spec; marker
            local dep_name=$(echo "$req" | sed -E 's/^([a-zA-Z0-9_-]+).*/\1/')
            local dep_comp="{\"type\": \"library\", \"bom-ref\": \"pkg:pypi/${dep_name}\", \"name\": \"${dep_name}\"}"
            components=$(echo "$components" | jq --argjson comp "$dep_comp" '. + [$comp]')
        done

        # Add binary components
        for bin_json in "${_BINARIES[@]}"; do
            local bin_name=$(echo "$bin_json" | jq -r '.normalized_name')
            local bin_sha=$(echo "$bin_json" | jq -r '.sha256')
            local bin_source=$(echo "$bin_json" | jq -r '.source')
            local bin_license=$(echo "$bin_json" | jq -r '.license')

            local bin_comp=$(cat <<EOF
{
    "type": "library",
    "bom-ref": "pkg:generic/${bin_name}",
    "name": "${bin_name}",
    "hashes": [{"alg": "SHA-256", "content": "${bin_sha}"}],
    "properties": [{"name": "source", "value": "${bin_source}"}]
}
EOF
)
            if [[ -n "$bin_license" && "$bin_license" != "null" ]]; then
                bin_comp=$(echo "$bin_comp" | jq --arg lic "$bin_license" '. + {licenses: [{license: {name: $lic}}]}')
            fi
            components=$(echo "$components" | jq --argjson comp "$bin_comp" '. + [$comp]')
        done
    fi

    # Build vulnerabilities array
    local vulnerabilities="[]"
    if [[ ${#_CVE_FINDINGS[@]} -gt 0 ]] && command -v jq &>/dev/null; then
        for cve_json in "${_CVE_FINDINGS[@]}"; do
            vulnerabilities=$(echo "$vulnerabilities" | jq --argjson cve "$cve_json" '. + [$cve]')
        done
    fi

    # Generate full SBOM
    cat <<EOF
{
    "bomFormat": "CycloneDX",
    "specVersion": "${SBOM_SPEC_VERSION}",
    "serialNumber": "urn:uuid:${uuid}",
    "version": 1,
    "metadata": {
        "timestamp": "${timestamp}",
        "tools": [{
            "name": "wheel-sbom",
            "version": "1.0.0"
        }],
        "component": {
            "type": "library",
            "name": "$(_json_escape "$_META_NAME")",
            "version": "$(_json_escape "$_META_VERSION")",
            "purl": "pkg:pypi/$(_json_escape "$_META_NAME")@$(_json_escape "$_META_VERSION")"
        }
    },
    "components": ${components},
    "vulnerabilities": ${vulnerabilities}
}
EOF
}

# =============================================================================
# SUMMARY GENERATION
# =============================================================================

# _generate_summary: Generate CI-friendly summary JSON
_generate_summary() {
    local wheel_name="$1"
    local timestamp=$(_get_timestamp)

    local rpm_count=0
    local source_count=0
    local unknown_count=0
    local artifact_count=0

    for bin_json in "${_BINARIES[@]}"; do
        local source=$(echo "$bin_json" | jq -r '.source' 2>/dev/null || echo "unknown")
        case "$source" in
            rpm) ((++rpm_count)) ;;
            source-built) ((++source_count)) ;;
            artifact) ((++artifact_count)) ;;
            *) ((++unknown_count)) ;;
        esac
    done

    local cve_count=${#_CVE_FINDINGS[@]}
    local cve_critical=0
    local cve_high=0

    for cve_json in "${_CVE_FINDINGS[@]}"; do
        local severity=$(echo "$cve_json" | jq -r '.severity // "UNKNOWN"' 2>/dev/null | tr '[:lower:]' '[:upper:]')
        case "$severity" in
            CRITICAL) ((++cve_critical)) ;;
            HIGH) ((++cve_high)) ;;
        esac
    done

    local requires_review="false"
    if [[ ${#_SBOM_RED_FLAGS[@]} -gt 0 || $unknown_count -gt 0 || -z "$_META_LICENSE" || $cve_critical -gt 0 || $cve_high -gt 0 ]]; then
        requires_review="true"
    fi

    cat <<EOF
{
    "wheel": "$(_json_escape "$wheel_name")",
    "package": "$(_json_escape "${_META_NAME}==${_META_VERSION}")",
    "license": "$(_json_escape "${_META_LICENSE:-NOT_SPECIFIED}")",
    "license_expression": "$(_json_escape "${_META_LICENSE_EXPR:-}")",
    "dependencies": ${#_META_REQUIRES[@]},
    "bundled_binaries": ${#_BINARIES[@]},
    "binary_sources": {
        "rpm": ${rpm_count},
        "artifact": ${artifact_count},
        "source_built": ${source_count},
        "unknown": ${unknown_count}
    },
    "cves": {
        "total": ${cve_count},
        "critical": ${cve_critical},
        "high": ${cve_high}
    },
    "red_flags": ${#_SBOM_RED_FLAGS[@]},
    "warnings": ${#_SBOM_WARNINGS[@]},
    "requires_manual_review": ${requires_review},
    "generated_at": "${timestamp}"
}
EOF
}

# =============================================================================
# MAIN ENTRY POINT
# =============================================================================

# generate_wheel_sbom: Generate SBOM and CVE report for wheel(s)
# Arguments: wheel_path [wheel_path ...]
# Returns: Always 0 (never fails)
generate_wheel_sbom() {
    local wheel_paths=("$@")

    [[ ${#wheel_paths[@]} -eq 0 ]] && return 0

    # Ensure output directory exists
    mkdir -p "${OUTPUT_DIR}"

    # Check for jq (required for JSON generation)
    if ! command -v jq &>/dev/null; then
        log_warn "[SBOM] jq not available - SBOM generation will be limited"
    fi

    for wheel_path in "${wheel_paths[@]}"; do
        [[ ! -f "$wheel_path" ]] && continue

        local wheel_name=$(basename "$wheel_path")
        local wheel_base="${wheel_name%.whl}"

        log_info "[SBOM] Processing: ${wheel_name}"

        # Reset tracking arrays
        _SBOM_WARNINGS=()
        _SBOM_RED_FLAGS=()
        declare -g -a _CVE_FINDINGS=()

        # Create temp directory for extraction
        local temp_dir=$(mktemp -d)

        # Extract wheel
        if ! unzip -q "$wheel_path" -d "$temp_dir" 2>/dev/null; then
            _sbom_warn "Failed to extract wheel: ${wheel_name}"
            rm -rf "$temp_dir"
            continue
        fi

        # Find dist-info directory
        local dist_info=$(find "$temp_dir" -maxdepth 1 -type d -name "*.dist-info" | head -1)

        if [[ -z "$dist_info" ]]; then
            _sbom_warn "No .dist-info found in wheel: ${wheel_name}"
            rm -rf "$temp_dir"
            continue
        fi

        # Extract metadata
        _extract_wheel_metadata "${dist_info}/METADATA"

        # Get license text if needed
        local license_text=""
        if [[ -n "$_META_LICENSE" ]] && ! _is_clear_spdx_license "$_META_LICENSE"; then
            license_text=$(_extract_license_text "$dist_info")
            if [[ -z "$license_text" ]]; then
                _sbom_red_flag "License '${_META_LICENSE}' requires full text but none found"
            fi
        elif [[ -z "$_META_LICENSE" ]]; then
            _sbom_red_flag "No license declared in package metadata"
            # Still try to get license text
            license_text=$(_extract_license_text "$dist_info")
        fi

        # Scan binaries
        _scan_wheel_binaries "$temp_dir"

        log_info "[SBOM] Found ${#_BINARIES[@]} binary files"

        # Run CVE detection
        log_info "[SBOM] Running CVE detection..."

        local pip_audit_results=$(_run_pip_audit "$_META_NAME" "$_META_VERSION")
        local cve_bin_results=$(_run_cve_bin_tool "$wheel_path")

        # Merge CVE results
        if command -v jq &>/dev/null; then
            local all_cves=$(echo "[$pip_audit_results, $cve_bin_results]" | jq -c 'add | unique_by(.cve_id // .id)')
            while IFS= read -r cve; do
                [[ -n "$cve" && "$cve" != "null" ]] && _CVE_FINDINGS+=("$cve")
            done < <(echo "$all_cves" | jq -c '.[]' 2>/dev/null)
        fi

        log_info "[SBOM] Found ${#_CVE_FINDINGS[@]} CVE(s)"

        # Generate outputs
        local sbom_file="${OUTPUT_DIR}/${wheel_base}.sbom.json"
        local summary_file="${OUTPUT_DIR}/${wheel_base}.summary.json"
        local cves_file="${OUTPUT_DIR}/${wheel_base}.cves.json"

        # Generate CycloneDX SBOM
        _generate_cyclonedx "$wheel_name" "$license_text" > "$sbom_file"
        log_info "[SBOM] Generated: ${sbom_file}"

        # Generate summary
        _generate_summary "$wheel_name" > "$summary_file"
        log_info "[SBOM] Generated: ${summary_file}"

        # Generate CVE report if any found
        if [[ ${#_CVE_FINDINGS[@]} -gt 0 ]]; then
            if command -v jq &>/dev/null; then
                printf '%s\n' "${_CVE_FINDINGS[@]}" | jq -s '.' > "$cves_file"
            else
                echo "[" > "$cves_file"
                printf '%s,\n' "${_CVE_FINDINGS[@]}" | sed '$ s/,$//' >> "$cves_file"
                echo "]" >> "$cves_file"
            fi
            log_info "[SBOM] Generated: ${cves_file}"
        fi

        # Report summary
        if [[ ${#_SBOM_RED_FLAGS[@]} -gt 0 ]]; then
            log_warn "[SBOM] ${#_SBOM_RED_FLAGS[@]} red flag(s) - manual review required"
            for flag in "${_SBOM_RED_FLAGS[@]}"; do
                log_warn "  - $flag"
            done
        fi

        # Cleanup
        rm -rf "$temp_dir"

    done

    return 0
}

log_info "Wheel SBOM utilities loaded"
