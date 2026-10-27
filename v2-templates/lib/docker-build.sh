#!/bin/bash
# =============================================================================
# docker-build.sh - Docker container build placeholder
# =============================================================================
# This file provides optional Docker container build functionality.
# Only activates when DOCKER_IMAGE_NAME is set.
#
# Usage:
#   source "${SCRIPT_DIR}/lib/docker-build.sh"
#
#   # Optional: Set Docker configuration
#   DOCKER_IMAGE_NAME="myimage"
#   DOCKER_IMAGE_TAG="1.0.0"
#
#   # Build image
#   build_docker_image
# =============================================================================

# Prevent multiple sourcing
[[ -n "$_DOCKER_BUILD_SH_SOURCED" ]] && return 0
_DOCKER_BUILD_SH_SOURCED=1

# =============================================================================
# DOCKER CONFIGURATION
# Override these in scripts that build containers
# =============================================================================
: ${DOCKERFILE_PATH:="./Dockerfile"}
: ${DOCKER_IMAGE_NAME:=""}
: ${DOCKER_IMAGE_TAG:="latest"}
: ${DOCKER_BUILD_CONTEXT:="."}
: ${DOCKER_BUILD_ARGS:=""}

# =============================================================================
# DOCKER CHECK FUNCTIONS
# =============================================================================

# check_docker_available: Check if Docker is available
check_docker_available() {
    if ! command -v docker &>/dev/null; then
        echo "[WARN] Docker not found in PATH"
        return 1
    fi

    if ! docker info &>/dev/null 2>&1; then
        echo "[WARN] Docker daemon not running or not accessible"
        return 1
    fi

    return 0
}

# check_dockerfile_exists: Check if Dockerfile exists
check_dockerfile_exists() {
    local dockerfile="${1:-$DOCKERFILE_PATH}"

    if [[ ! -f "$dockerfile" ]]; then
        echo "[WARN] Dockerfile not found at $dockerfile"
        return 1
    fi
    return 0
}

# =============================================================================
# DOCKER BUILD FUNCTIONS
# =============================================================================

# build_docker_image: Build a Docker image
# Usage: build_docker_image [dockerfile] [image_name] [tag]
build_docker_image() {
    local dockerfile="${1:-$DOCKERFILE_PATH}"
    local image_name="${2:-$DOCKER_IMAGE_NAME}"
    local image_tag="${3:-$DOCKER_IMAGE_TAG}"

    # Skip if no image name specified
    if [[ -z "$image_name" ]]; then
        echo "[INFO] DOCKER_IMAGE_NAME not set, skipping Docker build"
        return 0
    fi

    # Check prerequisites
    if ! check_docker_available; then
        echo "[ERROR] Docker not available"
        return 1
    fi

    if ! check_dockerfile_exists "$dockerfile"; then
        echo "[ERROR] Dockerfile not found"
        return 1
    fi

    echo "[INFO] Building Docker image: $image_name:$image_tag"
    echo "[INFO] Dockerfile: $dockerfile"
    echo "[INFO] Context: $DOCKER_BUILD_CONTEXT"

    # Build the image
    local build_cmd="docker build -t ${image_name}:${image_tag} -f ${dockerfile}"

    # Add build args if specified
    if [[ -n "$DOCKER_BUILD_ARGS" ]]; then
        build_cmd="$build_cmd $DOCKER_BUILD_ARGS"
    fi

    build_cmd="$build_cmd $DOCKER_BUILD_CONTEXT"

    if ! eval "$build_cmd"; then
        echo "[ERROR] Docker build failed"
        return 1
    fi

    echo "[INFO] Successfully built $image_name:$image_tag"
    return 0
}

# tag_docker_image: Tag an existing image
# Usage: tag_docker_image source_image target_image
tag_docker_image() {
    local source_image="$1"
    local target_image="$2"

    if [[ -z "$source_image" ]] || [[ -z "$target_image" ]]; then
        echo "[ERROR] tag_docker_image requires source and target image names"
        return 1
    fi

    echo "[INFO] Tagging $source_image as $target_image"
    docker tag "$source_image" "$target_image"
}

# push_docker_image: Push image to registry
# Usage: push_docker_image image_name:tag
push_docker_image() {
    local image="${1:-${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}}"

    if [[ -z "$image" ]] || [[ "$image" == ":" ]]; then
        echo "[ERROR] No image specified for push"
        return 1
    fi

    echo "[INFO] Pushing $image"
    docker push "$image"
}

# =============================================================================
# DOCKER CLEANUP FUNCTIONS
# =============================================================================

# cleanup_docker_image: Remove a Docker image
# Usage: cleanup_docker_image image_name:tag
cleanup_docker_image() {
    local image="$1"

    if [[ -z "$image" ]]; then
        echo "[WARN] No image specified for cleanup"
        return 0
    fi

    if docker image inspect "$image" &>/dev/null; then
        echo "[INFO] Removing Docker image: $image"
        docker rmi "$image" || true
    fi
}

# cleanup_build_cache: Clean Docker build cache
cleanup_build_cache() {
    echo "[INFO] Cleaning Docker build cache"
    docker builder prune -f || true
}

