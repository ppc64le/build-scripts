#!/bin/bash -ex
# -----------------------------------------------------------------------------
#
# Package       : redis-operator
# Version       : v0.24.0
# Source repo   : https://github.com/OT-CONTAINER-KIT/redis-operator
# Tested on     : UBI:9.7
# Ci-Check      : True
# Language      : GO
# Script License: Apache License, Version 2 or later
# Maintainer    : Manya Rusiya<Manya.Rusiya@ibm.com>
#
# Disclaimer       : This script has been tested in non-root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
# -----------------------------------------------------------------------------

PACKAGE_NAME=redis-operator
PACKAGE_VERSION=${1:-v0.24.0}
PACKAGE_URL=https://github.com/OT-CONTAINER-KIT/redis-operator
PACKAGE_DIR=redis-operator
WORKDIR=$(pwd)

sudo chown -R $(whoami):$(whoami) $HOME || true

# Install system dependencies
echo ">>> Installing System Dependencies"
sudo yum install -y \
    git make wget gcc gcc-c++ tar

# Install GO
export GO_VERSION=${GO_VERSION:-1.23.4}
export GOROOT=${GOROOT:-"/usr/local/go"}
export GOPATH=${GOPATH:-$HOME/go}
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin:/usr/local/bin
echo ">>> Installing GO"
wget https://golang.org/dl/go${GO_VERSION}.linux-ppc64le.tar.gz
sudo tar -C /usr/local -xvzf go${GO_VERSION}.linux-ppc64le.tar.gz
rm -rf go${GO_VERSION}.linux-ppc64le.tar.gz

# Clone the repository
cd $WORKDIR
git clone $PACKAGE_URL
cd $PACKAGE_DIR && git checkout $PACKAGE_VERSION

go mod tidy

# Build the binary
echo ">>> Building binary"
ret=0
make manager || ret=$?
if [ $ret -ne 0 ]; then
    echo "---------------- $PACKAGE_NAME: Build Failed ----------------"
    exit 1
else
    echo "---------------- $PACKAGE_NAME: Build Successfull ----------------"
fi

# Verify the binary exists
echo ">>> Verifying binary"
if [ -f "bin/manager" ]; then
    echo ">>> Binary exists"
else
    echo ">>> Binary not found"
    exit 1
fi

# Install setup-envtest and configure Kubernetes envtest assets for running tests
echo ">>> Installing setup-envtest"
go install sigs.k8s.io/controller-runtime/tools/setup-envtest@latest

# Create a user-writable directory for kubebuilder assets
export KUBEBUILDER_ASSETS_DIR=$HOME/.kubebuilder
mkdir -p $KUBEBUILDER_ASSETS_DIR

# Configure setup-envtest to use the user-writable directory
echo ">>> Setting up envtest with Kubernetes 1.29.0"
export KUBEBUILDER_ASSETS=$(setup-envtest use 1.29.0 -p path --bin-dir $KUBEBUILDER_ASSETS_DIR)

# Verify KUBEBUILDER_ASSETS is set
if [ -z "$KUBEBUILDER_ASSETS" ]; then
    echo ">>> Failed to set KUBEBUILDER_ASSETS"
    exit 1
fi
echo ">>> KUBEBUILDER_ASSETS set to: $KUBEBUILDER_ASSETS"

# Set USER environment variable if not set (required by integration test scripts)
export USER=${USER:-$(whoami)}
echo ">>> USER set to: $USER"

# Unit tests
echo ">>> Running Unit Tests"
ret=0
make unit-tests || ret=$?
if [ $ret -ne 0 ]; then
    echo "---------------- $PACKAGE_NAME: Unit Tests Failed ----------------"
    exit 1
else
    echo "---------------- $PACKAGE_NAME: Unit Tests Successfull ----------------"
fi
# Integration tests
echo ">>> Running Integration Test Setup and Tests"
ret=0
make integration-test-setup || ret=$?
if [ $ret -ne 0 ]; then
    echo "---------------- $PACKAGE_NAME: Integration Test Setup Failed ----------------"
    exit 1
else
    echo "---------------- $PACKAGE_NAME: Integration Test Setup Successfull ----------------"
fi
make integration-tests || ret=$?
if [ $ret -ne 0 ]; then
    echo "---------------- $PACKAGE_NAME: Integration Test Failed ----------------"
    exit 1
else
    echo "---------------- $PACKAGE_NAME: Integration Test Sucessfull ----------------"
fi

echo "---------------- $PACKAGE_NAME:$PACKAGE_VERSION Build and Test Successfull----------------"
exit 0
