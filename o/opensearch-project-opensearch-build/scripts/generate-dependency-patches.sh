#!/usr/bin/env bash
# =============================================================================
# generate-dependency-patches.sh — STAGE A (centralized patch generation)
#
# Generates one unified-diff patch per selected dependency-update target against
# the upstream gradle/libs.versions.toml of the component (fetched at the exact
# repository + ref listed in the opensearch-build manifest). Nothing is applied
# here; apply-dependency-patches.sh applies each patch later, when the matching
# component is checked out for building (STAGE B).
#
# Targets and what they patch:
#   opensearch -> OpenSearch checkout, gradle/libs.versions.toml
#   security   -> security checkout,   gradle/libs.versions.toml (all keys except OpenSAML keys)
#   opensaml   -> security checkout,   gradle/libs.versions.toml (keys: open_saml, open_saml_shib)
#                 OpenSAML is the libs:opensaml subproject of the security Gradle
#                 build and shares its catalog; it has no checkout of its own.
#
# Usage:
#   generate-dependency-patches.sh --manifest <opensearch-x.y.z.yml> --output-dir <dir> \
#       [--update <target>:<version-key>=<version>]...
#   Updates may also be given in $DEPENDENCY_UPDATES (comma/space/newline separated).
#   <version-key> is a key in the [versions] table of the catalog.
#   Example: --update security:guava=33.7.3-jre --update opensaml:open_saml=5.2.4
#
# Output: <dir>/<component>/<NN>-<target>.patch. Unselected targets produce no file.
# Patches for one component are cumulative and must be applied in file-name order.
# =============================================================================
set -euo pipefail

info()    { echo "[INFO] $*"; }
success() { echo "[SUCCESS] $*"; }
warn()    { echo "[WARN] $*" >&2; }
fail()    { echo "[ERROR] $*" >&2; exit 1; }
usage()   { sed -n '/^# Usage:/,/^# Output/p' "$0" | sed 's/^# \{0,1\}//' >&2; exit 1; }

CATALOG_REL="gradle/libs.versions.toml"
OPENSAML_KEYS=" open_saml open_saml_shib "

MANIFEST=""
OUTPUT_DIR=""
UPDATES=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --manifest)   [[ $# -ge 2 ]] || usage; MANIFEST="$2";   shift 2 ;;
        --output-dir) [[ $# -ge 2 ]] || usage; OUTPUT_DIR="$2"; shift 2 ;;
        --update)     [[ $# -ge 2 ]] || usage; UPDATES+=("$2");  shift 2 ;;
        -h|--help)    usage ;;
        *)            echo "[ERROR] Unknown option: $1" >&2; usage ;;
    esac
done

# Entries from the environment (Jenkins parameter), split on comma/space/newline.
if [[ -n "${DEPENDENCY_UPDATES:-}" ]]; then
    while IFS= read -r entry; do
        [[ -n "${entry}" ]] && UPDATES+=("${entry}")
    done < <(printf '%s\n' "${DEPENDENCY_UPDATES}" | tr ', \t' '\n\n\n' | tr -s '\n')
fi

[[ -n "${MANIFEST}" && -n "${OUTPUT_DIR}" ]] || { echo "[ERROR] --manifest and --output-dir are required" >&2; usage; }
[[ -f "${MANIFEST}" ]] || fail "Manifest not found: ${MANIFEST}"

# manifest_field <component> <field> — value of <field> under "- name: <component>".
manifest_field() {
    awk -v c="$1" -v f="$2" '
        $1 == "-" && $2 == "name:" { in_c = ($3 == c); next }
        in_c && $1 == f ":"        { print $2; exit }' "${MANIFEST}"
}

target_component() {
    case "$1" in
        opensearch)        echo "OpenSearch" ;;
        security|opensaml) echo "security" ;;
        *) return 1 ;;
    esac
}

# Fixed order = file-name prefix = apply order within a component.
target_prefix() {
    case "$1" in
        opensearch) echo "10" ;;
        security)   echo "10" ;;
        opensaml)   echo "20" ;;
    esac
}

# set_version <file> <key> <value> — rewrite one entry of the [versions] table.
set_version() {
    local file="$1" key="$2" value="$3" tmp
    tmp="$(mktemp)"
    awk -v k="${key}" -v v="${value}" '
        /^\[/ { sec = $0; sub(/[ \t]+$/, "", sec) }
        sec == "[versions]" && $0 !~ /^[ \t]*#/ {
            n = index($0, "=")
            if (n > 0) {
                name = substr($0, 1, n - 1); gsub(/[ \t]/, "", name)
                if (name == k) {
                    rest = substr($0, n + 1)
                    if (match(rest, /"[^"]*"/)) {
                        $0 = substr($0, 1, n) substr(rest, 1, RSTART - 1) "\"" v "\"" substr(rest, RSTART + RLENGTH)
                        found++
                    }
                }
            }
        }
        { print }
        END { if (found != 1) exit 1 }' "${file}" > "${tmp}" \
        || { rm -f "${tmp}"; fail "Key '${key}' not found exactly once in [versions] of the catalog"; }
    mv "${tmp}" "${file}"
}

# ---- parse + validate ------------------------------------------------------
info "Starting dependency patch generation."
if [[ ${#UPDATES[@]} -eq 0 ]]; then
    mkdir -p "${OUTPUT_DIR}"
    success "No dependency updates selected; no patches generated."
    exit 0
fi

PARSED=()   # "target|key|value"
for entry in "${UPDATES[@]}"; do
    [[ "${entry}" =~ ^([a-z]+):([A-Za-z0-9_.-]+)=([A-Za-z0-9._+-]+)$ ]] \
        || fail "Invalid update '${entry}'. Expected <target>:<version-key>=<version>"
    target="${BASH_REMATCH[1]}"; key="${BASH_REMATCH[2]}"; value="${BASH_REMATCH[3]}"
    target_component "${target}" >/dev/null \
        || fail "Unknown target '${target}' in '${entry}'. Valid: opensearch, security, opensaml"
    is_saml_key=false; [[ "${OPENSAML_KEYS}" == *" ${key} "* ]] && is_saml_key=true
    if [[ "${target}" == "opensaml" && "${is_saml_key}" == false ]]; then
        fail "'${key}' is not an OpenSAML key (allowed: ${OPENSAML_KEYS}); use the security target"
    fi
    if [[ "${target}" == "security" && "${is_saml_key}" == true ]]; then
        fail "'${key}' belongs to the opensaml target"
    fi
    for p in "${PARSED[@]:-}"; do
        [[ "${p}" == "${target}|${key}|"* ]] && fail "Duplicate update for ${target}:${key}"
    done
    PARSED+=("${target}|${key}|${value}")
done

# ---- generate --------------------------------------------------------------
WORK="$(mktemp -d)"
trap 'rm -rf "${WORK}"' EXIT
rm -rf "${OUTPUT_DIR}"
mkdir -p "${OUTPUT_DIR}"

for component in OpenSearch security; do
    # Selected updates for this component, in the fixed target order.
    targets=()
    case "${component}" in
        OpenSearch) order="opensearch" ;;
        security)   order="security opensaml" ;;
    esac
    for t in ${order}; do
        for p in "${PARSED[@]}"; do [[ "${p}" == "${t}|"* ]] && { targets+=("${t}"); break; }; done
    done
    [[ ${#targets[@]} -gt 0 ]] || continue

    repo="$(manifest_field "${component}" repository)"
    ref="$(manifest_field "${component}" ref)"
    [[ -n "${repo}" && -n "${ref}" ]] || fail "Component '${component}' (repository/ref) not found in ${MANIFEST}"

    info "Fetching ${component} baseline catalog from ${repo}@${ref}."
    git -C "${WORK}" init -q "${component}.git"
    git -C "${WORK}/${component}.git" fetch -q --depth 1 "${repo}" "${ref}" \
        || fail "Cannot fetch ${repo}@${ref}"
    cur="${WORK}/${component}.cur"
    git -C "${WORK}/${component}.git" show "FETCH_HEAD:${CATALOG_REL}" > "${cur}" \
        || fail "${CATALOG_REL} not found in ${repo}@${ref}"

    mkdir -p "${OUTPUT_DIR}/${component}"
    for t in "${targets[@]}"; do
        new="${WORK}/${component}.${t}.new"
        cp "${cur}" "${new}"
        for p in "${PARSED[@]}"; do
            IFS='|' read -r pt pk pv <<< "${p}"
            [[ "${pt}" == "${t}" ]] || continue
            info "  ${t}: ${pk} -> ${pv}"
            set_version "${new}" "${pk}" "${pv}"
        done
        patch="${OUTPUT_DIR}/${component}/$(target_prefix "${t}")-${t}.patch"
        if diff -u --label "a/${CATALOG_REL}" --label "b/${CATALOG_REL}" "${cur}" "${new}" > "${patch}"; then
            rm -f "${patch}"
            warn "${t}: requested versions already match upstream ${ref}; no patch generated"
        else
            success "Generated ${patch}"
        fi
        cp "${new}" "${cur}"   # next target's patch is cumulative on this one
    done
    rmdir "${OUTPUT_DIR}/${component}" 2>/dev/null || true
done

success "Dependency patch generation completed."
