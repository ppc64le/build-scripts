#!/usr/bin/env bash
# =============================================================================
# build.sh — local equivalent of the Jenkinsfile pipeline
#
# Stages:
#   1. Clean workspace + podman prune
#   2. Checkout opensearch-build (tag <version>) and build-scripts 
#   3. Build the build-env image
#   4. Apply patch, run build.sh + assemble.sh inside container, copy dist tar
#   5. Build the final OpenSearch container image
#   6. Validate: smoke-test + ai-services compatibility check (non-fatal)
#   7. Run Trivy security scans (JSON + table), save reports to ARTIFACTS_DIR
#   8. Push image to ICR (versioned tag, optional release tag)
#
# Artifacts saved to ARTIFACTS_DIR (default: /var/jenkins/artifacts/opensearch):
#   - opensearch-<version>-linux-ppc64le.tar.gz    (assembled dist)
#   - trivy-report/trivy-results.json
#   - trivy-report/trivy-results.txt
#
# Usage:
#   export ICR_USER="<icr-user>"                   # versioned-image push
#   export ICR_PASSWORD="<icr-password>"
#   export IBM_CLOUD_APIKEY="<your-iam-api-key>"   # only for --push-release-tag
#   ./build.sh [--version <v>] [--push-release-tag] [--skip-push] [--skip-scan]
#              [--resume-from <stage>]
#
#   Flags:
#     --version <v>        OpenSearch version to build (default: $OPENSEARCH_VERSION
#                          or 3.10.0). Equivalent to the Jenkins OPENSEARCH_VERSION
#                          parameter.
#     --push-release-tag   Also tag and push <image>:<version>-ppc64le
#                          (Jenkins PUSH_RELEASE_TAG parameter)
#     --skip-push          Skip the ICR push stage
#     --skip-scan          Skip the Trivy scan stage
#     --update <t>:<k>=<v> Dependency update, repeatable (Jenkins DEPENDENCY_UPDATES
#                          parameter, comma/space separated, is also read).
#                          <t> = opensearch | security | opensaml,
#                          <k> = key in [versions] of gradle/libs.versions.toml.
#                          e.g. --update security:guava=33.7.3-jre
#                               --update opensaml:open_saml=5.2.4
#                          Stage A generates one patch per selected target; Stage B
#                          applies it when that component is checked out.
#     --resume-from <N>    Resume from stage N; useful after a failed run
#                          where earlier stages already succeeded.
#                          Stages: 1=clean 2=checkout 3=build-env 4=artifacts
#                                  5=container-image 6=validate 7=scan 8=push
#                          Example: --resume-from 5
#
#   Env overrides:
#     BUILD_NUMBER         Image tag suffix (default: local)
#     VALIDATE_SCRIPT      Path to ai-services validate.sh
#                          (default: ./test/opensearch/validate.sh)
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration (matches Jenkinsfile environment block)
# ---------------------------------------------------------------------------
OPENSEARCH_VERSION="${OPENSEARCH_VERSION:-3.10.0}"
ARCHITECTURE="ppc64le"
PLATFORM="linux"
BUILD_NUMBER="${BUILD_NUMBER:-local}"

# Where to persist final artifacts on the host
ARTIFACTS_DIR="${ARTIFACTS_DIR:-/var/jenkins/artifacts/opensearch}"

# Repositories
OPENSEARCH_BUILD_REPO="https://github.com/opensearch-project/opensearch-build.git"
BUILD_SCRIPTS_REPO="https://github.com/irapandey/build-scripts.git"
BUILD_SCRIPTS_BRANCH="opensearch-3.10"

# Working directories (everything lives under WORK_DIR; easy to wipe)
WORK_DIR="${WORK_DIR:-$(pwd)/workspace}"
BUILD_DIR="${WORK_DIR}/opensearch-build"
SCRIPTS_DIR="${WORK_DIR}/build-scripts"

# IBM Container Registry
# Pushes <version>-<arch>-<BUILD_NUMBER> for each run;
# also pushes <version>-<arch> when --push-release-tag is set.
ICR_REGISTRY="icr.io"
IMAGE_NAME="icr.io/ai-services-cicd/opensearch"

# Validation
VALIDATE_SCRIPT="${VALIDATE_SCRIPT:-$(pwd)/test/opensearch/validate.sh}"

# Trivy settings
TRIVY_IMAGE="ghcr.io/aquasecurity/trivy:0.72.0"
TRIVY_CACHE="${TRIVY_CACHE:-/var/jenkins/trivy-cache}"

# ---------------------------------------------------------------------------
# Flag defaults
# ---------------------------------------------------------------------------
DEPENDENCY_UPDATES="${DEPENDENCY_UPDATES:-}"
SKIP_PUSH=false
SKIP_SCAN=false
PUSH_RELEASE_TAG=false
RESUME_FROM=1

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
    case "$1" in
        --version)           OPENSEARCH_VERSION="$2"; shift 2 ;;
        --push-release-tag)  PUSH_RELEASE_TAG=true;   shift ;;
        --skip-push)         SKIP_PUSH=true;          shift ;;
        --skip-scan)         SKIP_SCAN=true;          shift ;;
        --update)            DEPENDENCY_UPDATES="${DEPENDENCY_UPDATES:+${DEPENDENCY_UPDATES},}$2"; shift 2 ;;
        --resume-from)       RESUME_FROM="$2";        shift 2 ;;
        *)
            echo "Unknown option: $1" >&2
            echo "Usage: $0 [--version <v>] [--push-release-tag] [--skip-push] [--skip-scan] [--update <target>:<key>=<version>]... [--resume-from <1|2|3|4|5|6|7|8>]" >&2
            exit 1
            ;;
    esac
done

# ---------------------------------------------------------------------------
# Version-derived values (matches Jenkinsfile 'Prepare' stage)
# ---------------------------------------------------------------------------
OPENSEARCH_BUILD_BRANCH="${OPENSEARCH_VERSION}"   # checked out as a tag
DOCKERFILE_DIR="o/opensearch-project-opensearch-build/Dockerfiles/${OPENSEARCH_VERSION}_ubi9.7"
PATCH_FILE="${DOCKERFILE_DIR}/ppc64le-${OPENSEARCH_VERSION}-ai-services.patch"
# Hook that applies generated dependency patches per component at checkout time
# (applied after PATCH_FILE; it does nothing unless dependency updates are selected).
DEPS_PATCH_FILE="${DOCKERFILE_DIR}/ppc64le-${OPENSEARCH_VERSION}-dependency-patches.patch"
# Dependency patch scripts (Stage A generate / Stage B apply)
DEP_SCRIPTS_REL="o/opensearch-project-opensearch-build/scripts"
# Stage A output, mounted into the build container
DEP_PATCHES_DIR="${WORK_DIR}/dependency-patches"
BUILD_ENV_IMAGE="opensearch-build-env:${OPENSEARCH_VERSION}-ppc64le"
BUILD_ENV_DOCKERFILE="${DOCKERFILE_DIR}/Dockerfile.build-env"
IMAGE_TAG="${OPENSEARCH_VERSION}-${ARCHITECTURE}-${BUILD_NUMBER}"
RELEASE_TAG="${IMAGE_NAME}:${OPENSEARCH_VERSION}-${ARCHITECTURE}"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
log()  { echo -e "\n\033[1;36m>>> [$(date '+%H:%M:%S')] $*\033[0m"; }
ok()   { echo -e "\033[1;32m    ✔ $*\033[0m"; }
warn() { echo -e "\033[1;33m    ⚠ $*\033[0m"; }
die()  { echo -e "\033[1;31m    ✘ $*\033[0m" >&2; exit 1; }

# Ordered stage list — used to resolve --resume-from comparisons.
STAGE_ORDER=(1 2 3 4 5 6 7 8)

stage_index() {
    local s="$1" i=0
    for stage in "${STAGE_ORDER[@]}"; do
        if [[ "$stage" == "$s" ]]; then echo "$i"; return; fi
        (( i++ ))
    done
    echo "-1"
}

# Validate RESUME_FROM after helpers are defined (checked at first call below).
_RESUME_IDX=""
_validate_resume_from() {
    if [[ -z "${_RESUME_IDX}" ]]; then
        _RESUME_IDX=$(stage_index "${RESUME_FROM}")
        [[ "${_RESUME_IDX}" -ge 0 ]] || \
            die "Invalid --resume-from value '${RESUME_FROM}'. Valid: 1 2 3 4 5 6 7 8"
    fi
}

stage_should_run() {
    # Returns 0 (true) when this stage's index >= the resume-from stage's index
    _validate_resume_from
    local this_idx
    this_idx=$(stage_index "$1")
    [[ "${this_idx}" -ge "${_RESUME_IDX}" ]]
}

log "OpenSearch version : ${OPENSEARCH_VERSION}"
echo "    Build-scripts branch: ${BUILD_SCRIPTS_BRANCH}"
echo "    Dockerfile dir      : ${DOCKERFILE_DIR}"
echo "    Image tag           : ${IMAGE_NAME}:${IMAGE_TAG}"

# ---------------------------------------------------------------------------
# Stage 1 — Clean workspace + reclaim podman space
# ---------------------------------------------------------------------------
if stage_should_run 1; then
    log "STAGE 1 — Clean workspace"

    log "  Reclaiming Podman space..."
    podman system prune --force --volumes
    podman image prune --force --all --filter "label!=keep" || true

    echo "=== Disk after prune ==="
    df -h /

    log "  Removing previous workspace: ${WORK_DIR}"
    rm -rf "${WORK_DIR}"
    mkdir -p "${WORK_DIR}"

    ok "Stage 1 complete"
fi

# ---------------------------------------------------------------------------
# Stage 2 — Checkout sources
# ---------------------------------------------------------------------------
if stage_should_run 2; then
    log "STAGE 2 — Checkout sources"

    log "  Cloning opensearch-build @ tag ${OPENSEARCH_BUILD_BRANCH}..."
    mkdir -p "${BUILD_DIR}"
    git clone --depth=1 \
        --branch "${OPENSEARCH_BUILD_BRANCH}" \
        "${OPENSEARCH_BUILD_REPO}" \
        "${BUILD_DIR}"

    log "  Cloning build-scripts @ branch ${BUILD_SCRIPTS_BRANCH}..."
    mkdir -p "${SCRIPTS_DIR}"
    git clone --depth=1 \
        --branch "${BUILD_SCRIPTS_BRANCH}" \
        "${BUILD_SCRIPTS_REPO}" \
        "${SCRIPTS_DIR}"

    ok "Stage 2 complete"
fi

# ---------------------------------------------------------------------------
# Stage 3 — Build the build-env container image
# ---------------------------------------------------------------------------
if stage_should_run 3; then
    log "STAGE 3 — Build build-env image"

    echo "=== Disk space ==="
    df -h
    echo "=== Memory ==="
    free -h
    echo "=== Podman disk usage ==="
    podman system df || true

    podman build \
        -t "${BUILD_ENV_IMAGE}" \
        -f "${SCRIPTS_DIR}/${BUILD_ENV_DOCKERFILE}" \
        "${BUILD_DIR}"

    ok "Stage 3 complete — image: ${BUILD_ENV_IMAGE}"
fi

# ---------------------------------------------------------------------------
# Stage 4 — Apply patch, build artifacts, assemble dist, copy to host
# ---------------------------------------------------------------------------
if stage_should_run 4; then
    log "STAGE 4 — Build artifacts and assemble distribution (selected components)"

    log "  Applying patch..."
    git config --global user.name "OpenSearch Build"
    git config --global user.email "opensearch-build@example.com"

    # `git apply` is used instead of `git am` to avoid "corrupt patch" failures
    # that occur with new-file diffs in shallow (--depth=1) clones.
    git -C "${BUILD_DIR}" apply \
        --whitespace=nowarn \
        "${SCRIPTS_DIR}/${PATCH_FILE}"

    log "  Applying dependency-patch hook..."
    git -C "${BUILD_DIR}" apply \
        --whitespace=nowarn \
        "${SCRIPTS_DIR}/${DEPS_PATCH_FILE}"

    # Stage A — centralized generation. Nothing is applied here; Stage B runs inside
    # opensearch-build when each component is checked out (BuilderFromSource.checkout).
    log "  Stage A: generating dependency patches..."
    export DEPENDENCY_UPDATES
    bash "${SCRIPTS_DIR}/${DEP_SCRIPTS_REL}/generate-dependency-patches.sh" \
        --manifest   "${BUILD_DIR}/manifests/${OPENSEARCH_VERSION}/opensearch-${OPENSEARCH_VERSION}.yml" \
        --output-dir "${DEP_PATCHES_DIR}"

    log "  Running OpenSearch build + assemble inside container..."
    # Scripts and generated patches are mounted read-only.
    podman run --rm \
        --ulimit nproc=65536:65536 \
        -v "${BUILD_DIR}:/opensearch-build:z" \
        -v "${SCRIPTS_DIR}/${DEP_SCRIPTS_REL}:/ppc-scripts:ro,z" \
        -v "${DEP_PATCHES_DIR}:/ppc-dependency-patches:ro,z" \
        -e PPC_DEPENDENCY_PATCHES_DIR=/ppc-dependency-patches \
        -e PPC_APPLY_DEPENDENCY_PATCHES=/ppc-scripts/apply-dependency-patches.sh \
        -w /opensearch-build \
        --entrypoint '' \
        "${BUILD_ENV_IMAGE}" \
        bash -c 'set -euo pipefail && \
            ./build.sh \
                manifests/'"${OPENSEARCH_VERSION}"'/opensearch-'"${OPENSEARCH_VERSION}"'.yml \
                --platform '"${PLATFORM}"' \
                --architecture '"${ARCHITECTURE}"' \
                --component OpenSearch \
                    common-utils \
                    opensearch-remote-metadata-sdk \
                    job-scheduler \
                    security \
                    custom-codecs \
                    k-NN \
                    ml-commons \
                    neural-search \
                    opensearch-observability \
                    index-management && \
            ./assemble.sh tar/builds/opensearch/manifest.yml'

    log "  Copying assembled tar to host..."
    mkdir -p "${ARTIFACTS_DIR}"
    cp "${BUILD_DIR}/tar/dist/opensearch/opensearch-${OPENSEARCH_VERSION}-linux-${ARCHITECTURE}.tar.gz" \
        "${ARTIFACTS_DIR}/opensearch-${OPENSEARCH_VERSION}-linux-${ARCHITECTURE}.tar.gz"

    ok "Stage 4 complete — tar at ${ARTIFACTS_DIR}/opensearch-${OPENSEARCH_VERSION}-linux-${ARCHITECTURE}.tar.gz"
fi

# ---------------------------------------------------------------------------
# Stage 5 — Build final container image
# ---------------------------------------------------------------------------
if stage_should_run 5; then
    log "STAGE 5 — Build container image"

    DOCKER_CONTEXT="${WORK_DIR}/docker-context"
    rm -rf "${DOCKER_CONTEXT}"
    mkdir -p "${DOCKER_CONTEXT}"

    # Dockerfile and supporting files from build-scripts
    cp -r "${SCRIPTS_DIR}/${DOCKERFILE_DIR}/"* "${DOCKER_CONTEXT}/"

    # Entrypoint scripts and configs from opensearch-build repo
    cp "${BUILD_DIR}/docker/release/config/opensearch/opensearch-docker-entrypoint-"*.x.sh "${DOCKER_CONTEXT}/"
    cp "${BUILD_DIR}/docker/release/config/opensearch/log4j2.properties"               "${DOCKER_CONTEXT}/"
    cp "${BUILD_DIR}/scripts/opensearch-onetime-setup.sh"                              "${DOCKER_CONTEXT}/"
    cp "${BUILD_DIR}/config/opensearch.yml"                                            "${DOCKER_CONTEXT}/"

    # Assembled tarball — rename to what the Dockerfile expects
    cp "${BUILD_DIR}/tar/dist/opensearch/opensearch-${OPENSEARCH_VERSION}-linux-${ARCHITECTURE}.tar.gz" \
        "${DOCKER_CONTEXT}/opensearch-ppc64le.tgz"

    BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    podman build \
        --build-arg "VERSION=${OPENSEARCH_VERSION}" \
        --build-arg "BUILD_DATE=${BUILD_DATE}" \
        --build-arg "UID=1000" \
        --build-arg "GID=1000" \
        -f "${DOCKER_CONTEXT}/Dockerfile.ais" \
        -t "${IMAGE_NAME}:${IMAGE_TAG}" \
        "${DOCKER_CONTEXT}"

    ok "Stage 5 complete — image: ${IMAGE_NAME}:${IMAGE_TAG}"
fi

# ---------------------------------------------------------------------------
# Stage 6 — Validate: smoke-test + ai-services compatibility check
# Non-fatal (matches Jenkins catchError): failures are reported as warnings
# and do not prevent the scan/push stages.
# ---------------------------------------------------------------------------
if stage_should_run 6; then
    log "STAGE 6 — Validate image"

    # Run in a fresh shell so `set -e` stays effective inside the `if !` test.
    if ! bash -euo pipefail -s -- \
            "opensearch-validate-${BUILD_NUMBER}" 9201 \
            "${IMAGE_NAME}:${IMAGE_TAG}" "${OPENSEARCH_VERSION}" <<'SMOKE'
CONTAINER_NAME="$1"
HTTP_PORT="$2"
IMAGE="$3"
EXPECTED_VERSION="$4"

cleanup() {
    podman stop "${CONTAINER_NAME}" >/dev/null 2>&1 || true
    podman rm   "${CONTAINER_NAME}" >/dev/null 2>&1 || true
}
fail() {
    echo "ERROR: $*" >&2
    podman logs "${CONTAINER_NAME}" || true
    exit 1
}
trap cleanup EXIT

echo "=== Starting OpenSearch container for smoke-test ==="
podman run -d \
    --name "${CONTAINER_NAME}" \
    --ulimit nofile=65536:65536 \
    --ulimit nproc=4096:4096 \
    -e "discovery.type=single-node" \
    -e "DISABLE_SECURITY_PLUGIN=true" \
    -p "127.0.0.1:${HTTP_PORT}:9200" \
    "${IMAGE}"

echo "=== Waiting for OpenSearch to become healthy (max 120 s) ==="
TIMEOUT=120
ELAPSED=0
until curl -s --max-time 10 -o /dev/null -w "%{http_code}" \
        "http://127.0.0.1:${HTTP_PORT}/_cluster/health" | grep -qE '^(200)'; do
    if [ "${ELAPSED}" -ge "${TIMEOUT}" ]; then
        fail "OpenSearch did not become healthy within ${TIMEOUT} seconds."
    fi
    echo "  ... waiting (${ELAPSED}s elapsed)"
    sleep 5
    ELAPSED=$((ELAPSED + 5))
done

echo "=== OpenSearch is healthy – running validation checks ==="

# 1. Cluster health must be green or yellow
HEALTH=$(curl -s --max-time 10 "http://127.0.0.1:${HTTP_PORT}/_cluster/health" \
    | python3 -c "import sys,json; print(json.load(sys.stdin)['status'])")
echo "Cluster health: ${HEALTH}"
if [ "${HEALTH}" != "green" ] && [ "${HEALTH}" != "yellow" ]; then
    fail "Unexpected cluster health status: ${HEALTH}"
fi

# 2. Version must match expected build
REPORTED_VERSION=$(curl -s --max-time 10 "http://127.0.0.1:${HTTP_PORT}/" \
    | python3 -c "import sys,json; print(json.load(sys.stdin)['version']['number'])")
echo "Reported OpenSearch version: ${REPORTED_VERSION}"
if [ "${REPORTED_VERSION}" != "${EXPECTED_VERSION}" ]; then
    fail "Version mismatch – expected ${EXPECTED_VERSION}, got ${REPORTED_VERSION}"
fi

echo "=== Smoke-test passed ==="
SMOKE
    then
        warn "Smoke-test failed (non-fatal) — continuing"
    elif [[ ! -f "${VALIDATE_SCRIPT}" ]]; then
        warn "validate.sh not found at ${VALIDATE_SCRIPT} — skipping ai-services compatibility check"
    else
        # Tests the exact ai-services RAG usage pattern (security plugin enabled,
        # hybrid search pipeline, HNSW/lucene k-NN index, bulk insert,
        # dense/sparse/hybrid search, delete_by_query).
        if bash "${VALIDATE_SCRIPT}" \
                --image   "${IMAGE_NAME}:${IMAGE_TAG}" \
                --version "${OPENSEARCH_VERSION}" \
                --port    9202 \
                --timeout 180; then
            ok "Stage 6 complete — validation passed"
        else
            warn "ai-services validation failed (non-fatal) — continuing"
        fi
    fi
fi

# ---------------------------------------------------------------------------
# Stage 7 — Trivy security scan
# ---------------------------------------------------------------------------
if stage_should_run 7 && [[ "${SKIP_SCAN}" == false ]]; then
    log "STAGE 7 — Trivy security scan"

    REPORT_DIR="${ARTIFACTS_DIR}/trivy-report"
    IMAGE_ARCHIVE="${REPORT_DIR}/image.tar"
    mkdir -p "${REPORT_DIR}" "${TRIVY_CACHE}"

    log "  Exporting ${IMAGE_NAME}:${IMAGE_TAG} to Docker archive..."
    podman save --format docker-archive -o "${IMAGE_ARCHIVE}" "${IMAGE_NAME}:${IMAGE_TAG}"

    log "  Running Trivy scan — JSON report..."
    podman run --rm \
        -v "${REPORT_DIR}:/report:z" \
        -v "${TRIVY_CACHE}:/root/.cache/trivy:z" \
        "${TRIVY_IMAGE}" image \
            --input /report/image.tar \
            --format json \
            --output /report/trivy-results.json \
            --severity CRITICAL,HIGH \
            --ignore-unfixed \
            --scanners vuln

    log "  Running Trivy scan — table report..."
    podman run --rm \
        -v "${REPORT_DIR}:/report:z" \
        -v "${TRIVY_CACHE}:/root/.cache/trivy:z" \
        "${TRIVY_IMAGE}" image \
            --input /report/image.tar \
            --format table \
            --output /report/trivy-results.txt \
            --severity CRITICAL,HIGH \
            --ignore-unfixed \
            --scanners vuln

    echo ""
    echo "=== Trivy Summary (CRITICAL/HIGH counts) ==="
    grep -E '"Severity"' "${REPORT_DIR}/trivy-results.json" \
        | sort | uniq -c | sort -rn || true

    # Remove the archive to reclaim disk space (matches Jenkinsfile)
    rm -f "${IMAGE_ARCHIVE}"

    ok "Stage 7 complete — reports at ${REPORT_DIR}/"
elif [[ "${SKIP_SCAN}" == true ]]; then
    warn "Stage 7 (Trivy scan) skipped via --skip-scan"
fi

# ---------------------------------------------------------------------------
# Stage 8 — Push image to ICR
# ---------------------------------------------------------------------------
if stage_should_run 8 && [[ "${SKIP_PUSH}" == false ]]; then
    log "STAGE 8 — Push image to ICR"

    if [[ -z "${ICR_USER:-}" || -z "${ICR_PASSWORD:-}" ]]; then
        die "ICR_USER / ICR_PASSWORD are not set. Export them before running, or use --skip-push."
    fi

    log "  Logging into ${ICR_REGISTRY}..."
    echo "${ICR_PASSWORD}" | podman login \
        -u "${ICR_USER}" \
        --password-stdin \
        "${ICR_REGISTRY}"

    log "  Pushing versioned image ${IMAGE_NAME}:${IMAGE_TAG}..."
    podman push "${IMAGE_NAME}:${IMAGE_TAG}"

    podman logout "${ICR_REGISTRY}"

    if [[ "${PUSH_RELEASE_TAG}" == true ]]; then
        if [[ -z "${IBM_CLOUD_APIKEY:-}" ]]; then
            die "IBM_CLOUD_APIKEY is not set. Export it, or omit --push-release-tag."
        fi

        log "  Tagging image as ${RELEASE_TAG}..."
        podman tag "${IMAGE_NAME}:${IMAGE_TAG}" "${RELEASE_TAG}"

        log "  Logging into ${ICR_REGISTRY} (release tag)..."
        echo "${IBM_CLOUD_APIKEY}" | podman login \
            -u iamapikey \
            --password-stdin \
            "${ICR_REGISTRY}"

        log "  Pushing release tag ${RELEASE_TAG}..."
        podman push "${RELEASE_TAG}"

        podman logout "${ICR_REGISTRY}"
    fi

    ok "Stage 8 complete — image pushed: ${IMAGE_NAME}:${IMAGE_TAG}"
elif [[ "${SKIP_PUSH}" == true ]]; then
    warn "Stage 8 (ICR push) skipped via --skip-push"
fi

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------
log "All stages complete."
echo ""
echo "  Dist tar   : ${ARTIFACTS_DIR}/opensearch-${OPENSEARCH_VERSION}-linux-${ARCHITECTURE}.tar.gz"
echo "  Trivy JSON : ${ARTIFACTS_DIR}/trivy-report/trivy-results.json"
echo "  Trivy TXT  : ${ARTIFACTS_DIR}/trivy-report/trivy-results.txt"
echo "  Image      : ${IMAGE_NAME}:${IMAGE_TAG}"
if [[ "${PUSH_RELEASE_TAG}" == true ]]; then
    echo "  Release tag: ${RELEASE_TAG}"
fi