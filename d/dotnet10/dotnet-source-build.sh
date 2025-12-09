#!/bin/bash
# ----------------------------------------------------------------------------
#
# Package       : dotnet
# Version       : 10.0.0
# Source repo   : https://github.com/dotnet/dotnet
# Tested on     : Ubuntu
# Language      : dotnet
# Ci-Check  : False
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

set -euxo pipefail

REPO=https://github.com/dotnet/dotnet
REF=main
CONFIGURATION="Release"
PORTABLE_BUILD=false 
SDK_PATH=""
ARTIFACTS_PATH=""
ONLINE="false"

build_arguments=()
common_arguments=()

source /etc/os-release
ARCH=$(uname -m)
HOST_RID=${ID}.${VERSION_ID%.*}-${ARCH}

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
        # --configuration: build configuration (Release/Debug)
        --configuration)
            shift
            CONFIGURATION="$1"
            ;;
        # --sdk-path: path to the .NET SDK tarball file
        --sdk-path)
            shift
            SDK_PATH="$1"
            ;;
        # tarballs with packages
        # --artifacts-path: artifacts produced by previous build
        --artifacts-path)
            shift
            ARTIFACTS_PATH="$1"
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

# Install dependencies
sudo dnf repolist --all
packages=(
    brotli-devel
    clang
    cmake
    elfutils
    file
    findutils
    git
    glibc-langpack-en
    hostname
    jq
    krb5-devel
    libicu-devel
    llvm
    lttng-ust-devel
    make
    openssl-devel
    python3
    tar
    zip
    zlib-devel
    lld
)

sudo dnf -y install "${packages[@]}"

# Clone dotnet repo
git clone "$REPO"
cd "$(basename "$REPO" .git)"
git checkout "$REF"
COMMIT=$(git rev-parse HEAD)
echo "$REPO is at $COMMIT"

# Env variables
BUILD_DIR="$(pwd)"  
EXIT_CODE=256
BUILD_EXIT_CODE=256

# Copy sdk and pre-built-artifacts tarball
mkdir dotnet-sdk-$ARCH
cp -r "$SDK_PATH" dotnet-sdk-$ARCH
cp -r "$ARTIFACTS_PATH" dotnet-sdk-$ARCH
nuget_dir=$(readlink -f "dotnet-sdk-$ARCH")

# Make the pre-built ppc64le nuget packages available
find . -iname 'nuget.config' -exec sed -i -zE 's|(<packageSources>.*<clear ?/>)|\1\n<add key="'"$ARCH"'" value="'"$nuget_dir"'" />|' {} \;

# Extract the previously build sdk tarball
if [ ! -d .dotnet ]; then
    mkdir .dotnet
    tar xf "$SDK_PATH" -C .dotnet
    common_arguments+=(--with-sdk $(pwd)/.dotnet)
fi

# Extract the previously build pre-built-artifacts tarball
mkdir packages
common_arguments+=(--with-packages $(pwd)/packages)
tar xf "$ARTIFACTS_PATH" -C packages

sdk_versions=( .dotnet/sdk/* )
sdk_version=$(basename "${sdk_versions[0]}")

# Set dotnet path
DOTNET_ROOT=$(pwd)/.dotnet
export DOTNET_ROOT

SDK_FULL_VERSION=$(jq -r .tools.dotnet global.json)
DOTNET_MAJOR=${SDK_FULL_VERSION%%.*}

# Replace version but only when it appears on the line after the "sdk" key
sed -i -E '/"sdk": \{/!b;n;s/"version": "[^"]+"/"version": "'"$sdk_version"'"/' global.json
# replace dotnet but only when it appears on the line after the "tools" key
sed -i -E '/"tools": \{/!b;n;s/"dotnet": "[^"]+"/"dotnet": "'"$sdk_version"'"/' global.json

# Remove installation of runtimes, these will install invalid binaries, or,
# worse, overwrite our architecture-specific binaries with x86_64 binaries
sed -i -E '/"runtimes"/,+4d' global.json
sed -i -zE 's/,\n *\}/\n\}/' global.json

# --with-system-libs: allow users to use bundled/system libraries. Default is system libraries.
if (( DOTNET_MAJOR >= 9 )) && [[ $PORTABLE_BUILD == "false" ]]; then
    # Match rpm configuration.
    
    WITH_SYSTEM_LIBS=""
    if (( DOTNET_MAJOR >= 10 )); then
         WITH_SYSTEM_LIBS="${WITH_SYSTEM_LIBS}-lttng"
    fi
    WITH_SYSTEM_LIBS="${WITH_SYSTEM_LIBS}+brotli+"
    WITH_SYSTEM_LIBS="${WITH_SYSTEM_LIBS}+zlib+"

    OFS=$IFS
    IFS=+
    for lib in $WITH_SYSTEM_LIBS; do
        if [[ $lib == *brotli* ]]; then
            rm -rf src/runtime/src/native/external/brotli*
        fi
        if [[ $lib == *libunwind* ]]; then
            rm -rf src/runtime/src/native/external/libunwind*
        fi
        if [[ $lib == *zlib* ]]; then
            rm -rf src/runtime/src/native/external/zlib*
        fi
    done
    IFS=$OFS

    common_arguments+=(--with-system-libs "${WITH_SYSTEM_LIBS}")
fi

# Allow fetching additional prebuilds while building non-release branches.
if [ "${ONLINE:-true}" == "true" ]; then
    build_arguments+=(--online)
fi

# Build 'source-build' configuration.
# .NET9+: set the target rid so RHEL builds use a rid that doesn't include a minor version (e.g. 'rhel.8' instead of 'rhel.8.9').
if (( DOTNET_MAJOR >= 9 )); then
    common_arguments+=(--source-only /p:TargetRid="$HOST_RID")
fi

# Use a "daily build" version format.
if (( DOTNET_MAJOR >= 10 )); then
    # When unset, use a timestamp from two days ago so it is likely Microsoft has packages that have this version or higher.
    OFFICIAL_BUILD_ID="${OFFICIAL_BUILD_ID:-$(date -d "2 days ago" +"%Y%m%d").1}"
    common_arguments+=(/p:OfficialBuildId="$OFFICIAL_BUILD_ID")
fi

# Use mono runtime
build_arguments+=(--use-mono-runtime)

# Set --PortableBuild for ppc64le
build_arguments+=(/p:PortableBuild="$PORTABLE_BUILD")

# Build
BUILD_EXIT_CODE=0
./build.sh ${common_arguments[0]+"${common_arguments[@]}"} ${build_arguments[0]+"${build_arguments[@]}"} || BUILD_EXIT_CODE=$?
EXIT_CODE=$BUILD_EXIT_CODE

exit $EXIT_CODE
