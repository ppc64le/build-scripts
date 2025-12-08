#!/bin/bash
# ----------------------------------------------------------------------------
#
# Package       : dotnet
# Version       : 10.0.100
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
# Performs a build and runs tests of https://github.com/dotnet/dotnet
# to detect regressions early

set -euxo pipefail

REPO=https://github.com/dotnet/dotnet
REF=main
CROSS_ARCH=""
DISABLE_CONTAINER=""
PORTABLE_BUILD=false 
CONTAINER_IMAGE=""
SCRIPT_ARGS="$@"

architecture=$(uname -m)
build_arguments=()
common_arguments=()
container_build_arguments=()
#SCRIPT_ARGS="--containerfile vmr-main-cross.Containerfile --cross-arch ppc64le --ref v9.0.0"
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

if [ "$DISABLE_CONTAINER" != "true" ]; then
    sudo dnf -y install podman

    container_build_arguments+=(--build-arg=TARGET_DEBIAN_ARCH=ppc64el)
    container_build_arguments+=(--build-arg=TARGET_GNU_ARCH=powerpc64le)

    if [ -n "${CONTAINER_FILE}" ]; then
        if [ -n "${CONTAINER_IMAGE}" ]; then
            echo "--containerfile can not be combined with --containerimage"
            exit 1
        fi

    CONTAINER_IMAGE="build_env"
    podman build -t "$CONTAINER_IMAGE" "${container_build_arguments[@]}" -f "$CONTAINER_FILE" .
    fi

    if [ -n "${CONTAINER_IMAGE}" ]; then
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

# Clone the dotnet vmr repo
git clone "$REPO"
cd "$(basename "$REPO" .git)"
git checkout "$REF"
COMMIT=$(git rev-parse HEAD)
echo "$REPO is at $COMMIT"

SDK_FULL_VERSION=$(jq -r .tools.dotnet global.json)
DOTNET_MAJOR=${SDK_FULL_VERSION%%.*}

if [ -n "$CROSS_ARCH" ] && [[ $REF == v8* || $REF == release/8* ]]; then
    #Patch to enable cross build for .NET8
    sed -i '/<BuildCommandArgs>$(BuildCommandArgs) \/p:OSName=$(OSNameOverride)<\/BuildCommandArgs>/a <BuildArgs>$(BuildArgs) \/p:PortableRid=$(PortableRid)<\/BuildArgs>' repo-projects/installer.proj

    sed -i '0,/<PropertyGroup>/{ /<PropertyGroup>/s#<PropertyGroup>#&\n    <BuildNonPortable>true</BuildNonPortable># }' repo-projects/runtime.proj
    sed -i.bak '/<\/BuildNonPortable>/a \    <BuildNonPortable Condition="'\''$(PortableBuild)'\'' == '\''true'\''">false<\/BuildNonPortable>' repo-projects/runtime.proj
    sed -i 's|<BuildCommandArgs>\$(BuildCommandArgs) /p:SourceBuildNonPortable=true</BuildCommandArgs>|<BuildCommandArgs>\$(BuildCommandArgs) /p:SourceBuildNonPortable=\$(BuildNonPortable)</BuildCommandArgs>|' repo-projects/runtime.proj

    sed -i 's#<SupportedRuntimeIdentifiers Condition=" '\''$(PortableBuild)'\'' == '\''false'\'' ">$(SupportedRuntimeIdentifiers);$(TargetRuntimeIdentifier)</SupportedRuntimeIdentifiers>#<SupportedRuntimeIdentifiers Condition=" '\''$(DotNetBuildFromSource)'\'' == '\''true'\'' ">$(SupportedRuntimeIdentifiers);$(TargetRuntimeIdentifier)</SupportedRuntimeIdentifiers>#' src/aspnetcore/Directory.Build.props

    sed -i 's#<DefaultAppHostRuntimeIdentifier Condition=" '\''$(PortableBuild)'\'' == '\''false'\'' ">$(TargetRuntimeIdentifier)</DefaultAppHostRuntimeIdentifier>#<DefaultAppHostRuntimeIdentifier Condition=" '\''$(DotNetBuildFromSource)'\'' == '\''true'\'' ">$(TargetRuntimeIdentifier)</DefaultAppHostRuntimeIdentifier>#' src/aspnetcore/eng/Common.props

    sed -i 's#<RuntimePackRuntimeIdentifiers Condition=" '\''$(PortableBuild)'\'' == '\''false'\'' ">$(TargetRuntimeIdentifier)</RuntimePackRuntimeIdentifiers>#<RuntimePackRuntimeIdentifiers Condition=" '\''$(DotNetBuildFromSource)'\'' == '\''true'\'' ">$(TargetRuntimeIdentifier)</RuntimePackRuntimeIdentifiers>#' src/aspnetcore/eng/tools/GenerateFiles/Directory.Build.targets.in
    sed -i 's#<AppHostRuntimeIdentifiers Condition=" '\''$(PortableBuild)'\'' == '\''false'\'' ">$(TargetRuntimeIdentifier)</AppHostRuntimeIdentifiers>#<AppHostRuntimeIdentifiers Condition=" '\''$(DotNetBuildFromSource)'\'' == '\''true'\'' ">$(TargetRuntimeIdentifier)</AppHostRuntimeIdentifiers>#' src/aspnetcore/eng/tools/GenerateFiles/Directory.Build.targets.in
    sed -i "s|<KnownCrossgen2Pack Update=\"Microsoft.NETCore.App.Crossgen2\" Condition=\" '\$(PortableBuild)' == 'false' \">|<KnownCrossgen2Pack Update=\"Microsoft.NETCore.App.Crossgen2\" Condition=\" '\$(DotNetBuildFromSource)' == 'true' \">|g" src/aspnetcore/eng/tools/GenerateFiles/Directory.Build.targets.in

    sed -i 's#<Rid>$(OSName)-$(Architecture)</Rid>#<Rid Condition=" '\''$(Rid)'\'' == '\'''\'' ">$(OSName)-$(Architecture)</Rid>#' src/installer/src/redist/targets/GetRuntimeInformation.targets
    sed -i 's#<PortableRid>\$(PortableOSName)-\$(Architecture)</PortableRid>#<PortableRid Condition=" '\''\$(PortableRid)'\'' == '\'''\'' ">\$(PortableOSName)-\$(Architecture)</PortableRid>#' src/installer/src/redist/targets/GetRuntimeInformation.targets

    sed -i 's#<BuildOsName Condition=" '\''$(PortableBuild)'\'' == '\''false'\'' ">$(TargetRuntimeIdentifier.Substring(0,$(TargetRuntimeIdentifier.IndexOf('"'"'-'"'"'))))</BuildOsName>#<BuildOsName Condition=" '\''$(DotNetBuildFromSource)'\'' == '\''true'\'' ">$(TargetRuntimeIdentifier.Substring(0,$(TargetRuntimeIdentifier.IndexOf('"'"'-'"'"'))))</BuildOsName>#' src/aspnetcore/src/Framework/App.Runtime/src/Microsoft.AspNetCore.App.Runtime.csproj

    sed -i '/^done/a __PortableBuild=1' src/runtime/eng/native/build-commons.sh

    sed -i 's#<LatestPackageReference Include="Microsoft\.NETCore\.App\.Runtime\.\$(TargetRuntimeIdentifier)" Condition=" '\''\$(PortableBuild)'\'' == '\''false'\'' "#<LatestPackageReference Include="Microsoft\.NETCore\.App\.Runtime\.\$(TargetRuntimeIdentifier)" Condition=" '\''\$(DotNetBuildFromSource)'\'' == '\''true'\'' "#' src/aspnetcore/eng/Dependencies.props
    sed -i 's#<LatestPackageReference Include="Microsoft\.NETCore\.App\.Crossgen2\.\$(TargetRuntimeIdentifier)" Condition=" '\''\$(PortableBuild)'\'' == '\''false'\'' "#<LatestPackageReference Include="Microsoft\.NETCore\.App\.Crossgen2\.\$(TargetRuntimeIdentifier)" Condition=" '\''\$(DotNetBuildFromSource)'\'' == '\''true'\'' "#' src/aspnetcore/eng/Dependencies.props
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
if (( DOTNET_MAJOR >= 9 )); then
    common_arguments+=(--source-only)
fi

# default to offline when building release branches.
if [[ "$REF" == release/* ]]; then
    ONLINE="${ONLINE:-false}"
fi

if [ "${ONLINE:-true}" == "true" ]; then
    build_arguments+=(--online)
fi

# Use mono runtime for ppc64le
build_arguments+=(--use-mono-runtime)

# .NET 8 requires '--' for sending arguments to MSBuild.
if [ "$DOTNET_MAJOR" == 8 ]; then
    build_arguments+=(--)
fi

# Cross-builds are portable to minimize dependencies on the cross-build environment.
if [ -n "$CROSS_ARCH" ]; then
    PORTABLE_BUILD=true
fi

build_arguments+=(/p:PortableBuild="$PORTABLE_BUILD")

if [ -n "$CROSS_ARCH" ]; then
    if [ "$DOTNET_MAJOR" == 8 ]; then
        build_arguments+=(/p:DotNetBuildVertical=true /p:OverrideTargetRid=linux-"$CROSS_ARCH")
    else
        build_arguments+=(/p:TargetArchitecture="$CROSS_ARCH")
    fi

    # Apply the fix from https://github.com/dotnet/sdk/pull/44028 manually for
    # non-source-build scenario used in cross-building
    export NuGetAudit=false
fi

# Use a "daily build" version format.
if (( DOTNET_MAJOR >= 10 )); then
    # When unset, use a timestamp from two days ago so it is likely Microsoft has packages that have this version or higher.
    OFFICIAL_BUILD_ID="${OFFICIAL_BUILD_ID:-$(date -d "2 days ago" +"%Y%m%d").1}"
    common_arguments+=(/p:OfficialBuildId="$OFFICIAL_BUILD_ID")
fi

BUILD_EXIT_CODE=0
./build.sh ${common_arguments[0]+"${common_arguments[@]}"} ${build_arguments[0]+"${build_arguments[@]}"} || BUILD_EXIT_CODE=$?
EXIT_CODE=$BUILD_EXIT_CODE
