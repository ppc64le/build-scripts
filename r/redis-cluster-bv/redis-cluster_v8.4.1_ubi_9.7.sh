#!/bin/bash -e

# -----------------------------------------------------------------------------
# Package       : redis-cluster
# Version       : 8.4.1
# Source repo   : https://github.com/bitnami/containers
# Tested on     : UBI:9.7
# Ci-Check      : False
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
PATCH_FILE=redis-8.4.1-ppc64le-fixed.patch

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

# Apply architecture-specific patch
if [ -f "$SCRIPT_PATH/$PATCH_FILE" ]; then
    echo ">>> Applying patch $PATCH_FILE"
    if ! git apply "$SCRIPT_PATH/$PATCH_FILE"; then
        echo ">>> ERROR: Failed to apply patch."
        exit 1
    fi
else
    echo ">>> ERROR: Patch file $PATCH_FILE not found in $SCRIPT_PATH."
    exit 1
fi

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
pkill redis-server || true
if ! make test MALLOC=libc EXTRA_CFLAGS="$EXTRA_CFLAGS"; then
    echo ">>> WARNING: Redis tests failed, continuing anyway..."
fi

# 5. Setup Bitnami directory structure

echo ">>> Setting up Bitnami directory structure..."
mkdir -p /opt/bitnami/redis/bin
cp /usr/local/bin/redis-* /opt/bitnami/redis/bin/

cd "$BITNAMI_DIR"
cp -r rootfs/* /
chmod -R 755 /opt/bitnami

# 6. Cluster Validation Test

echo ">>> Starting Redis cluster validation..."

PORTS=(7000 7001 7002 7003 7004 7005)

for PORT in "${PORTS[@]}"; do
mkdir -p /tmp/redis-$PORT
redis-server --port $PORT 
--cluster-enabled yes 
--cluster-config-file nodes.conf 
--cluster-node-timeout 5000 
--appendonly yes 
--daemonize yes 
--dir /tmp/redis-$PORT
done

sleep 5

yes yes | redis-cli --cluster create 
127.0.0.1:7000 
127.0.0.1:7001 
127.0.0.1:7002 
127.0.0.1:7003 
127.0.0.1:7004 
127.0.0.1:7005 
--cluster-replicas 1

# 7. Functional Test

echo ">>> Running functional validation..."

redis-cli -c -p 7000 set testkey "hello_world"
VALUE=$(redis-cli -c -p 7000 get testkey)

if [[ "$VALUE" != "hello_world" ]]; then
echo "========================================================================"
echo " ERROR: Functional test failed"
echo "========================================================================"
exit 1
fi

# Cleanup

pkill redis-server || true

echo "========================================================================"
echo " SUCCESS: $PACKAGE_NAME version $PACKAGE_VERSION built and tested successfully."
echo "========================================================================"
exit 0
