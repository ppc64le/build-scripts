#!/bin/bash
# ----------------------------------------------------------------------------
#
# Package       : dotnet
# Version       : 9.0.100
# Source repo   : https://github.com/dotnet/dotnet
# Tested on     : Ubuntu
# Language      : dotnet
# Travis-Check  : False
# Script License: MIT License (MIT)
# Maintainer    : Ashwini Kadam <Ashwini.Kadam@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
# Performs a build and runs tests of https://github.com/dotnet/dotnet
# to detect regressions early
# Performs a build and runs tests of https://github.com/dotnet/dotnet
# to detect regressions early

set -euxo pipefail

REPO=https://github.com/dotnet/dotnet
REF=main
CROSS_ARCH=""
DISABLE_CONTAINER=""
build_arguments=()
common_arguments=()
nuget_dir=""
CONTAINER_IMAGE=""
SCRIPT_ARGS="$@"
#SCRIPT_ARGS="--containerfile vmr-main.cross.Containerfile --cross-arch ppc64le --ref v9.0.0"
while [ $# -ne 0 ]
do
    name="$1"
    case "$name" in
         --ref)
            shift
            REF="$1"
            ;;
	# --containerfile: specify path to Containerfile to build a container image to use for building .NET
        --containerfile)
            shift
            CONTAINER_FILE="$1"
            ;;
        # --containerimage: specify existing container image to use during the build
        --containerimage)
            shift
            CONTAINER_IMAGE="$1"
            ;;
        # --disablecontainer: (internal) used to avoid recursion when the script calls itself to run in a container
        --disablecontainer)
            DISABLE_CONTAINER=true
            ;;
        # --cross-arch: target architecture when cross-building
        --cross-arch)
            shift
            CROSS_ARCH="$1"
            ;;
        *)
            echo "Unknown argument \`$name\`"
            exit 1
            ;;
    esac
    shift
done

container_build_arguments=()
if [[ $CROSS_ARCH == ppc64le ]]; then
    container_build_arguments+=(--build-arg=TARGET_DEBIAN_ARCH=ppc64el)
    container_build_arguments+=(--build-arg=TARGET_GNU_ARCH=powerpc64le)
fi

if [ "$DISABLE_CONTAINER" != "true" ]; then

        sudo dnf -y install podman

    if [ -n "${CONTAINER_FILE}" ]; then
        if [ -n "${CONTAINER_IMAGE}" ]; then
            echo "--containerfile can not be combined with --containerimage"
            exit 1
        fi

        CONTAINER_IMAGE="build_env"
        podman build -t "$CONTAINER_IMAGE" "${container_build_arguments[@]}" -f "$CONTAINER_FILE" .
    fi

    if [ -n "${CONTAINER_IMAGE}" ]; then
        VOLUME_MOUNT_FLAGS=

        VOLUME_MOUNT_FLAGS=:z

        WORKSPACE_ARGS=()
        if [ -n "${WORKSPACE:-}" ]; then
            WORKSPACE_ARGS+=("-v" "$WORKSPACE:$WORKSPACE${VOLUME_MOUNT_FLAGS}")
        fi

        podman run  -u 0 \
                    -v .:/workdir"$VOLUME_MOUNT_FLAGS" --workdir /workdir \
		    -v "$(pwd)":/scripts"$VOLUME_MOUNT_FLAGS" \
                    -e "BUILDING_IN_CONTAINER=true" \
		    "${WORKSPACE_ARGS[@]}" \
                    "$CONTAINER_IMAGE" \
                    "/scripts/$(basename "$0")" --disablecontainer $SCRIPT_ARGS 
        exit $?
    fi
fi
architecture=$(uname -m)

git clone "$REPO"
cd "$(basename "$REPO" .git)"
git checkout "$REF"
COMMIT=$(git rev-parse HEAD)
echo "$REPO is at $COMMIT"

SDK_FULL_VERSION=$(jq -r .tools.dotnet global.json)
DOTNET_MAJOR=${SDK_FULL_VERSION%%.*}

# Prep (install .NET, previously-source-built, and other pre-built .NET dependencies)
./prep-source-build.sh


# With recent versions of the VMR, we need the --source-only flag too.
# Otherwise the VMR may build in Unified Build mode.
if ./build.sh --help | grep -- source-only; then
    build_arguments+=(--source-only)
fi

# default to offline when building release branches.
if [[ "$REF" == release/* ]]; then
    ONLINE="${ONLINE:-false}"
fi

if [ "${ONLINE:-true}" == "true" ]; then
    build_arguments+=(--online)
fi

if [[ "$CROSS_ARCH" == "ppc64le" ]]; then
    build_arguments+=(--use-mono-runtime)
fi

if [ -n "$CROSS_ARCH" ]; then
    build_arguments+=(/p:TargetArchitecture="$CROSS_ARCH" /p:PortableBuild=true)
fi

BUILD_EXIT_CODE=0
./build.sh ${common_arguments[0]+"${common_arguments[@]}"} ${build_arguments[0]+"${build_arguments[@]}"} || BUILD_EXIT_CODE=$?
EXIT_CODE=$BUILD_EXIT_CODE

