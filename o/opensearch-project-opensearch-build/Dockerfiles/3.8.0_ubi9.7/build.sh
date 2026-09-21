#!/usr/bin/env bash
# =============================================================================
# build.sh — local equivalent of the Jenkinsfile pipeline
#
# Stages:
#   1. Clean workspace + podman prune
#   2. Checkout opensearch-build (tag 3.8.0) and build-scripts (opensearch-3.8.0)
#   3. Build the build-env image
#   4. Apply patch, run build.sh + assemble.sh inside container, copy dist tar
#      (jvector and prometheus-exporter are NOT in the main manifest and are
#       therefore NOT bundled into the assembled tarball)
#   4b. Build opensearch-jvector and opensearch-prometheus-exporter separately
#       using extra-plugins-3.8.0.yml; copy their zips to ARTIFACTS_DIR/plugin-zips/
#   5. Build the final OpenSearch container image
#      (plugin zips from 4b are placed in the image for optional installation)
#   6. Run Trivy security scans (JSON + table), save reports to ARTIFACTS_DIR
#   7. Push image to ICR (requires IBM_CLOUD_APIKEY env var)
#
# Artifacts saved to ARTIFACTS_DIR (default: /var/jenkins/artifacts/opensearch):
#   - opensearch-3.8.0-linux-ppc64le.tar.gz        (assembled dist; no extra plugins)
#   - plugin-zips/opensearch-jvector-*.zip
#   - plugin-zips/prometheus-exporter-*.zip
#   - trivy-report/trivy-results.json
#   - trivy-report/trivy-results.txt
#
# Usage:
#   export IBM_CLOUD_APIKEY="<your-iam-api-key>"
#   ./build.sh [--skip-push] [--skip-scan] [--resume-from <stage>]
#
#   Flags:
#     --skip-push          Skip the ICR push stage
#     --skip-scan          Skip the Trivy scan stage
#     --resume-from <N>    Resume from stage N; useful after a failed run
#                          where earlier stages already succeeded.
#                          Stages: 1=clean 2=checkout 3=build-env 4=artifacts
#                                  4b=extra-plugins 5=container-image 6=scan 7=push
#                          Example: --resume-from 4b
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration (matches Jenkinsfile environment block)
# ---------------------------------------------------------------------------
OPENSEARCH_VERSION="3.8.0"
ARCHITECTURE="ppc64le"
PLATFORM="linux"

# Where to persist final artifacts on the host
ARTIFACTS_DIR="${ARTIFACTS_DIR:-/var/jenkins/artifacts/opensearch}"

# Repositories
OPENSEARCH_BUILD_REPO="https://github.com/opensearch-project/opensearch-build.git"
OPENSEARCH_BUILD_BRANCH="3.8.0"   # checked out as a tag

BUILD_SCRIPTS_REPO="https://github.com/irapandey/build-scripts.git"
BUILD_SCRIPTS_BRANCH="opensearch-3.8.0"

# Working directories (everything lives under WORK_DIR; easy to wipe)
WORK_DIR="${WORK_DIR:-$(pwd)/workspace}"
BUILD_DIR="${WORK_DIR}/opensearch-build"
SCRIPTS_DIR="${WORK_DIR}/build-scripts"
#!/usr/bin/env bash
# =============================================================================
# build.sh — local equivalent of the Jenkinsfile pipeline
#
# Stages:
#   1. Clean workspace + podman prune
#   2. Checkout opensearch-build (tag 3.8.0) and build-scripts (opensearch-3.8.0)
#   3. Build the build-env image
#   4. Apply patch, run build.sh + assemble.sh inside container, copy dist tar
#      (jvector and prometheus-exporter are NOT in the main manifest and are
#       therefore NOT bundled into the assembled tarball)
#   4b. Build opensearch-jvector and opensearch-prometheus-exporter separately
#       using extra-plugins-3.8.0.yml; copy their zips to ARTIFACTS_DIR/plugin-zips/
#   5. Build the final OpenSearch container image
#      (plugin zips from 4b are placed in the image for optional installation)
#   6. Run Trivy security scans (JSON + table), save reports to ARTIFACTS_DIR
#   7. Push image to ICR (requires IBM_CLOUD_APIKEY env var)
#
# Artifacts saved to ARTIFACTS_DIR (default: /var/jenkins/artifacts/opensearch):
#   - opensearch-3.8.0-linux-ppc64le.tar.gz        (assembled dist; no extra plugins)
#   - plugin-zips/opensearch-jvector-*.zip
#   - plugin-zips/prometheus-exporter-*.zip
#   - trivy-report/trivy-results.json
#   - trivy-report/trivy-results.txt
#
# Usage:
#   export IBM_CLOUD_APIKEY="<your-iam-api-key>"
#   ./build.sh [--skip-push] [--skip-scan] [--resume-from <stage>]
#
#   Flags:
#     --skip-push          Skip the ICR push stage
#     --skip-scan          Skip the Trivy scan stage
#     --resume-from <N>    Resume from stage N; useful after a failed run
#                          where earlier stages already succeeded.
#                          Stages: 1=clean 2=checkout 3=build-env 4=artifacts
#                                  4b=extra-plugins 5=container-image 6=scan 7=push
#                          Example: --resume-from 4b
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration (matches Jenkinsfile environment block)
# ---------------------------------------------------------------------------
OPENSEARCH_VERSION="3.8.0"
ARCHITECTURE="ppc64le"
PLATFORM="linux"

# Where to persist final artifacts on the host
ARTIFACTS_DIR="${ARTIFACTS_DIR:-/var/jenkins/artifacts/opensearch}"

# Repositories
OPENSEARCH_BUILD_REPO="https://github.com/opensearch-project/opensearch-build.git"
OPENSEARCH_BUILD_BRANCH="3.8.0"   # checked out as a tag

BUILD_SCRIPTS_REPO="https://github.com/irapandey/build-scripts.git"
BUILD_SCRIPTS_BRANCH="opensearch-3.8.0"

# Working directories (everything lives under WORK_DIR; easy to wipe)
WORK_DIR="${WORK_DIR:-$(pwd)/workspace}"
BUILD_DIR="${WORK_DIR}/opensearch-build"
SCRIPTS_DIR="${WORK_DIR}/build-scripts"

# Paths inside build-scripts repo
PATCH_FILE="o/opensearch-project-opensearch-build/Dockerfiles/3.8.0_ubi9.7/ppc64le-3.8.0-ai-services.patch"
DOCKERFILE_DIR="o/opensearch-project-opensearch-build/Dockerfiles/3.8.0_ubi9.7"
# Build-env image name
BUILD_ENV_IMAGE="opensearch-build-env:3.8.0-ppc64le"
BUILD_ENV_DOCKERFILE="${DOCKERFILE_DIR}/Dockerfile.build-env"

# Final image
ICR_REGISTRY="icr.io"
IMAGE_NAME="icr.io/ai-services-private/opensearch:${OPENSEARCH_VERSION}-ppc64le-extended"

# Trivy settings
TRIVY_IMAGE="ghcr.io/aquasecurity/trivy:0.72.0"
TRIVY_CACHE="${TRIVY_CACHE:-/var/jenkins/trivy-cache}"

# ---------------------------------------------------------------------------
# Flag defaults
# ---------------------------------------------------------------------------
SKIP_PUSH=false
SKIP_SCAN=false
RESUME_FROM=1

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
    case "$1" in
        --skip-push)    SKIP_PUSH=true;   shift ;;
        --skip-scan)    SKIP_SCAN=true;   shift ;;
        --resume-from)  RESUME_FROM="$2"; shift 2 ;;
        *)
            echo "Unknown option: $1" >&2
            echo "Usage: $0 [--skip-push] [--skip-scan] [--resume-from <1|2|3|4|4b|5|6|7>]" >&2
            exit 1
            ;;
    esac
done

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
log()  { echo -e "\n\033[1;36m>>> [$(date '+%H:%M:%S')] $*\033[0m"; }
ok()   { echo -e "\033[1;32m    ✔ $*\033[0m"; }
warn() { echo -e "\033[1;33m    ⚠ $*\033[0m"; }
die()  { echo -e "\033[1;31m    ✘ $*\033[0m" >&2; exit 1; }

# Ordered stage list — used to resolve --resume-from comparisons.
STAGE_ORDER=(1 2 3 4 4b 5 6 7)

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
            die "Invalid --resume-from value '${RESUME_FROM}'. Valid: 1 2 3 4 4b 5 6 7"
    fi
}

stage_should_run() {
    # Returns 0 (true) when this stage's index >= the resume-from stage's index
    _validate_resume_from
    local this_idx
    this_idx=$(stage_index "$1")
    [[ "${this_idx}" -ge "${_RESUME_IDX}" ]]
}

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
    log "STAGE 4 — Build artifacts and assemble distribution (full manifest)"

    log "  Applying patch..."
    # ppc64le-3.8.0-ai-services.patch is a git-am mbox patch.
    # The opensearch-build repo is cloned with --depth=1 (a shallow clone).
    # git-am fails with "corrupt patch" on new-file hunks in shallow clones
    # because it cannot resolve the base tree object referenced by the index
    # line (e.g. "index 00000000..f97331b2").
    # git-apply handles the raw diff content directly without needing history,
    # so we strip the mbox envelope with git-am --keep-cr and pass only the
    # diff portion, or we use `git apply` which accepts mbox patches via stdin
    # with the --include option.  The simplest fix: pass the patch through
    # `git apply` with --allow-empty and let it skip the envelope automatically.

    git config --global user.name "OpenSearch Build"
    git config --global user.email "opensearch-build@example.com"

    # Step 1: apply all shell/python changes to the opensearch-build clone.
    # Use `git apply` instead of `git am` to avoid "corrupt patch" failures
    # that occur with new-file diffs in shallow (--depth=1) clones.
    # git-apply accepts mbox-format files (it skips the envelope header).
    git -C "${BUILD_DIR}" apply \
        --whitespace=nowarn \
        "${SCRIPTS_DIR}/${PATCH_FILE}"

    # Step 2: copy opensearch.patch into the build dir root so the build scripts find it
    # cp "${SCRIPTS_DIR}/${DOCKERFILE_DIR}/opensearch.patch" "${BUILD_DIR}/opensearch.patch"
    # echo "opensearch.patch copied ($(wc -l < "${BUILD_DIR}/opensearch.patch") lines)"

    log "  Running OpenSearch build + assemble inside container..."
    podman run --rm \
        --ulimit nproc=65536:65536 \
        -v "${BUILD_DIR}:/opensearch-build:z" \
        -w /opensearch-build \
        --entrypoint '' \
        "${BUILD_ENV_IMAGE}" \
        bash -c 'set -euo pipefail && \
            ./build.sh \
                manifests/3.8.0/opensearch-3.8.0.yml \
                --platform '"${PLATFORM}"' \
                --architecture '"${ARCHITECTURE}"' && \
            ./assemble.sh tar/builds/opensearch/manifest.yml'

    log "  Copying assembled tar to host..."
    mkdir -p "${ARTIFACTS_DIR}"
    cp "${BUILD_DIR}/tar/dist/opensearch/opensearch-${OPENSEARCH_VERSION}-linux-${ARCHITECTURE}.tar.gz" \
        "${ARTIFACTS_DIR}/opensearch-${OPENSEARCH_VERSION}-linux-${ARCHITECTURE}.tar.gz"

    ok "Stage 4 complete — tar at ${ARTIFACTS_DIR}/opensearch-${OPENSEARCH_VERSION}-linux-${ARCHITECTURE}.tar.gz"
fi

# ---------------------------------------------------------------------------
# Stage 4b — Build extra plugins by cloning their repos and running build scripts
# ---------------------------------------------------------------------------
if stage_should_run 4b; then
    log "STAGE 4b — Build extra plugins (opensearch-jvector, opensearch-prometheus-exporter)"

    PLUGIN_ZIPS_HOST="${ARTIFACTS_DIR}/plugin-zips"
    mkdir -p "${PLUGIN_ZIPS_HOST}"

    # ---- opensearch-jvector ------------------------------------------------
    JVECTOR_DIR="${WORK_DIR}/opensearch-jvector"

    log "  Cloning opensearch-jvector @ tag ${OPENSEARCH_VERSION}.0..."
    git clone --depth=1 --branch "${OPENSEARCH_VERSION}.0" \
        https://github.com/opensearch-project/opensearch-jvector.git "${JVECTOR_DIR}"

    log "  Building opensearch-jvector..."
    podman run --rm \
        --ulimit nproc=65536:65536 \
        -v "${JVECTOR_DIR}:/plugin-src:z" \
        -v "${BUILD_DIR}/scripts:/opensearch-build/scripts:z" \
        -w /plugin-src \
        --entrypoint '' \
        "${BUILD_ENV_IMAGE}" \
        bash -c 'set -euo pipefail && \
            /opensearch-build/scripts/components/opensearch-jvector/build.sh \
                -v '"${OPENSEARCH_VERSION}"' \
                -s false \
                -p '"${PLATFORM}"' \
                -a '"${ARCHITECTURE}"' \
                -o artifacts'

    found=$(find "${JVECTOR_DIR}/artifacts/plugins" -name "opensearch-jvector-*.zip" 2>/dev/null | head -1)
    if [[ -n "${found}" ]]; then
        cp "${found}" "${PLUGIN_ZIPS_HOST}/"
        ok "  Saved: $(basename "${found}")"
    else
        die "opensearch-jvector zip not found after build"
    fi

    # ---- opensearch-prometheus-exporter ------------------------------------
    PROMETHEUS_DIR="${WORK_DIR}/opensearch-prometheus-exporter"

    log "  Cloning opensearch-prometheus-exporter @ tag ${OPENSEARCH_VERSION}.0..."
    git clone --depth=1 --branch "${OPENSEARCH_VERSION}.0" \
        https://github.com/opensearch-project/opensearch-prometheus-exporter.git "${PROMETHEUS_DIR}"

    log "  Building opensearch-prometheus-exporter..."
    podman run --rm \
        --ulimit nproc=65536:65536 \
        -v "${PROMETHEUS_DIR}:/plugin-src:z" \
        -v "${BUILD_DIR}/scripts:/opensearch-build/scripts:z" \
        -w /plugin-src \
        --entrypoint '' \
        "${BUILD_ENV_IMAGE}" \
        bash -c 'set -euo pipefail && \
            /opensearch-build/scripts/default/opensearch/build.sh \
                -v '"${OPENSEARCH_VERSION}"' \
                -s false \
                -p '"${PLATFORM}"' \
                -a '"${ARCHITECTURE}"' \
                -o artifacts'

    found=$(find "${PROMETHEUS_DIR}/artifacts/plugins" -name "prometheus-exporter-*.zip" 2>/dev/null | head -1)
    if [[ -n "${found}" ]]; then
        cp "${found}" "${PLUGIN_ZIPS_HOST}/"
        ok "  Saved: $(basename "${found}")"
    else
        die "prometheus-exporter zip not found after build"
    fi

    ok "Stage 4b complete — plugin zips at ${PLUGIN_ZIPS_HOST}/"
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

    # Copy extra plugin zips (built in Stage 4b) into the Docker context so the
    # Dockerfile can place them in the image for optional/manual installation.
    # These zips are NOT installed into OpenSearch at image build time; they are
    # provided for operators who want to install them post-deployment.
    PLUGIN_ZIPS_DIR="${DOCKER_CONTEXT}/plugin-zips"
    mkdir -p "${PLUGIN_ZIPS_DIR}"
    for zip_pattern in "opensearch-jvector-*.zip" "prometheus-exporter-*.zip"; do
        found=$(find "${ARTIFACTS_DIR}/plugin-zips" -name "${zip_pattern}" 2>/dev/null | head -1)
        if [[ -n "${found}" ]]; then
            cp "${found}" "${PLUGIN_ZIPS_DIR}/"
            ok "  Included plugin zip: $(basename "${found}")"
        else
            warn "  Plugin zip not found for pattern '${zip_pattern}' — skipping"
        fi
    done

    BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    podman build \
        --build-arg "VERSION=${OPENSEARCH_VERSION}" \
        --build-arg "BUILD_DATE=${BUILD_DATE}" \
        --build-arg "UID=1000" \
        --build-arg "GID=1000" \
        -f "${DOCKER_CONTEXT}/Dockerfile.ais" \
        -t "${IMAGE_NAME}" \
        "${DOCKER_CONTEXT}"

    ok "Stage 5 complete — image: ${IMAGE_NAME}"
fi

# ---------------------------------------------------------------------------
# Stage 6 — Trivy security scan
# ---------------------------------------------------------------------------
if stage_should_run 6 && [[ "${SKIP_SCAN}" == false ]]; then
    log "STAGE 6 — Trivy security scan"

    REPORT_DIR="${ARTIFACTS_DIR}/trivy-report"
    IMAGE_ARCHIVE="${REPORT_DIR}/image.tar"
    mkdir -p "${REPORT_DIR}" "${TRIVY_CACHE}"

    log "  Exporting ${IMAGE_NAME} to Docker archive..."
    podman save --format docker-archive -o "${IMAGE_ARCHIVE}" "${IMAGE_NAME}"

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

    ok "Stage 6 complete — reports at ${REPORT_DIR}/"
elif [[ "${SKIP_SCAN}" == true ]]; then
    warn "Stage 6 (Trivy scan) skipped via --skip-scan"
fi

# # ---------------------------------------------------------------------------
# # Stage 7 — Push image to ICR
# # ---------------------------------------------------------------------------
# if stage_should_run 7 && [[ "${SKIP_PUSH}" == false ]]; then
#     log "STAGE 7 — Push image to ICR"

#     if [[ -z "${IBM_CLOUD_APIKEY:-}" ]]; then
#         die "IBM_CLOUD_APIKEY is not set. Export it before running, or use --skip-push."
#     fi

#     log "  Logging into ${ICR_REGISTRY}..."
#     # Suppress echo to avoid leaking the key in terminal output
#     set +x
#     echo "${IBM_CLOUD_APIKEY}" | podman login \
#         -u iamapikey \
#         --password-stdin \
#         "${ICR_REGISTRY}"
#     set -x

#     log "  Pushing ${IMAGE_NAME}..."
#     podman push "${IMAGE_NAME}"

#     podman logout "${ICR_REGISTRY}"

#     ok "Stage 7 complete — image pushed: ${IMAGE_NAME}"
# elif [[ "${SKIP_PUSH}" == true ]]; then
#     warn "Stage 7 (ICR push) skipped via --skip-push"
# fi

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------
log "All stages complete."
echo ""
echo "  Dist tar   : ${ARTIFACTS_DIR}/opensearch-${OPENSEARCH_VERSION}-linux-${ARCHITECTURE}.tar.gz"
echo "  Trivy JSON : ${ARTIFACTS_DIR}/trivy-report/trivy-results.json"
echo "  Trivy TXT  : ${ARTIFACTS_DIR}/trivy-report/trivy-results.txt"
echo "  Image      : ${IMAGE_NAME}"
