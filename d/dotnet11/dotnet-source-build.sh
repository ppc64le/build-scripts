#!/bin/bash
# ----------------------------------------------------------------------------
#
# Package       : dotnet
# Version       : 11.0.100
# Source repo   : https://github.com/dotnet/dotnet
# Tested on     : RHEL 10.2
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
# .NET11 source build for ppc64le on RHEL
# ./dotnet-source-build.sh --ref v11.0.100-rc.1.26425.128 --sdk-path /home/dotnet-sdk-11.0.100-rc.1.26425.128-linux-ppc64le.tar.gz --artifacts-path /home/Private.SourceBuilt.Artifacts.11.0.100-rc.1.26425.128.linux-ppc64le.tar.gz --official-build-id 20260825.28

set -euxo pipefail

REPO=https://github.com/dotnet/dotnet
REF=main
CONFIGURATION="Release"
PORTABLE_BUILD=false 
SDK_PATH=""
ARTIFACTS_PATH=""
ONLINE="false"
OFFICIAL_BUILD_ID=""
WITH_SYSTEM_LIBS="default"
PATCH_FILE_PATH=""

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
    ninja-build
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
# See https://stackoverflow.com/questions/18620153
sed -i -E '/"sdk": \{/!b;n;s/"version": "[^"]+"/"version": "'"$sdk_version"'"/' global.json
# replace dotnet but only when it appears on the line after the "tools" key
sed -i -E '/"tools": \{/!b;n;s/"dotnet": "[^"]+"/"dotnet": "'"$sdk_version"'"/' global.json

# Remove installation of runtimes, these will install invalid binaries, or,
# worse, overwrite our architecture-specific binaries with x86_64 binaries
sed -i -E '/"runtimes"/,+4d' global.json
sed -i -zE 's/,\n *\}/\n\}/' global.json

# Disable apphost for ppc64le as do not support .net8/9/10.
sed -i -E 's|</OutputType>|</OutputType><UseAppHost>false</UseAppHost>|' src/vstest/test/Intent/Intent.csproj

# --with-system-libs: allow users to use bundled/system libraries. Default is system libraries.
# Match rpm configuration.
if [[ $WITH_SYSTEM_LIBS == "default" ]] && (( DOTNET_MAJOR >= 9 )) && [[ $PORTABLE_BUILD == "false" ]]; then
    WITH_SYSTEM_LIBS="${WITH_SYSTEM_LIBS}-lttng"
    WITH_SYSTEM_LIBS="${WITH_SYSTEM_LIBS}+brotli+"
    WITH_SYSTEM_LIBS="${WITH_SYSTEM_LIBS}+zlib+"
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

# Verify arguments with spaces are handled properly (https://github.com/dotnet/fsharp/pull/19570).
common_arguments+=(/p:OfficialBuilder="Red Hat Inc.")

# Allow fetching additional prebuilds while building non-release branches.
if [ "${ONLINE:-true}" == "true" ]; then
    build_arguments+=(--online)
fi

# Build 'source-build' configuration.
# .NET9+: set the target rid so RHEL builds use a rid that doesn't include a minor version (e.g. 'rhel.8' instead of 'rhel.8.9').
common_arguments+=(--source-only /p:TargetRid="$HOST_RID")

# Use mono runtime
build_arguments+=(--use-mono-runtime)

# Set --PortableBuild for ppc64le
build_arguments+=(/p:PortableBuild="$PORTABLE_BUILD")

# Build
BUILD_EXIT_CODE=0
./build.sh ${common_arguments[0]+"${common_arguments[@]}"} ${build_arguments[0]+"${build_arguments[@]}"} || BUILD_EXIT_CODE=$?
EXIT_CODE=$BUILD_EXIT_CODE

exit $EXIT_CODE