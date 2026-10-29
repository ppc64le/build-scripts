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
#   # Single-pass postprocess wheel (licenses, retagging, metadata, SBOM)
#   postprocess_wheel_single_pass "/path/to/wheel.whl"
#
# Extensibility:
#   - WHEEL_CLASSIFIERS array: Add classifiers to inject
#   - custom_wheel_metadata() callback: Full control over metadata modifications
# =============================================================================

# Prevent multiple sourcing
[[ -n "$_WHEEL_UTILS_SH_SOURCED" ]] && return 0
_WHEEL_UTILS_SH_SOURCED=1

_WHEEL_UTILS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

    # Ensure output directory exists
    mkdir -p "$output_dir"

    # Ensure build and COS tools are available in active venv
    pip install --quiet --upgrade build wheel ibm-cos-sdk

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
# AUDITWHEEL EXCLUSIONS
# =============================================================================

# get_auditwheel_exclude_args: Generate --exclude arguments for auditwheel repair
# Usage: get_auditwheel_exclude_args [wheel_file]
# Reads exclusions from:
#   1. Package build_info.json ("auditwheel_exclude" array or string)
#   2. Script/Environment variable AUDITWHEEL_EXCLUDE
get_auditwheel_exclude_args() {
    local wheel_file="${1:-}"

    local build_info_file=""
    if [[ -n "${SCRIPT_DIR:-}" && -f "${SCRIPT_DIR}/build_info.json" ]]; then
        build_info_file="${SCRIPT_DIR}/build_info.json"
    elif [[ -n "${PACKAGE_DIR:-}" && -f "${PACKAGE_DIR}/build_info.json" ]]; then
        build_info_file="${PACKAGE_DIR}/build_info.json"
    elif [[ -f "build_info.json" ]]; then
        build_info_file="build_info.json"
    fi

    local env_exclude="${AUDITWHEEL_EXCLUDE:-}"

    python3 -c '
import json, sys, os

build_info_path = sys.argv[1]
env_exclude = sys.argv[2]

excludes = []

# 1. From build_info.json (top-level key only)
if build_info_path and os.path.exists(build_info_path):
    try:
        with open(build_info_path) as f:
            data = json.load(f)
        val = data.get("auditwheel_exclude") or data.get("auditwheel_exclude_libs") or []
        if isinstance(val, list):
            excludes.extend(val)
        elif isinstance(val, str):
            excludes.extend(val.split())
    except Exception:
        pass

# 2. From environment / script variable
if env_exclude:
    excludes.extend(env_exclude.split())

# 3. Deduplicate preserving order and format output
seen = set()
for item in excludes:
    item = str(item).strip()
    if item and item not in seen:
        seen.add(item)
        print("--exclude")
        print(item)
' "$build_info_file" "$env_exclude"
}

# =============================================================================
# AUDITWHEEL PLATFORM TAG & DISTRO DETECTION
# =============================================================================

# get_auditwheel_plat: Map OS/UBI major version to PEP 600 manylinux platform tag
# Reads from:
#   1. AUDITWHEEL_PLAT environment variable override (e.g. manylinux_2_34_ppc64le)
#   2. UBI_MAJOR environment variable
#   3. /etc/os-release (VERSION_ID)
# Returns: "manylinux_2_28_ppc64le", "manylinux_2_34_ppc64le", "manylinux_2_39_ppc64le", etc.
get_auditwheel_plat() {
    if [[ -n "${AUDITWHEEL_PLAT:-}" ]]; then
        echo "${AUDITWHEEL_PLAT}"
        return 0
    fi

    local ubi_major="${UBI_MAJOR:-}"
    if [[ -z "$ubi_major" && -f /etc/os-release ]]; then
        local version_id=""
        # shellcheck source=/dev/null
        . /etc/os-release
        version_id="${VERSION_ID:-}"
        ubi_major="${version_id%%.*}"
    fi

    case "$ubi_major" in
        8)
            echo "manylinux_2_28_ppc64le"
            ;;
        9)
            echo "manylinux_2_34_ppc64le"
            ;;
        10)
            echo "manylinux_2_39_ppc64le"
            ;;
        *)
            log_error "Unsupported UBI major version for auditwheel platform mapping: ${ubi_major:-unknown}"
            return 1
            ;;
    esac
}

# =============================================================================
# CONSOLIDATED SINGLE-PASS WHEEL POSTPROCESSING
# =============================================================================

# postprocess_wheel_single_pass: Consolidated single-pass wheel postprocessing
# Performs in a single extract-and-repack cycle:
#   1. Extract wheel (1 wheel unpack)
#   2. Bundled library license resolution & license file injection
#   3. PPC64LE rebuild suffix resolution (+ppc64leN PEP 440 local version)
#   4. Classifier injection & custom_wheel_metadata hook
#   5. CycloneDX SBOM & CVE report generation
#   6. Repack wheel (1 wheel pack - automatically recalculates PEP 376/427 RECORD)
# Usage: postprocess_wheel_single_pass "/path/to/wheel.whl" [target_dir]
# Returns: 0 on success, 1 on failure
postprocess_wheel_single_pass() {
    local wheel_path="$1"
    local target_dir="${2:-$(dirname "$wheel_path")}"

    if [[ ! -f "$wheel_path" ]]; then
        log_error "Wheel file not found: $wheel_path"
        return 1
    fi

    # Convert paths to absolute paths before cd'ing into temp_dir
    local wheel_dir_abs
    wheel_dir_abs="$(cd "$(dirname "$wheel_path")" && pwd)"
    local wheel_path_abs="${wheel_dir_abs}/$(basename "$wheel_path")"

    mkdir -p "$target_dir"
    local target_dir_abs
    target_dir_abs="$(cd "$target_dir" && pwd)"

    local wheel_name
    wheel_name=$(basename "$wheel_path")
    log_info "Single-pass postprocessing: ${wheel_name}"

    # Check for required wheel / extraction tools
    if ! python3 -c "import wheel" &>/dev/null && ! command -v unzip &>/dev/null; then
        log_warn "Neither 'wheel' python package nor 'unzip' available, skipping postprocessing"
        return 0
    fi

    # Ensure ibm-cos-sdk is available in active venv if COS credentials are provided
    if [[ -n "${COS_WHEEL_API_KEY:-${IBMCLOUD_API_KEY:-}}" ]] && ! python3 -c "import ibm_boto3" &>/dev/null; then
        pip install --quiet ibm-cos-sdk 2>/dev/null || true
    fi

    local temp_dir
    temp_dir=$(mktemp -d)
    local pkg_dir=""

    # 1. Unpack wheel using 'wheel unpack' (or fallback to unzip)
    if python3 -m wheel unpack "$wheel_path_abs" -d "$temp_dir" &>/dev/null; then
        pkg_dir=$(find "$temp_dir" -mindepth 1 -maxdepth 1 -type d | head -1)
    elif command -v unzip &>/dev/null; then
        if unzip -q "$wheel_path_abs" -d "$temp_dir" 2>/dev/null; then
            pkg_dir="$temp_dir"
        fi
    fi

    if [[ -z "$pkg_dir" || ! -d "$pkg_dir" ]]; then
        log_error "Failed to extract wheel: ${wheel_name}"
        rm -rf "$temp_dir"
        return 1
    fi

    # Locate .dist-info directory
    local dist_info
    dist_info=$(find "$pkg_dir" -maxdepth 1 -type d -name "*.dist-info" | head -1)

    if [[ -z "$dist_info" ]]; then
        log_error "No .dist-info directory found in wheel: ${wheel_name}"
        rm -rf "$temp_dir"
        return 1
    fi

    # 2. Bundled library license resolution
    if type -t _find_bundled_libs 2>/dev/null | grep -q "function" && \
       type -t _generate_license_files 2>/dev/null | grep -q "function"; then
        local libs_count
        libs_count=$(_find_bundled_libs "$pkg_dir" | wc -l)
        if [[ "$libs_count" -gt 0 ]]; then
            log_info "Processing bundled library licenses (${libs_count} libraries found)"
            _generate_license_files "$pkg_dir" "$dist_info"
        fi
    fi

    # 3. PPC64LE Rebuild Suffix Retagging (PEP 440 Local Version Identifier +ppc64leN)
    local final_wheel_name="$wheel_name"
    local retag_output
    if ! retag_output=$(python3 "${_WHEEL_UTILS_DIR}/wheel-postprocess.py" "$wheel_name" "$pkg_dir" "" "$wheel_path_abs"); then
        log_error "wheel-postprocess.py failed for ${wheel_name}"
        rm -rf "$temp_dir"
        return 1
    fi
    if [[ "$retag_output" == RENAME:* ]]; then
        final_wheel_name=$(echo "$retag_output" | cut -d: -f2)
        local new_dist_info_name=$(echo "$retag_output" | cut -d: -f3)
        dist_info="${pkg_dir}/${new_dist_info_name}"
        log_info "Retagged wheel with version: ${final_wheel_name}"
    fi

    # 4. Inject classifiers & run custom_wheel_metadata hook
    local metadata_file="${dist_info}/METADATA"
    if [[ -f "$metadata_file" ]]; then
        if [[ ${#WHEEL_CLASSIFIERS[@]} -gt 0 ]]; then
            _inject_classifiers "$metadata_file"
        fi
        if type -t custom_wheel_metadata 2>/dev/null | grep -q "function"; then
            log_info "Running custom_wheel_metadata hook..."
            custom_wheel_metadata "$metadata_file" "$pkg_dir"
        fi
    fi

    # 5. Generate CycloneDX SBOM & CVE reports
    if type -t generate_wheel_sbom_for_dir 2>/dev/null | grep -q "function"; then
        log_info "Generating SBOM and CVE reports for ${final_wheel_name}"
        generate_wheel_sbom_for_dir "$pkg_dir" "$dist_info" "$final_wheel_name" "$wheel_path_abs"
    fi

    # 6. Repack wheel once using 'wheel pack' (or fallback to zip)
    local final_wheel_path="${target_dir_abs}/${final_wheel_name}"
    local repack_success=1

    if python3 -m wheel pack "$pkg_dir" -d "$target_dir_abs" &>/dev/null; then
        repack_success=0
    elif command -v zip &>/dev/null; then
        if type -t _update_wheel_record 2>/dev/null | grep -q "function"; then
            _update_wheel_record "$pkg_dir" "$dist_info"
        fi
        local orig_dir="$PWD"
        cd "$pkg_dir"
        rm -f "$final_wheel_path"
        if zip -q -r "$final_wheel_path" .; then
            repack_success=0
        fi
        cd "$orig_dir"
    fi

    if [[ $repack_success -ne 0 ]]; then
        log_error "Failed to repack wheel: ${final_wheel_name}"
        rm -rf "$temp_dir"
        return 1
    fi

    # Remove old wheel if target is different name or location
    if [[ -f "$final_wheel_path" && "$wheel_path_abs" != "$final_wheel_path" ]]; then
        rm -f "$wheel_path_abs"
    fi

    rm -rf "$temp_dir"

    # 7. Generate recipe SHA256 and write to <wheel>.sha256
    generate_sha "" "" "$target_dir_abs" "$final_wheel_name" 2>/dev/null || true
    if [[ -n "${SHA256_VALUE:-}" ]]; then
        echo "$SHA256_VALUE" > "${final_wheel_path}.sha256"
        echo "$SHA256_VALUE" > "${target_dir_abs}/sha256.sha"
    fi

    log_info "Single-pass postprocessing complete: ${final_wheel_name}"
    return 0
}

# _inject_classifiers: Add classifiers to METADATA file
# Usage: _inject_classifiers metadata_file
# Internal function - uses WHEEL_CLASSIFIERS array
_inject_classifiers() {
    local metadata_file="$1"
    [[ ${#WHEEL_CLASSIFIERS[@]} -eq 0 ]] && return 0
    [[ ! -f "$metadata_file" ]] && return 1

    python3 -c '
import sys

meta_file = sys.argv[1]
classifiers = sys.argv[2:]

with open(meta_file, "r", encoding="utf-8") as f:
    lines = f.readlines()

existing = {line.strip() for line in lines}
to_add = [f"Classifier: {c}\n" for c in classifiers if f"Classifier: {c}" not in existing]

if to_add:
    classifier_indexes = [i for i, l in enumerate(lines) if l.startswith("Classifier:")]

    if classifier_indexes:
        insert_at = classifier_indexes[-1] + 1
    else:
        # Insert at the end of header block (before description)
        insert_at = len(lines)
        for i, l in enumerate(lines):
            if not l.strip():
                insert_at = i
                break

    lines[insert_at:insert_at] = to_add

    with open(meta_file, "w", encoding="utf-8") as f:
        f.writelines(lines)
' "$metadata_file" "${WHEEL_CLASSIFIERS[@]}"
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

# validate_wheel_version: Validate that a built wheel matches expected package version
# Usage: validate_wheel_version wheel_path [expected_version]
# Returns: 0 if valid, 1 if mismatch or dirty git hash
validate_wheel_version() {
    local wheel_path="$1"
    local expected_version="${2:-${GITHUB_PACKAGE_VERSION:-${PACKAGE_VERSION:-}}}"

    [[ -z "$expected_version" ]] && return 0
    [[ ! -f "$wheel_path" ]] && return 1

    local wheel_name
    wheel_name="$(basename "$wheel_path")"

    python3 "${_WHEEL_UTILS_DIR}/check-wheel-version.py" "$wheel_name" "$expected_version"
}

# =============================================================================
# BUILD RECIPE SHA256 GENERATION (matching create_wheel_wrapper.sh)
# =============================================================================

# generate_sha: Compute build-recipe SHA256 for wheel (matching create_wheel_wrapper.sh)
# Usage: generate_sha [build_script] [python_version] [cur_dir] [wheel_name]
generate_sha() {
    local build_script="${1:-${BUILD_SCRIPT:-${BUILD_SCRIPT_PATH:-}}}"
    local python_version="${2:-${PYTHON_VERSION:-}}"
    local cur_dir="${3:-$PWD}"
    local wheel="${4:-}"

    # Mark repo as safe (to avoid dubious ownership issue in containers)
    git config --global --add safe.directory "$cur_dir" 2>/dev/null || true

    if [[ -z "$build_script" && -n "${SCRIPT_DIR:-}" ]]; then
        local pkg_name="${PACKAGE_NAME:-}"
        if [[ -f "${SCRIPT_DIR}/${pkg_name}.sh" ]]; then
            build_script="${SCRIPT_DIR}/${pkg_name}.sh"
        elif [[ -f "${SCRIPT_DIR}/$(basename "$SCRIPT_DIR").sh" ]]; then
            build_script="${SCRIPT_DIR}/$(basename "$SCRIPT_DIR").sh"
        fi
    fi

    if [[ -z "$build_script" || ! -f "$build_script" ]]; then
        log_error "Build script not found: ${build_script:-empty}. Cannot determine recipe SHA."
        return 1
    fi

    local b_dir
    b_dir="$(dirname "$build_script")"
    local b_file
    b_file="$(basename "$build_script")"
    local build_script_date
    build_script_date=$(git -C "$b_dir" log -1 --format=%ci -- "$b_file" 2>/dev/null)
    : "${build_script_date:?Failed to determine BUILD_SCRIPT_DATE from git log for ${build_script}}"

    local package_language="${PACKAGE_LANGUAGE:-python}"
    local pkg_name="${PACKAGE_NAME:-}"
    local pkg_ver="${PACKAGE_VERSION:-}"

    # Resolve preloaded artifact SHAs for each build dependency
    local dep_hashes=""
    local raw_deps="${BUILD_DEPS:-}"
    if [[ -z "$raw_deps" && -n "${SCRIPT_DIR:-}" && -f "${SCRIPT_DIR}/build_info.json" ]] && command -v jq &>/dev/null; then
        raw_deps=$(jq -r --arg ver "$pkg_ver" '(.[$ver].build_deps // .build_deps // []) | join(" ")' "${SCRIPT_DIR}/build_info.json" 2>/dev/null || echo "")
    fi

    if [[ -n "$raw_deps" ]]; then
        local artifact_ws="${ARTIFACT_WORKSPACE:-/output/artifacts}"
        local ubi_ver="${UBI_VERSION:-}"
        local cand_bases=("${artifact_ws}")
        if [[ -n "$ubi_ver" && "${artifact_ws}" != */"${ubi_ver}"* ]]; then
            cand_bases=("${artifact_ws}/${ubi_ver}" "${artifact_ws}")
        fi
        local sorted_deps
        sorted_deps=$(echo "$raw_deps" | tr " ," "\n\n" | grep -v "^$" | sort -u)

        for dep_item in $sorted_deps; do
            local d_name="${dep_item%%:*}"
            local d_ver="${dep_item#*:}"
            [[ "$d_ver" == "$d_name" ]] && d_ver=""

            local d_hash=""
            local clean_ver="${d_ver#v}"

            # Look for sha256.sha in preloaded artifact dir
            for base_dir in "${cand_bases[@]}"; do
                for cand in "${base_dir}/${d_name}/${d_ver}/sha256.sha" \
                            "${base_dir}/${d_name}/${clean_ver}/sha256.sha" \
                            "${base_dir}/${d_name}/v${clean_ver}/sha256.sha" \
                            "${base_dir}/${d_name}/sha256.sha" \
                            "${base_dir}/${d_name}/${d_ver}/manifest.json" \
                            "${base_dir}/${d_name}/manifest.json"; do
                    if [[ -f "$cand" ]]; then
                        if [[ "$cand" == *.sha ]]; then
                            d_hash=$(head -n1 "$cand" | awk '{print $1}')
                        else
                            d_hash=$(sha256sum "$cand" 2>/dev/null | awk '{print $1}')
                        fi
                        [[ -n "$d_hash" ]] && break 2
                    fi
                done
            done

            # Fallback: hash dep spec string if artifact dir is unmounted
            if [[ -z "$d_hash" ]]; then
                d_hash=$(echo -n "${dep_item}" | sha256sum 2>/dev/null | awk '{print $1}' | cut -c1-16)
            fi

            if [[ -z "$dep_hashes" ]]; then
                dep_hashes="$d_hash"
            else
                dep_hashes="${dep_hashes} ${d_hash}"
            fi
        done
    fi

    local string_to_hash=""
    if [[ "$wheel" == *any.whl || "$wheel" == *abi3* || "$wheel" == *none* ]]; then
        string_to_hash="${pkg_name}_${pkg_ver}_${package_language}_${build_script_date}"
    else
        string_to_hash="${pkg_name}_${pkg_ver}_${package_language}_${python_version}_${build_script_date}"
    fi

    if [[ -n "$dep_hashes" ]]; then
        string_to_hash="${string_to_hash} ${dep_hashes}"
    fi

    local sha_value
    sha_value=$(echo -n "$string_to_hash" | sha256sum 2>/dev/null | awk '{print $1}')
    if [[ -z "$sha_value" ]]; then
        sha_value=$(python3 -c "import hashlib; print(hashlib.sha256('$string_to_hash'.encode('utf-8')).hexdigest())")
    fi

    echo "$sha_value" > "$cur_dir/sha256.sha"
    export SHA256_VALUE="$sha_value"

    log_info "SHA256 successfully generated for $string_to_hash"
    log_info "SHA256: $sha_value"
}


