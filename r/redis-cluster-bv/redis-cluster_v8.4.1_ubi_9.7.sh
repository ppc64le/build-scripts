#!/bin/bash -e

# -----------------------------------------------------------------------------
# Package       : redis-cluster
# Version       : 8.4.1
# Source repo   : https://github.com/bitnami/containers
# Tested on     : UBI:9.7
# Ci-Check      : True
# Language      : C
# Script License: Apache License, Version 2 or later
# Maintainer    : Amit Kumar <amit.kumar282@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
# 					 It may not work as expected with newer versions of the
# 					 package and/or distribution. In such case, please
# 					 contact "Maintainer" of this script.
# -----------------------------------------------------------------------------

PACKAGE_NAME=redis-cluster
PACKAGE_VERSION=${1:-8.4.1}
PACKAGE_URL=https://github.com/bitnami/containers
COMMIT_ID=8fe1092de5cf5664de9f8afc7764b51d69d4da86
SCRIPT_PACKAGE_VERSION=$PACKAGE_VERSION
SCRIPT_PATH=$(dirname $(realpath $0))

# 1. Install OS Dependencies
dnf update -y
dnf install -y git wget tar make which procps hostname gcc gcc-c++ openssl openssl-devel ncurses ncurses-devel libstdc++ libstdc++-devel \
python3 jq tcl diffutils patch

# 2. Clone repository
if [ -d "$PACKAGE_NAME" ]; then
echo ">>> Removing existing directory $PACKAGE_NAME..."
rm -rf "$PACKAGE_NAME"
fi

git clone $PACKAGE_URL $PACKAGE_NAME
cd $PACKAGE_NAME
git checkout $COMMIT_ID

BITNAMI_DIR=$(pwd)/bitnami/redis-cluster/8.4/debian-12

# 3. Build Redis from source
echo ">>> Building Redis from source..."
cd $SCRIPT_PATH
REDIS_PACKAGE_NAME=redis
REDIS_PACKAGE_URL=https://github.com/redis/redis
PATCH_FILE_DEBUG=redis-8.4.1-ppc64le-debug.patch
PATCH_FILE_UTIL=redis-8.4.1-ppc64le-util.patch

# Clone repository
if [ -d "$REDIS_PACKAGE_NAME" ]; then
    rm -rf "$REDIS_PACKAGE_NAME"
fi

if ! git clone $REDIS_PACKAGE_URL $REDIS_PACKAGE_NAME; then
    echo ">>> ERROR: Failed to clone Redis repository."
    exit 1
fi

cd $REDIS_PACKAGE_NAME

# Checkout specific version
git checkout $PACKAGE_VERSION

# Apply architecture-specific patches
echo ">>> Applying ppc64le patches..."

if [ -f "$SCRIPT_PATH/$PATCH_FILE_DEBUG" ]; then
    echo ">>> Applying debug.c patch: $PATCH_FILE_DEBUG"
    if ! patch -p1 --fuzz=3 --ignore-whitespace < "$SCRIPT_PATH/$PATCH_FILE_DEBUG"; then
        echo ">>> ERROR: Failed to apply debug.c patch."
        exit 1
    fi
else
    echo ">>> ERROR: Patch file $PATCH_FILE_DEBUG not found in $SCRIPT_PATH."
    exit 1
fi

if [ -f "$SCRIPT_PATH/$PATCH_FILE_UTIL" ]; then
    echo ">>> Applying util.tcl patch: $PATCH_FILE_UTIL"
    if ! patch -p1 --fuzz=3 --ignore-whitespace < "$SCRIPT_PATH/$PATCH_FILE_UTIL"; then
        echo ">>> ERROR: Failed to apply util.tcl patch."
        exit 1
    fi
else
    echo ">>> ERROR: Patch file $PATCH_FILE_UTIL not found in $SCRIPT_PATH."
    exit 1
fi

echo ">>> All patches applied successfully."

# Detect Power 10 and apply optimization flags
EXTRA_CFLAGS=""
if [[ $(uname -m) == "ppc64le" ]]; then
    if grep -iq "POWER10" /proc/cpuinfo || lscpu | grep -iq "POWER10"; then
        echo ">>> Power 10 CPU detected. Applying P10 optimization flags..."
        EXTRA_CFLAGS="-mcpu=power10 -mtune=power10"
    fi
fi

# Build Redis
if ! make MALLOC=libc EXTRA_CFLAGS="$EXTRA_CFLAGS" -j$(nproc); then
    echo ">>> ERROR: Redis build failed."
    exit 1
fi

make install

# 4. Run Redis Test Suite
echo ">>> Running Redis test suite..."
if ! make test MALLOC=libc EXTRA_CFLAGS="$EXTRA_CFLAGS"; then
    echo ">>> FAIL: Redis tests failed ..."
    exit 2
fi

echo "========================================================================"
echo " SUCCESS: $PACKAGE_NAME version $PACKAGE_VERSION built and tested successfully."
echo "========================================================================"
exit 0
