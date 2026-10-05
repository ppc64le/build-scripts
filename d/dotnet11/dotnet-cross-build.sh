#!/bin/bash
# ----------------------------------------------------------------------------
#
# Package       : dotnet
# Version       : 11.0.100
# Source repo   : https://github.com/dotnet/dotnet
# Tested on     : fedora-43 (x86_64)
# Language      : dotnet
# Ci-Check      : False
# Script License: Apache License, Version 2 or later
# Maintainer    : Shrinivas Sidral <Shrinivas.Sidral@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
# .Net11 cross build for ppc64le using ubi image
# ./dotnet-cross-build.sh --ref <branch>  --cross-release-version <UBI_IMAGE_VERSION> --cross-arch ppc64le --official-build-id <OFFICIAL_BUILD_ID>

set -euxo pipefail

REPO=https://github.com/dotnet/dotnet
REF=main
CROSS_ARCH=""
PORTABLE_BUILD= 
CROSS_RELEASE_VERSION=""
CROSS_RELEASE_OS="rhel"
CROSS_CONTAINER_BUILD=""
OFFICIAL_BUILD_ID=""
WITH_SYSTEM_LIBS="default"
build_arguments=()
common_arguments=()
container_build_arguments=()
HOST_ARCH=$(uname -m)

while [ $# -ne 0 ]
do
    name="$1"
    case "$name" in
        # repository and reference to build and test
        # --repo: repo url
        --repo)
            shift
            REPO="$1"
            ;;
        # --ref: ref to check out
         --ref)
            shift
            REF="$1"
            ;;
        # --cross-arch: target architecture when cross-building
        --cross-arch)
            shift
            CROSS_ARCH="$1"
            ;;
        # --cross-release-version: target another version of the OS
        --cross-release-version)
            shift
            CROSS_RELEASE_VERSION="$1"
            ;;
        # --official-build-id: set the official build ID (from the release manifest)
        --official-build-id)
            shift
            OFFICIAL_BUILD_ID="$1"
            ;;
        # Build using online sources. Can be set to 'true'/'false'.
        --online)
            shift
            ONLINE="$1"
            ;;
        *)
            echo "Unknown argument \`$name\`"
            exit 1
            ;;
    esac
    shift
done

get_linux_platform_name()
{
    . /etc/os-release
    echo "$ID.$VERSION_ID"
    return 0
}

linux_platform=$(get_linux_platform_name)

fixup_rootfs() {
    set +x
    local ROOTFS="$1"

    # Ensure directories are writable.
    find "$ROOTFS" -type d -exec chmod u+w {} +

    # Make absolute symlinks in the rootfs relative within the rootfs.
    find "$ROOTFS" -type l | while read l; do
        target="$(readlink "$l")"
        if [[ "$target" == /* ]]; then
            abs_target="$(realpath -sm "$ROOTFS/$target")"
            rel_target="$(realpath -s --relative-to="$(dirname "$(realpath -s "$l")")" "$abs_target")"
            echo "Changing '$l' from '$target' to '$rel_target'"
            ln -fsn "$rel_target" "$l"
        fi
    done
    set -x
}

# When CROSS_RELEASE_VERSION is set without CROSS_ARCH, use HOST_ARCH
if [ -z "$CROSS_ARCH" ] && [ -n "$CROSS_RELEASE_VERSION" ]; then
    CROSS_ARCH="$HOST_ARCH"
fi

# Set TARGET_ARCH to CROSS_ARCH if set, otherwise use HOST_ARCH
TARGET_ARCH="${CROSS_ARCH:-$HOST_ARCH}"

# Cross-builds are portable to minimize dependencies on the cross-build environment.
if [ -n "$CROSS_ARCH" ]; then
    PORTABLE_BUILD="${PORTABLE_BUILD:-true}"
fi
PORTABLE_BUILD="${PORTABLE_BUILD:-false}"

# When CROSS_ARCH is set without CROSS_RELEASE_VERSION, do a Ubuntu cross-compiler build
if [ -n "$CROSS_ARCH" ] && [ -z "$CROSS_RELEASE_VERSION" ]; then
    CROSS_CONTAINER_BUILD="yes"
fi

# Packages needed for the target platform
target_packages=(
    brotli-devel
    krb5-devel
    libicu-devel
    zlib-devel
)

dotnet_version=${REF##*/}
fedora_version=${linux_platform##*.}
if [[ $fedora_version -ge 45 && ${dotnet_version%.0*} =~ ^(8|9|10)$ ]]; then
    target_packages+=(openssl3-devel)
else
    target_packages+=(openssl-devel)
fi

# CROSS_RELEASE_VERSION for rhel uses ubi images to create the rootfs
# The images don't include lttng-ust-devel, so we do our builds without lttng-ust devel support.
# This matches the build configuration we use for RHEL and Fedora.
# Building without lttng-ust is supported for .NET 10+.
if [ -z "$CROSS_RELEASE_VERSION" ] || [ "$CROSS_RELEASE_OS" == "fedora" ]; then
    target_packages+=(lttng-ust-devel)
fi

# Building with system rapidjson is limited to Fedora.
if [[ $linux_platform == fedora.* && -z "$CROSS_RELEASE_VERSION" ]] || [[ "$CROSS_RELEASE_OS" == "fedora" ]]; then
    target_packages+=(rapidjson-devel)
fi

container_build_arguments=(--build-arg=TARGET_DEBIAN_ARCH=ppc64el)
container_build_arguments+=(--build-arg=TARGET_GNU_ARCH=powerpc64le)

sudo dnf -y install podman

export ROOTFS_DIR="$(pwd)/rootfs"
if [ -d "$ROOTFS_DIR" ]; then
    sudo rm -rf "$ROOTFS_DIR"
fi
mkdir -p "$ROOTFS_DIR"

# Populate sysroot from target OS version
if [ "$CROSS_RELEASE_OS" == "rhel" ]; then
    podman run --rm \
        -v "$ROOTFS_DIR:/sysroot:Z" \
        registry.access.redhat.com/ubi$CROSS_RELEASE_VERSION/ubi:latest \
        dnf install \
            --installroot=/sysroot \
            --releasever=$CROSS_RELEASE_VERSION \
            --forcearch="$TARGET_ARCH" \
            --verbose \
            -y \
            filesystem basesystem \
            glibc-devel gcc libstdc++-devel gcc-c++ \
            "${target_packages[@]}"
else
    echo "Error: Unsupported CROSS_RELEASE_OS: $CROSS_RELEASE_OS"
    exit 1
fi
fixup_rootfs "$ROOTFS_DIR"

if [ "${BUILDING_IN_CONTAINER:-}" != "true" ]; then
    # install dependencies
    sudo dnf repolist --all
    # Build host packages.
    host_packages=(
        clang
        cmake
        elfutils
        file
        findutils
        git
        glibc-langpack-en
        hostname
        jq
        libicu
        llvm
        make
        patch
        python3
        rpm-build
        tar
        zip
        ninja-build
        lld
    )

    sudo dnf -y install "${host_packages[@]}"
fi

# Clone the dotnet vmr repo
git clone "$REPO"
cd "$(basename "$REPO" .git)"
git checkout "$REF"
COMMIT=$(git rev-parse HEAD)
echo "$REPO is at $COMMIT"

SDK_FULL_VERSION=$(jq -r .tools.dotnet global.json)
DOTNET_MAJOR=${SDK_FULL_VERSION%%.*}

# If the repo includes a 'release.json' file in its root, use it as the release manifest.
if [ -f "release.json" ]; then
    common_arguments+=(--release-manifest release.json)
    # The build doesn't want there to be a git folder when using source link arguments.
    rm -rf .git
# For .NET 10+, use a "daily build" version format.
elif (( DOTNET_MAJOR >= 10 )) && [ -z "$OFFICIAL_BUILD_ID" ]; then
    DAILY_BUILD_INFO=$(curl -sSL "https://aka.ms/dotnet/$DOTNET_MAJOR.0.1xx/daily/productCommit-linux-x64.json")
    DAILY_VERSION=$(echo "$DAILY_BUILD_INFO" | jq -r '.sdk.version')

    if [[ "$DAILY_VERSION" == *-* ]]; then
        # expected format: 10.0.100-rc.2.25468.104
        # https://github.com/dotnet/arcade/blob/main/Documentation/CorePackages/Versioning.md#package-version
        SHORT_DATE=${DAILY_VERSION%.*}
        SHORT_DATE=${SHORT_DATE##*.}
        SHORT_DATE_YY="${SHORT_DATE:0:2}"
        SHORT_DATE_DD=$(( SHORT_DATE % 50 ))
        SHORT_DATE_MM=$(( 10#${SHORT_DATE:2} / 50 )) # Force base 10. Otherwise this is treated as an octal number when it starts with zero in January.
        REVISION=${DAILY_VERSION##*.}
        REVISION=$((REVISION - 100))

        SHORT_DATE_YY=$(printf "%02d" $SHORT_DATE_YY)
        SHORT_DATE_MM=$(printf "%02d" $SHORT_DATE_MM)
        SHORT_DATE_DD=$(printf "%02d" $SHORT_DATE_DD)
    else
        # expected format: 10.0.100, use the current date.
        SHORT_DATE_YY=$(date +"%y")
        SHORT_DATE_MM=$(date +"%m")
        SHORT_DATE_DD=$(date +"%d")
        REVISION=1
    fi

    OFFICIAL_BUILD_ID="20$SHORT_DATE_YY$SHORT_DATE_MM$SHORT_DATE_DD.$REVISION"
    common_arguments+=(/p:OfficialBuildId="$OFFICIAL_BUILD_ID")
fi

if [[ -n "$OFFICIAL_BUILD_ID" ]]; then
    common_arguments+=(/p:OfficialBuildId="$OFFICIAL_BUILD_ID")
fi

# Disable apphost for ppc64le as do not support .net11
if [[ "$TARGET_ARCH" = ppc64le ]]; then
    sed -i -E 's|</OutputType>|</OutputType><UseAppHost>false</UseAppHost>|' src/vstest/test/Intent/Intent.csproj
fi

# Cross-release builds don't do lttng.
if [ -n "$CROSS_RELEASE_VERSION" ]; then
    if [[ $WITH_SYSTEM_LIBS == "default" ]]; then
        WITH_SYSTEM_LIBS=""
    fi
    WITH_SYSTEM_LIBS="${WITH_SYSTEM_LIBS}-lttng"
fi

if [[ $WITH_SYSTEM_LIBS != "default" ]]; then
    # Remove sources files that shouldn't be used because system libraries are used instead.
    OFS=$IFS
    IFS=+
    for lib in $WITH_SYSTEM_LIBS; do
        if [[ $lib == *brotli* ]]; then
            rm -rf src/runtime/src/native/external/brotli*
        fi
        if [[ $lib == *libunwind* ]]; then
            rm -rf src/runtime/src/native/external/libunwind*
        fi
        if [[ $lib == *rapidjson* ]]; then
            rm -rf src/runtime/src/native/external/rapidjson*
        fi
        if [[ $lib == *zlib* ]]; then
            rm -rf src/runtime/src/native/external/zlib*
        fi
    done
    IFS=$OFS

    common_arguments+=(--with-system-libs "${WITH_SYSTEM_LIBS}")
fi

# Prep (install .NET, previously-source-built, and other pre-built .NET dependencies)
# prep scrip was moved/renamed for .NET 9.
if [ -f "./prep-source-build.sh" ]; then
    ./prep-source-build.sh
else
    ./prep.sh
fi

# With recent versions of the VMR, we need the --source-only flag too.
# Otherwise the VMR may build in Unified Build mode.
# Build 'source-build' configuration.
common_arguments+=(--source-only)


# default to offline when building release branches.
if [[ "$REF" == release/* ]]; then
    ONLINE="${ONLINE:-false}"
fi

if [ "${ONLINE:-true}" == "true" ]; then
    build_arguments+=(--online)
fi

build_arguments+=(--use-mono-runtime /p:PortableBuild="$PORTABLE_BUILD" /p:TargetArchitecture="$CROSS_ARCH" /p:CrossBuild=true)

# Don't pick up clang configuration that is meant for the host from /etc/clang.
export CLANG_NO_DEFAULT_CONFIG=1

# Apply the fix from https://github.com/dotnet/sdk/pull/44028 manually for
# non-source-build scenario used in cross-building
export NuGetAudit=false

BUILD_EXIT_CODE=0
./build.sh ${common_arguments[0]+"${common_arguments[@]}"} ${build_arguments[0]+"${build_arguments[@]}"} || BUILD_EXIT_CODE=$?
EXIT_CODE=$BUILD_EXIT_CODE