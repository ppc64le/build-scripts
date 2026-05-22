#!/bin/bash -ex
# -----------------------------------------------------------------------------
#
# Package		: MinIO
# Version		: RELEASE.2025-10-15T17-29-55Z
# Source repo 	: https://github.com/minio/minio
# Tested on		: UBI 9.7
# Language		: GO
# Ci-Check  	: True
# Script License: Apache License, Version 2 or later
# Maintainer	: Simran Sirsat <Simran.Sirsat@ibm.com>
#
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------


PACKAGE_NAME=minio
PACKAGE_VERSION=${1:-RELEASE.2025-10-15T17-29-55Z}
PACKAGE_URL=https://github.com/minio/minio

SCRIPT_PATH=$(dirname $(realpath $0))

# Safer build location
BUILD_HOME=/tmp/minio-build

# Clean old build if exists
rm -rf "$BUILD_HOME"
mkdir -p "$BUILD_HOME"

yum install -y wget git tar make

GO_VERSION=1.24.8

# Install Go and setup working directory
wget https://golang.org/dl/go$GO_VERSION.linux-ppc64le.tar.gz
tar -C /usr/local -xzf go$GO_VERSION.linux-ppc64le.tar.gz
mkdir -p /home/tester/go/src 
rm -f go$GO_VERSION.linux-ppc64le.tar.gz

export PATH=$PATH:/usr/local/go/bin
export GOPATH=/home/tester/go
export GO111MODULE=on

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

# -----------------------------
# Clone and Prepare Repository
# -----------------------------
cd $BUILD_HOME
git clone ${PACKAGE_URL}
cd ${PACKAGE_NAME} && git checkout ${PACKAGE_VERSION}
git apply ${SCRIPT_PATH}/${PACKAGE_NAME}-${PACKAGE_VERSION}.patch

if ! make build; then
	echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
    echo "$PACKAGE_NAME  |  $PACKAGE_VERSION |  $OS_NAME | GitHub | Fail |  Install_Fails"
	exit 1
fi

if ! make install; then
	echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_NAME  |  $PACKAGE_VERSION |  $OS_NAME | GitHub | Fail |  Install_Fails"
	exit 1
fi

# Test (create non-root user for testing)

useradd -m -s /bin/bash tester || true
groupadd podman || true
usermod -aG podman tester || true

# Give ownership of minIO source to tester
chown -R tester:tester $BUILD_HOME/$PACKAGE_NAME || true

# Switch to tester user and run tests

# Ensure tester owns Go workspace and cache
chown -R tester:tester /home/tester/go

# Ensure build dir ownership
chown -R tester:tester "$BUILD_HOME"

su - tester -c "
export PACKAGE_NAME='$PACKAGE_NAME'
export PACKAGE_VERSION='$PACKAGE_VERSION'
export OS_NAME='$OS_NAME'
export BUILD_HOME='$BUILD_HOME'

export PATH='/usr/local/go/bin:\$PATH'
export GOPATH='/home/tester/go'
export GO111MODULE='on'

set -e
set -x

cd '$BUILD_HOME/$PACKAGE_NAME'

if ! GOMAXPROCS=2 go test -v -p 1 -parallel 1 -timeout 30m ./...; then
    echo '------------------$PACKAGE_NAME:test_fails------------------'
    echo '$PACKAGE_NAME | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_success_but_test_Fails'
    exit 1
else
    echo '------------------$PACKAGE_NAME:test_success------------------'
    echo '$PACKAGE_NAME | $PACKAGE_VERSION | $OS_NAME | GitHub | Pass | Both_Install_and_Test_Success'
    exit 0
fi
"
