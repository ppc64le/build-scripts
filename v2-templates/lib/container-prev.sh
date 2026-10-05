#!/bin/bash
# =============================================================================
# Container Build Library - Multi-Architecture Support
# =============================================================================
# Provides functions for building multi-arch container images.
# Supports buildah (preferred) with automatic fallback to podman via Docker socket.
#
# Usage:
#   source templates/lib/container.sh
#
# Environment Variables:
#   BUILD_CONTAINER      - Set to "1" to enable container builds
#   CONTAINER_REGISTRY   - Registry to tag images for (default: none)
#   CONTAINER_IMAGE_NAME - Override image name (default: PACKAGE_NAME)
#   CONTAINER_OUTPUT_DIR - Where to save images (default: OUTPUT_DIR/containers)
#   CONTAINER_PUSH       - Set to "1" to push to registry after build
#   CONTAINER_ENGINE     - Force engine: "buildah", "podman", or "auto" (default)
#
# Docker Socket Fallback:
#   When running inside an unprivileged container where buildah can't create
#   user namespaces, we fall back to podman if /var/run/docker.sock is mounted.
#   The orchestration layer sets DOCKER_HOST=unix:///var/run/docker.sock so
#   podman communicates with the host Docker daemon.
#
#   The build context is tar'd and piped to `podman build -` to avoid path
#   mismatch issues between container and host. No special path mounting needed.
#
#   Setup (orchestration layer handles this):
#     - Mount /var/run/docker.sock:/var/run/docker.sock
#     - Set DOCKER_HOST=unix:///var/run/docker.sock
#     - Ensure podman is available in container
#
# build_info.json Configuration:
#   {
#     "docker_build": true,
#     "docker_image_name": "my-image",
#     "docker_registry": "icr.io/namespace"
#   }
#
# Multi-arch workflow:
#   1. Build on each architecture - creates image:version-ARCH
#   2. Run manifest_create to create multi-arch manifest
#   3. Run manifest_push to push manifest to registry
#
# =============================================================================

# Ensure common.sh is loaded for logging functions
if ! declare -f log_info &>/dev/null; then
    echo "ERROR: container.sh requires common.sh to be sourced first" >&2
    exit 1
fi

# =============================================================================
# DETECT CONTAINER ENVIRONMENT
# =============================================================================
# When running inside a container, buildah can't create user namespaces
# unless the outer container was started with --privileged or specific caps.
# We detect this and use --isolation chroot as fallback.
# If running as non-root, we may need sudo for buildah to work.

_is_inside_container() {
    # Check common container indicators
    [[ -f /.dockerenv ]] && return 0
    [[ -f /run/.containerenv ]] && return 0
    grep -q 'docker\|kubepods\|libpod' /proc/1/cgroup 2>/dev/null && return 0
    [[ "${container:-}" == "podman" ]] || [[ "${container:-}" == "docker" ]] && return 0
    return 1
}

# =============================================================================
# BUILDAH PRIVILEGE DETECTION
# =============================================================================
# Rootless buildah needs CLONE_NEWUSER which fails in unprivileged containers.
# Root buildah (via sudo) doesn't need user namespaces.
# We auto-detect and use sudo when necessary.

_can_unshare() {
    # Quick test if user namespaces work
    unshare --user true 2>/dev/null
}

_needs_sudo_buildah() {
    # If already root, no sudo needed
    [[ $(id -u) -eq 0 ]] && return 1

    # If not in a container, rootless buildah usually works
    _is_inside_container || return 1

    # Inside container as non-root: test if user namespaces work
    if _can_unshare; then
        return 1  # User namespaces work, no sudo needed
    fi

    # User namespaces don't work - check if sudo is available
    if command -v sudo &>/dev/null && sudo -n buildah --version &>/dev/null 2>&1; then
        return 0  # Need and can use sudo
    fi

    return 1  # Can't use sudo, will fail but let it try
}

# Determine buildah command prefix once at load time
BUILDAH_CMD="buildah"
if _needs_sudo_buildah; then
    BUILDAH_CMD="sudo buildah"
    log_info "Container build will use sudo (non-root in unprivileged container)"
fi

# Set default isolation mode and storage driver for nested containers
# vfs driver avoids overlay namespace requirements
# chroot isolation avoids CLONE_NEWUSER requirements
if _is_inside_container; then
    : "${BUILDAH_ISOLATION:=chroot}"
    BUILDAH_CMD="${BUILDAH_CMD} --storage-driver vfs"
    log_info "Using vfs storage driver for nested container build"
fi

# =============================================================================
# DOCKER SOCKET DETECTION
# =============================================================================
# When buildah can't work (unprivileged container), we can fall back to using
# podman with the host's Docker socket mounted. The orchestration layer sets
# DOCKER_HOST=unix:///var/run/docker.sock so podman talks to the host daemon.

_docker_socket_available() {
    [[ -S /var/run/docker.sock ]] && command -v podman &>/dev/null
}

_select_container_engine() {
    local engine="${CONTAINER_ENGINE:-auto}"

    case "${engine}" in
        buildah)
            echo "buildah"
            ;;
        podman)
            echo "podman"
            ;;
        auto|"")
            # Auto-detect: prefer buildah, fall back to podman+socket
            if command -v buildah &>/dev/null; then
                # Check if buildah will actually work
                if ! _is_inside_container; then
                    echo "buildah"
                elif _can_unshare; then
                    echo "buildah"
                elif [[ $(id -u) -eq 0 ]]; then
                    echo "buildah"
                elif _docker_socket_available; then
                    # Buildah won't work, but Docker socket + podman available
                    echo "podman"
                else
                    # Try buildah anyway, it might work with sudo
                    echo "buildah"
                fi
            elif _docker_socket_available; then
                echo "podman"
            else
                echo "none"
            fi
            ;;
    esac
}

# Determine container engine at load time
CONTAINER_ENGINE_SELECTED="$(_select_container_engine)"

if [[ "${CONTAINER_ENGINE_SELECTED}" == "podman" ]]; then
    log_info "Container builds will use podman (via Docker socket)"
elif [[ "${CONTAINER_ENGINE_SELECTED}" == "buildah" ]]; then
    log_info "Container builds will use buildah"
fi

# =============================================================================
# CONFIGURATION
# =============================================================================

# Default output directory for container images
: "${CONTAINER_OUTPUT_DIR:=${OUTPUT_DIR:-/output}/containers}"

# Normalize architecture names to OCI standard
# uname -m returns: x86_64, aarch64, ppc64le, s390x
# OCI uses: amd64, arm64, ppc64le, s390x
_normalize_arch() {
    local arch="${1:-$(uname -m)}"
    case "${arch}" in
        x86_64)  echo "amd64" ;;
        aarch64) echo "arm64" ;;
        *)       echo "${arch}" ;;  # ppc64le, s390x are already correct
    esac
}

# =============================================================================
# _build_with_podman
# Build container image using podman (via Docker socket)
#
# Uses tar+stdin to avoid path mismatch between container and host.
# The host Docker daemon can't see container paths, so we tar up the
# build context and pipe it to `podman build -`.
#
# Requires DOCKER_HOST to be set by orchestration layer.
# =============================================================================
_build_with_podman() {
    local dockerfile="$1"
    local context_dir="$2"
    local arch_tag="$3"
    local latest_arch_tag="$4"
    local version="$5"

    log_info "Building with podman via Docker socket (tar context to stdin)..."

    # Build podman command args
    local podman_args=()
    podman_args+=(build)
    podman_args+=(--tag "${arch_tag}")
    podman_args+=(--tag "${latest_arch_tag}")

    # Add version build arg if Dockerfile uses it
    if grep -q 'ARG.*VERSION' "${dockerfile}"; then
        podman_args+=(--build-arg "VERSION=${version}")
        podman_args+=(--build-arg "PACKAGE_VERSION=${version}")
    fi

    # The "-" tells podman to read tar context from stdin
    # Dockerfile must be in the context directory (standard location)
    podman_args+=(-)

    log_info "Running: tar -C ${context_dir} -c . | sudo podman ${podman_args[*]}"

    # Tar the context directory and pipe to podman build
    # Use sudo to avoid namespace permission issues in unprivileged containers
    if ! tar -C "${context_dir}" -c . | sudo podman "${podman_args[@]}"; then
        log_error "Podman build failed"
        return 1
    fi

    return 0
}

# =============================================================================
# _save_with_podman
# Save podman image to OCI archive
# =============================================================================
_save_with_podman() {
    local arch_tag="$1"
    local output_file="$2"

    log_info "Saving podman image to: ${output_file}"

    # Save as OCI archive for compatibility
    if ! sudo podman save "${arch_tag}" -o "${output_file}"; then
        log_error "Failed to save podman image"
        return 1
    fi

    return 0
}

# =============================================================================
# _load_container_config
# Load container configuration from build_info.json
# =============================================================================
_load_container_config() {
    local script_dir="${1:-${SCRIPT_DIR}}"
    local build_info="${script_dir}/build_info.json"

    if [[ -f "${build_info}" ]]; then
        # Parse docker_build flag
        if command -v jq &>/dev/null; then
            DOCKER_BUILD=$(jq -r '.docker_build // false' "${build_info}" 2>/dev/null)
            DOCKER_IMAGE_NAME=$(jq -r '.docker_image_name // empty' "${build_info}" 2>/dev/null)
            DOCKER_REGISTRY=$(jq -r '.docker_registry // empty' "${build_info}" 2>/dev/null)
        else
            # Fallback: simple grep parsing
            if grep -q '"docker_build"[[:space:]]*:[[:space:]]*true' "${build_info}"; then
                DOCKER_BUILD=true
            else
                DOCKER_BUILD=false
            fi
            DOCKER_IMAGE_NAME=$(grep -o '"docker_image_name"[[:space:]]*:[[:space:]]*"[^"]*"' "${build_info}" | sed 's/.*: *"//;s/"$//' || true)
            DOCKER_REGISTRY=$(grep -o '"docker_registry"[[:space:]]*:[[:space:]]*"[^"]*"' "${build_info}" | sed 's/.*: *"//;s/"$//' || true)
        fi
    else
        DOCKER_BUILD=false
    fi

    # Apply overrides from environment
    : "${DOCKER_BUILD:=false}"
    : "${DOCKER_IMAGE_NAME:=${CONTAINER_IMAGE_NAME:-${PACKAGE_NAME}}}"
    : "${DOCKER_REGISTRY:=${CONTAINER_REGISTRY:-}}"
}

# =============================================================================
# _should_build_container
# Check if container build should proceed
# Returns 0 if yes, 1 if no
# =============================================================================
_should_build_container() {
    local script_dir="${1:-${SCRIPT_DIR}}"
    local dockerfile="${script_dir}/Dockerfile"

    # Load config if not already loaded
    if [[ -z "${DOCKER_BUILD:-}" ]]; then
        _load_container_config "${script_dir}"
    fi

    # Check conditions
    if [[ ! -f "${dockerfile}" ]]; then
        log_info "No Dockerfile found at ${dockerfile}"
        return 1
    fi

    if [[ "${DOCKER_BUILD}" != "true" ]] && [[ "${BUILD_CONTAINER:-}" != "1" ]]; then
        log_info "Container build not enabled (set BUILD_CONTAINER=1 or docker_build: true)"
        return 1
    fi

    # Check if we have a working container engine
    if [[ "${CONTAINER_ENGINE_SELECTED}" == "none" ]]; then
        log_warn "No container engine available (need buildah or podman+socket)"
        return 1
    fi

    # For buildah, check if it will actually work
    if [[ "${CONTAINER_ENGINE_SELECTED}" == "buildah" ]]; then
        if _is_inside_container && [[ $(id -u) -ne 0 ]] && ! _can_unshare; then
            if ! sudo -n buildah --version &>/dev/null 2>&1; then
                # Buildah won't work, check for podman+socket fallback
                if _docker_socket_available; then
                    log_info "Switching to podman (buildah can't create namespaces)"
                    CONTAINER_ENGINE_SELECTED="podman"
                else
                    log_warn "buildah requires privileges and Docker socket not available"
                    log_warn "Mount Docker socket: -v /var/run/docker.sock:/var/run/docker.sock"
                    return 1
                fi
            fi
        fi
    fi

    return 0
}

# =============================================================================
# build_container
# Build container image using buildah with multi-arch tagging
#
# Arguments:
#   $1 - Version tag (default: PACKAGE_VERSION)
#   $2 - Dockerfile path (default: SCRIPT_DIR/Dockerfile)
#
# Creates:
#   - Local image: image_name:version-ARCH (e.g., couchdb:3.4.2-ppc64le)
#   - Archive: image_name-version-ARCH.tar
#   - If registry configured: registry/image_name:version-ARCH
#
# Returns:
#   0 on success, 1 on failure
# =============================================================================
build_container() {
    local version="${1:-${PACKAGE_VERSION}}"
    local dockerfile="${2:-${SCRIPT_DIR}/Dockerfile}"
    local context_dir
    context_dir="$(dirname "${dockerfile}")"

    # Load configuration
    _load_container_config "${context_dir}"

    local image_name="${DOCKER_IMAGE_NAME:-${PACKAGE_NAME}}"
    local raw_arch
    raw_arch=$(uname -m)
    local arch
    arch=$(_normalize_arch "${raw_arch}")

    # Multi-arch tag format: image:version-arch
    local arch_tag="${image_name}:${version}-${arch}"
    local latest_arch_tag="${image_name}:latest-${arch}"

    log_info "Building container image: ${arch_tag}"
    log_info "  Dockerfile: ${dockerfile}"
    log_info "  Context: ${context_dir}"
    log_info "  Architecture: ${arch} (${raw_arch})"
    log_info "  Engine: ${CONTAINER_ENGINE_SELECTED}"

    # Create output directory
    mkdir -p "${CONTAINER_OUTPUT_DIR}"

    local output_file="${CONTAINER_OUTPUT_DIR}/${image_name}-${version}-${arch}.tar"

    # ==========================================================================
    # BUILD WITH SELECTED ENGINE
    # ==========================================================================
    if [[ "${CONTAINER_ENGINE_SELECTED}" == "podman" ]]; then
        # ----- Podman build (via Docker socket) -----
        if ! _build_with_podman "${dockerfile}" "${context_dir}" "${arch_tag}" "${latest_arch_tag}" "${version}"; then
            return 1
        fi

        log_info "Container image built successfully: ${arch_tag}"

        # Save image
        if ! _save_with_podman "${arch_tag}" "${output_file}"; then
            return 1
        fi

        # Tag with registry prefix if configured
        if [[ -n "${DOCKER_REGISTRY}" ]]; then
            local registry_arch_tag="${DOCKER_REGISTRY}/${image_name}:${version}-${arch}"
            local registry_latest_arch="${DOCKER_REGISTRY}/${image_name}:latest-${arch}"

            log_info "Tagging for registry: ${registry_arch_tag}"
            sudo podman tag "${arch_tag}" "${registry_arch_tag}"
            sudo podman tag "${latest_arch_tag}" "${registry_latest_arch}"

            # Push to registry if requested
            if [[ "${CONTAINER_PUSH:-}" == "1" ]]; then
                log_info "Pushing to registry: ${registry_arch_tag}"
                if sudo podman push "${registry_arch_tag}"; then
                    log_info "Successfully pushed ${registry_arch_tag}"
                else
                    log_warn "Failed to push to registry (continuing anyway)"
                fi
            fi
        fi
    else
        # ----- Buildah build -----
        local build_args=()
        build_args+=(--file "${dockerfile}")
        build_args+=(--tag "${arch_tag}")
        build_args+=(--tag "${latest_arch_tag}")

        # Add architecture label for manifest tools
        build_args+=(--label "org.opencontainers.image.architecture=${arch}")
        build_args+=(--label "org.opencontainers.image.version=${version}")

        # Add version build arg if Dockerfile uses it
        if grep -q 'ARG.*VERSION' "${dockerfile}"; then
            build_args+=(--build-arg "VERSION=${version}")
            build_args+=(--build-arg "PACKAGE_VERSION=${version}")
        fi

        # Add isolation mode - chroot is safer for nested containers
        local isolation="${BUILDAH_ISOLATION:-}"
        if [[ -z "${isolation}" ]] && _is_inside_container; then
            isolation="chroot"
        fi
        if [[ -n "${isolation}" ]]; then
            build_args+=(--isolation "${isolation}")
            log_info "Using isolation mode: ${isolation}"
        fi

        log_info "Running: ${BUILDAH_CMD} build ${build_args[*]} ${context_dir}"

        if ! ${BUILDAH_CMD} build "${build_args[@]}" "${context_dir}"; then
            # Buildah failed - try podman fallback if available
            if _docker_socket_available; then
                log_warn "Buildah failed, falling back to podman..."
                CONTAINER_ENGINE_SELECTED="podman"
                if ! _build_with_podman "${dockerfile}" "${context_dir}" "${arch_tag}" "${latest_arch_tag}" "${version}"; then
                    return 1
                fi
                if ! _save_with_podman "${arch_tag}" "${output_file}"; then
                    return 1
                fi
            else
                log_error "Container build failed"
                return 1
            fi
        else
            log_info "Container image built successfully: ${arch_tag}"

            # Save to OCI archive
            log_info "Saving container to: ${output_file}"
            if ! ${BUILDAH_CMD} push "${arch_tag}" "oci-archive:${output_file}"; then
                log_error "Failed to save container image"
                return 1
            fi
        fi

        # Tag with registry prefix if configured
        if [[ -n "${DOCKER_REGISTRY}" ]]; then
            local registry_arch_tag="${DOCKER_REGISTRY}/${image_name}:${version}-${arch}"
            local registry_latest_arch="${DOCKER_REGISTRY}/${image_name}:latest-${arch}"

            log_info "Tagging for registry: ${registry_arch_tag}"
            ${BUILDAH_CMD} tag "${arch_tag}" "${registry_arch_tag}"
            ${BUILDAH_CMD} tag "${latest_arch_tag}" "${registry_latest_arch}"

            # Save registry-tagged version
            local registry_output="${CONTAINER_OUTPUT_DIR}/${image_name}-${version}-${arch}-registry.tar"
            ${BUILDAH_CMD} push "${registry_arch_tag}" "oci-archive:${registry_output}"
            log_info "Registry-tagged image saved to: ${registry_output}"

            # Push to registry if requested
            if [[ "${CONTAINER_PUSH:-}" == "1" ]]; then
                log_info "Pushing to registry: ${registry_arch_tag}"
                if ${BUILDAH_CMD} push "${registry_arch_tag}" "docker://${registry_arch_tag}"; then
                    log_info "Successfully pushed ${registry_arch_tag}"
                else
                    log_warn "Failed to push to registry (continuing anyway)"
                fi
            fi
        fi
    fi

    log_info "Container build complete"
    log_info "  Image: ${arch_tag}"
    log_info "  Archive: ${output_file}"
    log_info "  Load with: podman load < ${output_file}"

    # Write manifest fragment for multi-arch assembly
    local manifest_fragment="${CONTAINER_OUTPUT_DIR}/${image_name}-${version}-${arch}.manifest"
    cat > "${manifest_fragment}" <<EOF
# Manifest fragment for ${arch_tag}
IMAGE_NAME=${image_name}
VERSION=${version}
ARCH=${arch}
RAW_ARCH=${raw_arch}
ARCHIVE=${output_file}
REGISTRY_TAG=${DOCKER_REGISTRY:+${DOCKER_REGISTRY}/}${image_name}:${version}-${arch}
EOF
    log_info "Manifest fragment: ${manifest_fragment}"

    return 0
}

# =============================================================================
# manifest_create
# Create a multi-arch manifest from arch-specific images
#
# Arguments:
#   $1 - Image name (default: DOCKER_IMAGE_NAME or PACKAGE_NAME)
#   $2 - Version (default: PACKAGE_VERSION)
#   $@ - Architectures to include (default: auto-detect from .manifest files)
#
# Example:
#   manifest_create myimage 1.0.0 amd64 ppc64le arm64
#   manifest_create  # Auto-detect from manifest fragments
#
# Returns:
#   0 on success, 1 on failure
# =============================================================================
manifest_create() {
    local image_name="${1:-${DOCKER_IMAGE_NAME:-${PACKAGE_NAME}}}"
    local version="${2:-${PACKAGE_VERSION}}"
    shift 2 2>/dev/null || true

    local manifest_name="${image_name}:${version}"
    local manifest_latest="${image_name}:latest"

    log_info "Creating multi-arch manifest: ${manifest_name}"

    # Collect architectures
    local arches=("$@")

    # If no arches specified, auto-detect from manifest fragments
    if [[ ${#arches[@]} -eq 0 ]]; then
        log_info "Auto-detecting architectures from manifest fragments..."
        for fragment in "${CONTAINER_OUTPUT_DIR}/${image_name}-${version}-"*.manifest; do
            if [[ -f "${fragment}" ]]; then
                local frag_arch
                frag_arch=$(grep '^ARCH=' "${fragment}" | cut -d= -f2)
                if [[ -n "${frag_arch}" ]]; then
                    arches+=("${frag_arch}")
                    log_info "  Found: ${frag_arch}"
                fi
            fi
        done
    fi

    if [[ ${#arches[@]} -eq 0 ]]; then
        log_error "No architectures found for manifest"
        return 1
    fi

    log_info "Architectures: ${arches[*]}"

    # Remove existing manifest if present
    ${BUILDAH_CMD} manifest rm "${manifest_name}" 2>/dev/null || true
    ${BUILDAH_CMD} manifest rm "${manifest_latest}" 2>/dev/null || true

    # Create new manifest
    if ! ${BUILDAH_CMD} manifest create "${manifest_name}"; then
        log_error "Failed to create manifest ${manifest_name}"
        return 1
    fi

    # Add each architecture
    for arch in "${arches[@]}"; do
        local arch_tag="${image_name}:${version}-${arch}"
        log_info "Adding ${arch_tag} to manifest..."

        if ! ${BUILDAH_CMD} manifest add "${manifest_name}" "${arch_tag}"; then
            log_warn "Failed to add ${arch_tag} - image may not exist locally"
            continue
        fi
    done

    # Create latest manifest too
    ${BUILDAH_CMD} manifest create "${manifest_latest}" 2>/dev/null || true
    for arch in "${arches[@]}"; do
        ${BUILDAH_CMD} manifest add "${manifest_latest}" "${image_name}:latest-${arch}" 2>/dev/null || true
    done

    log_info "Manifest created: ${manifest_name}"

    # Inspect the manifest
    log_info "Manifest contents:"
    ${BUILDAH_CMD} manifest inspect "${manifest_name}" 2>/dev/null | head -50 || true

    return 0
}

# =============================================================================
# manifest_push
# Push multi-arch manifest to registry
#
# Arguments:
#   $1 - Image name (default: DOCKER_IMAGE_NAME or PACKAGE_NAME)
#   $2 - Version (default: PACKAGE_VERSION)
#   $3 - Registry (default: DOCKER_REGISTRY)
#
# Example:
#   manifest_push myimage 1.0.0 icr.io/namespace
#
# Returns:
#   0 on success, 1 on failure
# =============================================================================
manifest_push() {
    local image_name="${1:-${DOCKER_IMAGE_NAME:-${PACKAGE_NAME}}}"
    local version="${2:-${PACKAGE_VERSION}}"
    local registry="${3:-${DOCKER_REGISTRY}}"

    if [[ -z "${registry}" ]]; then
        log_error "No registry specified for manifest push"
        log_error "Set DOCKER_REGISTRY or pass registry as argument"
        return 1
    fi

    local manifest_name="${image_name}:${version}"
    local registry_manifest="${registry}/${image_name}:${version}"
    local registry_latest="${registry}/${image_name}:latest"

    log_info "Pushing manifest to registry: ${registry_manifest}"

    # Push versioned manifest
    if ! ${BUILDAH_CMD} manifest push --all "${manifest_name}" "docker://${registry_manifest}"; then
        log_error "Failed to push manifest ${registry_manifest}"
        return 1
    fi
    log_info "Successfully pushed: ${registry_manifest}"

    # Push latest manifest
    local manifest_latest="${image_name}:latest"
    if ${BUILDAH_CMD} manifest exists "${manifest_latest}" 2>/dev/null; then
        log_info "Pushing latest manifest: ${registry_latest}"
        if ${BUILDAH_CMD} manifest push --all "${manifest_latest}" "docker://${registry_latest}"; then
            log_info "Successfully pushed: ${registry_latest}"
        else
            log_warn "Failed to push latest manifest (non-fatal)"
        fi
    fi

    log_info "Registry push complete"
    log_info "  Pull with: podman pull ${registry_manifest}"

    return 0
}

# =============================================================================
# container_only_build
# Build just the container without running the full build script
# Useful for end users who just want the Docker image
# =============================================================================
container_only_build() {
    local script_dir="${1:-${SCRIPT_DIR}}"
    local dockerfile="${script_dir}/Dockerfile"

    if [[ ! -f "${dockerfile}" ]]; then
        log_error "No Dockerfile found at ${dockerfile}"
        return 1
    fi

    if [[ "${CONTAINER_ENGINE_SELECTED}" == "none" ]]; then
        log_error "No container engine available"
        log_error "Install buildah (dnf install buildah) or mount Docker socket with podman available"
        return 1
    fi

    _load_container_config "${script_dir}"
    build_container "${PACKAGE_VERSION}" "${dockerfile}"
}

# =============================================================================
# container_info
# Display information about built container images
# =============================================================================
container_info() {
    local image_name="${1:-${DOCKER_IMAGE_NAME:-${PACKAGE_NAME}}}"
    local version="${2:-${PACKAGE_VERSION}}"

    log_info "Container images for ${image_name}:${version}"
    log_info "Engine: ${CONTAINER_ENGINE_SELECTED}"
    log_info ""

    # List local images
    log_info "Local images:"
    if [[ "${CONTAINER_ENGINE_SELECTED}" == "podman" ]]; then
        sudo podman images "${image_name}:${version}*" 2>/dev/null || true
        sudo podman images "${image_name}:latest*" 2>/dev/null || true
    else
        ${BUILDAH_CMD} images --filter "reference=${image_name}:${version}*" 2>/dev/null || true
        ${BUILDAH_CMD} images --filter "reference=${image_name}:latest*" 2>/dev/null || true
    fi

    # List archives
    log_info ""
    log_info "Archives in ${CONTAINER_OUTPUT_DIR}:"
    ls -la "${CONTAINER_OUTPUT_DIR}/${image_name}-${version}"*.tar 2>/dev/null || echo "  (none)"

    # List manifests (buildah only - podman via socket doesn't support local manifests)
    if [[ "${CONTAINER_ENGINE_SELECTED}" == "buildah" ]]; then
        log_info ""
        log_info "Manifests:"
        ${BUILDAH_CMD} manifest inspect "${image_name}:${version}" 2>/dev/null | head -20 || echo "  (none)"
    fi
}

log_info "Container build library loaded (engine: ${CONTAINER_ENGINE_SELECTED})"
