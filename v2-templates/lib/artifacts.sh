#!/bin/bash
# =============================================================================
# Artifact System Helper Functions
# =============================================================================
# Sourced automatically by python.sh when BUILD_DEPS or PROVIDES_ARTIFACT
# shell variables are set in the build script.
#
# Environment:
#   ARTIFACT_WORKSPACE - Set by execution engine to shared artifact location.
#                        Falls back to ${OUTPUT_DIR}/artifacts for local testing.
#
# Usage in scripts:
#   PROVIDES_ARTIFACT="mylib"           # This script builds an artifact
#   BUILD_DEPS="protobuf:v25.3 hdf5"    # This script needs artifacts
#
# See templates/docs/NATIVE_DEPENDENCIES.md for full documentation.
# =============================================================================

# ARTIFACT_WORKSPACE is set by the execution engine to a shared location
# that persists across builds in a run. Falls back for local testing.
: "${ARTIFACT_WORKSPACE:=${OUTPUT_DIR:-/tmp}/artifacts}"

# Ensure the workspace exists
mkdir -p "${ARTIFACT_WORKSPACE}" 2>/dev/null || true

# -----------------------------------------------------------------------------
# artifact_dir - Get path to artifact directory
# Usage: artifact_dir <name> [version]
# If version not specified, uses "default"
# -----------------------------------------------------------------------------
artifact_dir() {
    local name="$1"
    local version="${2:-default}"
    local ubi_ver="${UBI_VERSION:-}"
    if [[ -n "$ubi_ver" && "${ARTIFACT_WORKSPACE}" != */"${ubi_ver}"* ]]; then
        echo "${ARTIFACT_WORKSPACE}/${ubi_ver}/${name}/${version}"
    else
        echo "${ARTIFACT_WORKSPACE}/${name}/${version}"
    fi
}

# -----------------------------------------------------------------------------
# source_artifact - Source an artifact's environment
# Usage: source_artifact <name> [version]
# Returns: 0 if found and sourced, 1 if not found
# -----------------------------------------------------------------------------
source_artifact() {
    local name="$1"
    local version="${2:-}"
    local ubi_ver="${UBI_VERSION:-}"
    local artifact_base="${ARTIFACT_WORKSPACE}/${name}"

    if [[ -n "$ubi_ver" && "${ARTIFACT_WORKSPACE}" != */"${ubi_ver}"* && -d "${ARTIFACT_WORKSPACE}/${ubi_ver}/${name}" ]]; then
        artifact_base="${ARTIFACT_WORKSPACE}/${ubi_ver}/${name}"
    fi

    # If version specified, use it directly
    if [[ -n "$version" ]]; then
        local env_file="${artifact_base}/${version}/env.sh"
        if [[ -f "$env_file" ]]; then
            log_info "Sourcing artifact ${name}:${version}"
            source "$env_file"
            return 0
        fi
        # Try stripping leading 'v'
        if [[ "$version" == v* ]]; then
            local stripped_version="${version#v}"
            local stripped_env_file="${artifact_base}/${stripped_version}/env.sh"
            if [[ -f "$stripped_env_file" ]]; then
                log_info "Sourcing artifact ${name}:${stripped_version}"
                source "$stripped_env_file"
                return 0
            fi
        fi
        # Try prepending 'v'
        if [[ "$version" != v* ]]; then
            local prepended_version="v${version}"
            local prepended_env_file="${artifact_base}/${prepended_version}/env.sh"
            if [[ -f "$prepended_env_file" ]]; then
                log_info "Sourcing artifact ${name}:${prepended_version}"
                source "$prepended_env_file"
                return 0
            fi
        fi
        log_error "Artifact not found: ${name}:${version}"
        log_error "Expected: ${env_file}"
        return 1
    fi

    # No version specified - find any available version
    local latest_env=""
    for env_file in "${artifact_base}"/*/env.sh; do
        [[ -f "$env_file" ]] && latest_env="$env_file"
    done

    if [[ -n "$latest_env" ]]; then
        log_info "Sourcing artifact ${name} from $(dirname "$latest_env")"
        source "$latest_env"
        return 0
    fi

    log_error "No artifact found for: ${name}"
    log_error "Searched: ${artifact_base}/*/env.sh"
    return 1
}

# -----------------------------------------------------------------------------
# artifact_exists - Check if an artifact exists
# Usage: artifact_exists <name> [version]
# Returns: 0 if exists, 1 if not
# -----------------------------------------------------------------------------
artifact_exists() {
    local name="$1"
    local version="${2:-}"
    local ubi_ver="${UBI_VERSION:-}"
    local artifact_base="${ARTIFACT_WORKSPACE}/${name}"

    if [[ -n "$ubi_ver" && "${ARTIFACT_WORKSPACE}" != */"${ubi_ver}"* && -d "${ARTIFACT_WORKSPACE}/${ubi_ver}/${name}" ]]; then
        artifact_base="${ARTIFACT_WORKSPACE}/${ubi_ver}/${name}"
    fi

    if [[ -n "$version" ]]; then
        if [[ -f "${artifact_base}/${version}/env.sh" ]]; then
            return 0
        fi
        if [[ "$version" == v* ]]; then
            local stripped_version="${version#v}"
            if [[ -f "${artifact_base}/${stripped_version}/env.sh" ]]; then
                return 0
            fi
        fi
        if [[ "$version" != v* ]]; then
            local prepended_version="v${version}"
            if [[ -f "${artifact_base}/${prepended_version}/env.sh" ]]; then
                return 0
            fi
        fi
        return 1
    else
        # Check for any version
        local found=false
        for env_file in "${artifact_base}"/*/env.sh; do
            [[ -f "$env_file" ]] && found=true && break
        done
        $found
    fi
}

# -----------------------------------------------------------------------------
# compute_artifact_recipe_sha - Compute deterministic recipe SHA for an artifact
# Usage: compute_artifact_recipe_sha <name> <version> [deps...]
# -----------------------------------------------------------------------------
compute_artifact_recipe_sha() {
    local name="$1"
    local version="$2"
    shift 2 2>/dev/null || true
    local dep_list=("$@")

    # 1. Determine build script path
    local script_file="${BUILD_SCRIPT:-}"
    if [[ -z "$script_file" || ! -f "$script_file" ]]; then
        local s_dir="${SCRIPT_DIR:-}"
        if [[ -n "$s_dir" && -d "$s_dir" ]]; then
            for candidate in "${BUILD_SCRIPT_NAME:-}" "${name}.sh" "$(basename "$s_dir").sh"; do
                if [[ -n "$candidate" && -f "${s_dir}/${candidate}" ]]; then
                    script_file="${s_dir}/${candidate}"
                    break
                fi
            done
        fi
    fi

    # 2. Extract BUILD_SCRIPT_DATE via git log on the build script file
    local build_script_date=""
    if [[ -n "$script_file" && -f "$script_file" ]] && command -v git &>/dev/null; then
        local s_dir="$(dirname "$script_file")"
        local s_base="$(basename "$script_file")"
        build_script_date=$(git -C "$s_dir" log -1 --format=%ci -- "$s_base" 2>/dev/null || echo "")
    fi

    if [[ -z "$build_script_date" ]]; then
        build_script_date="unknown"
    fi

    # 3. Determine package language
    local pkg_lang="${PACKAGE_LANGUAGE:-${LANGUAGE:-c++}}"

    # 4. Resolve build dependency hashes
    local dep_hashes=""
    local all_deps=()
    if [[ ${#dep_list[@]} -gt 0 ]]; then
        all_deps+=("${dep_list[@]}")
    fi
    if [[ -n "${BUILD_DEPS:-}" ]]; then
        for d in $(echo "$BUILD_DEPS" | tr ',' ' '); do
            [[ -n "$d" ]] && all_deps+=("$d")
        done
    fi

    if [[ ${#all_deps[@]} -gt 0 ]]; then
        local sorted_deps
        sorted_deps=$(printf '%s
' "${all_deps[@]}" | sort -u)
        local d_hashes=()
        for dep in $sorted_deps; do
            local dep_name="${dep%%:*}"
            local dep_ver="${dep#*:}"
            [[ "$dep_ver" == "$dep" ]] && dep_ver=""

            local d_sha=""
            for candidate_dir in "${ARTIFACT_WORKSPACE}/${dep_name}/${dep_ver}"                                  "${ARTIFACT_WORKSPACE}/${UBI_VERSION:-}/${dep_name}/${dep_ver}"                                  "${ARTIFACT_WORKSPACE}/${dep_name}"                                  "${ARTIFACT_WORKSPACE}/${UBI_VERSION:-}/${dep_name}"; do
                if [[ -f "${candidate_dir}/sha256.sha" ]]; then
                    d_sha=$(head -n1 "${candidate_dir}/sha256.sha" | awk '{print $1}')
                    break
                fi
            done
            if [[ -z "$d_sha" ]]; then
                d_sha=$(echo -n "${dep_name}:${dep_ver}" | sha256sum | awk '{print $1}' | cut -c1-16)
            fi
            d_hashes+=("$d_sha")
        done
        dep_hashes="${d_hashes[*]}"
    fi

    # 5. Build string_to_hash matching compute_recipe_sha pattern
    local base_str="${name}_${version}_${pkg_lang}_${build_script_date}"
    local string_to_hash="$base_str"
    if [[ -n "$dep_hashes" ]]; then
        string_to_hash="${base_str} ${dep_hashes}"
    fi

    echo -n "$string_to_hash" | sha256sum | awk '{print $1}'
}

# -----------------------------------------------------------------------------
# generate_artifact_manifest - Create manifest.json for an artifact
# Usage: generate_artifact_manifest <dir> <name> <version> <url> <license_spdx> [deps...]
# -----------------------------------------------------------------------------
generate_artifact_manifest() {
    local artifact_dir="$1"
    local name="$2"
    local version="$3"
    local git_url="${4:-}"
    local license_spdx="${5:-UNKNOWN}"
    shift 5
    local depends_on=("$@")

    local manifest_file="${artifact_dir}/manifest.json"
    local git_sha=""

    # Try to get git sha
    if command -v git &>/dev/null; then
        git_sha=$(git rev-parse HEAD 2>/dev/null || echo "")
    fi

    # Build depends_on JSON array
    local deps_json="[]"
    if [[ ${#depends_on[@]} -gt 0 ]] && command -v jq &>/dev/null; then
        deps_json=$(printf '%s\n' "${depends_on[@]}" | jq -R . | jq -s .)
    elif [[ ${#depends_on[@]} -gt 0 ]]; then
        # Fallback without jq
        deps_json="[\"${depends_on[*]// /\", \"}\"]"
    fi

    # Compute deterministic Recipe SHA
    local recipe_sha
    recipe_sha=$(compute_artifact_recipe_sha "${name}" "${version}" "${depends_on[@]}")

    # Generate manifest
    cat > "${manifest_file}" << EOF
{
  "name": "${name}",
  "version": "${version}",
  "recipe_sha": "${recipe_sha}",
  "git_sha": "${git_sha}",
  "git_url": "${git_url}",
  "build_date": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "build_host": "$(hostname -s 2>/dev/null || echo unknown)",
  "arch": "$(uname -m)",
  "distro": "${UBI_VERSION:-unknown}",
  "license_spdx": "${license_spdx}",
  "license_files": ["LICENSE"],
  "depends_on": ${deps_json}
}
EOF
    log_info "Generated manifest: ${manifest_file}"

    # Write deterministic Recipe SHA into sha256.sha
    echo "${recipe_sha}" > "${artifact_dir}/sha256.sha"
    log_info "Wrote recipe SHA to ${artifact_dir}/sha256.sha: ${recipe_sha}"
}

# -----------------------------------------------------------------------------
# cleanup_artifact_dir - Remove unnecessary files from artifact directory
# Usage: cleanup_artifact_dir <artifact_dir> [targets...]
# If no targets specified, defaults to "share" (man pages, docs, etc.)
#
# Examples:
#   cleanup_artifact_dir "${ARTIFACT_DIR}"              # removes share/
#   cleanup_artifact_dir "${ARTIFACT_DIR}" share        # removes share/
#   cleanup_artifact_dir "${ARTIFACT_DIR}" share bin    # removes share/ and bin/
# -----------------------------------------------------------------------------
cleanup_artifact_dir() {
    local artifact_dir="$1"
    shift
    local targets=("$@")

    # Default to cleaning share/ if no targets specified
    if [[ ${#targets[@]} -eq 0 ]]; then
        targets=("share")
    fi

    for target in "${targets[@]}"; do
        local target_path="${artifact_dir}/${target}"
        if [[ -d "${target_path}" ]]; then
            log_info "Cleaning artifact: removing ${target}/"
            rm -rf "${target_path}"
        fi
    done
}

# -----------------------------------------------------------------------------
# collect_dependency_licenses - Gather licenses from all used artifacts
# Usage: collect_dependency_licenses <output_dir>
# Called in post_build to collect licenses for wheel compliance
# -----------------------------------------------------------------------------
collect_dependency_licenses() {
    local output_dir="${1:-.}"
    local summary_file="${output_dir}/THIRD_PARTY_LICENSES.txt"

    mkdir -p "${output_dir}"

    echo "# Third-Party Licenses" > "${summary_file}"
    echo "" >> "${summary_file}"
    echo "Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "${summary_file}"
    echo "" >> "${summary_file}"

    local found_any=false

    # Check if jq is available for proper parsing
    if command -v jq &>/dev/null; then
        # Iterate through all artifact manifests (supporting both flat and ubi-nested workspaces)
        for manifest in "${ARTIFACT_WORKSPACE}"/*/*/manifest.json "${ARTIFACT_WORKSPACE}"/*/*/*/manifest.json; do
            [[ -f "$manifest" ]] || continue
            found_any=true

            local artifact_path=$(dirname "$manifest")
            local name=$(jq -r '.name // "unknown"' "$manifest")
            local version=$(jq -r '.version // "unknown"' "$manifest")
            local spdx=$(jq -r '.license_spdx // "UNKNOWN"' "$manifest")
            local git_url=$(jq -r '.git_url // ""' "$manifest")

            echo "## ${name} ${version}" >> "${summary_file}"
            echo "" >> "${summary_file}"
            echo "- SPDX License: ${spdx}" >> "${summary_file}"
            [[ -n "$git_url" ]] && echo "- Source: ${git_url}" >> "${summary_file}"
            echo "" >> "${summary_file}"

            # Copy license files
            for license_file in LICENSE LICENSE.txt LICENSE.md COPYING; do
                local src="${artifact_path}/${license_file}"
                if [[ -f "$src" ]]; then
                    local dest="${output_dir}/${name}-${spdx}.txt"
                    cp "$src" "$dest"
                    echo "License file: ${name}-${spdx}.txt" >> "${summary_file}"
                    break
                fi
            done

            echo "" >> "${summary_file}"
            echo "---" >> "${summary_file}"
            echo "" >> "${summary_file}"
        done
    else
        # Fallback without jq
        log_warn "jq not available, using basic license collection"
        for artifact_path in "${ARTIFACT_WORKSPACE}"/*/*/ "${ARTIFACT_WORKSPACE}"/*/*/*/; do
            [[ -d "$artifact_path" ]] || continue
            for license_file in "${artifact_path}"/LICENSE*; do
                if [[ -f "$license_file" ]]; then
                    found_any=true
                    local name=$(basename "$(dirname "$artifact_path")")
                    cp "$license_file" "${output_dir}/${name}-LICENSE.txt"
                    echo "## ${name}" >> "${summary_file}"
                    echo "License file: ${name}-LICENSE.txt" >> "${summary_file}"
                    echo "" >> "${summary_file}"
                fi
            done
        done
    fi

    if [[ "$found_any" == "false" ]]; then
        echo "No third-party dependency artifacts found." >> "${summary_file}"
    fi

    log_info "Collected licenses to ${output_dir}"
}

# -----------------------------------------------------------------------------
# Log that artifacts.sh was loaded (useful for debugging)
# -----------------------------------------------------------------------------
log_info "Artifact system loaded (ARTIFACT_WORKSPACE=${ARTIFACT_WORKSPACE})"

# =============================================================================
# AUTO-DETECT AND FIND LICENSE FILE
# =============================================================================
_find_license_file() {
    # If user specified a license file, use it
    if [[ -n "${LICENSE_FILE:-}" ]]; then
        if [[ -f "${LICENSE_FILE}" ]]; then
            echo "${LICENSE_FILE}"
            return 0
        fi
    fi

    # Auto-detect common license file names
    local license_names=(
        "LICENSE"
        "LICENSE.txt"
        "LICENSE.md"
        "LICENSE.MIT"
        "LICENSE.BSD"
        "LICENSE.APACHE"
        "COPYING"
        "COPYING.txt"
        "COPYING.md"
        "COPYING.LIB"
    )

    for name in "${license_names[@]}"; do
        if [[ -f "${name}" ]]; then
            echo "${name}"
            return 0
        fi
    done

    return 1
}

# =============================================================================
# STANDARD ARTIFACT CLEANUP
# =============================================================================
_cleanup_artifact() {
    local artifact_dir="$1"

    log_info "Cleaning up artifact directory"

    cleanup_artifact_dir "${artifact_dir}" share
    find "${artifact_dir}" -name '*.la' -delete 2>/dev/null || true
    find "${artifact_dir}" -type d -empty -delete 2>/dev/null || true
}

# =============================================================================
# COPY LICENSE FILE TO ARTIFACT
# =============================================================================
_copy_license() {
    local artifact_dir="$1"

    local license_file
    if license_file="$(_find_license_file)"; then
        log_info "Copying license file: ${license_file}"
        cp "${license_file}" "${artifact_dir}/LICENSE"
    else
        log_warn "No license file found. Create LICENSE manually if needed."
    fi
}

# =============================================================================
# GENERATE STANDARD env.sh
# =============================================================================
_generate_env_sh() {
    local artifact_dir="$1"
    local name="$2"
    local version="$3"

    local name_upper
    name_upper="$(echo "${name}" | tr '[:lower:]-' '[:upper:]_')"

    log_info "Generating env.sh for ${name} ${version}"

    cat > "${artifact_dir}/env.sh" << EOF
# ${name} ${version} environment
# Generated by template on $(date -u +%Y-%m-%dT%H:%M:%SZ)

export ${name_upper}_PREFIX="${artifact_dir}"

# Library paths (runtime and compile-time)
export LD_LIBRARY_PATH="${artifact_dir}/lib:\${LD_LIBRARY_PATH:-}"
export LIBRARY_PATH="${artifact_dir}/lib:\${LIBRARY_PATH:-}"

# Include path for headers
export CPATH="${artifact_dir}/include:\${CPATH:-}"

# pkg-config path
export PKG_CONFIG_PATH="${artifact_dir}/lib/pkgconfig:\${PKG_CONFIG_PATH:-}"
export CMAKE_PREFIX_PATH="\${${name_upper}_PREFIX}:\${CMAKE_PREFIX_PATH:-}"
EOF

    # Add lib64 paths if they exist
    if [[ -d "${artifact_dir}/lib64" ]]; then
        cat >> "${artifact_dir}/env.sh" << EOF

# lib64 paths (for packages that use lib64 instead of lib)
export LD_LIBRARY_PATH="${artifact_dir}/lib64:\${LD_LIBRARY_PATH:-}"
export LIBRARY_PATH="${artifact_dir}/lib64:\${LIBRARY_PATH:-}"
export PKG_CONFIG_PATH="${artifact_dir}/lib64/pkgconfig:\${PKG_CONFIG_PATH:-}"
EOF
    fi

    # Add bin to PATH if it exists and has executables
    if [[ -d "${artifact_dir}/bin" ]] && ls "${artifact_dir}/bin"/* >/dev/null 2>&1; then
        cat >> "${artifact_dir}/env.sh" << EOF

# Binary path
export PATH="${artifact_dir}/bin:\${PATH}"
EOF
    fi
}

