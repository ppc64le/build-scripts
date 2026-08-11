#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : vault
# Version          : v1.19.5
# Source repo      : https://github.com/hashicorp/vault
# Tested on        : UBI:9.7
# Language         : Go
# Ci-Check         : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Pratik Tonage <Pratik.Tonage@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

# ---------------------------
# Configuration
# ---------------------------
PACKAGE_NAME=vault
PACKAGE_VERSION=${1:-v1.19.5}
PACKAGE_URL=https://github.com/hashicorp/vault
BUILD_HOME="$(pwd)"

# ---------------------------
# Install dependencies
# ---------------------------
echo "Installing dependencies..."
yum install -y \
    openssl make git gcc wget tar gzip \
    ca-certificates libcap tzdata procps shadow-utils util-linux

# ---------------------------
# Install and setup GO
# ---------------------------
echo "Installing Go..."
export GO_VERSION=${GO_VERSION:-1.24.13}
export GOROOT=${GOROOT:-"/usr/local/go"}
export GOPATH=${GOPATH:-$HOME/go}
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin:/usr/local/bin
wget https://golang.org/dl/go${GO_VERSION}.linux-ppc64le.tar.gz
tar -C /usr/local -xvzf go${GO_VERSION}.linux-ppc64le.tar.gz
rm -rf go${GO_VERSION}.linux-ppc64le.tar.gz
go version

# ---------------------------
# Clone repository
# ---------------------------
cd "${BUILD_HOME}"
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

# ---------------------------------
# Bootstrap dependencies
# ---------------------------------
echo "Running make bootstrap..."
ret=0
make bootstrap || ret=$?
if [ $ret -ne 0 ]; then
    set +ex
    echo "------------------ ${PACKAGE_NAME}: Bootstrap Failed ------------------"
    exit 1
fi

# ---------------------------
# Build Vault
# ---------------------------
echo "Building Vault..."
make dev || ret=$?
if [ $ret -ne 0 ]; then
    set +ex
    echo "------------------ ${PACKAGE_NAME}: Build Failed ------------------"
    exit 2
fi

VAULT_BIN="$BUILD_HOME/$PACKAGE_NAME/bin/vault"

# To run tests, type make test. Note: this requires Docker to be installed.
# make test

#Smoke test
echo "Running smoke test..."
if ! $VAULT_BIN version; then
    echo "Smoke test failed"
    exit 3
fi


echo "$PACKAGE_NAME build and smoke test successful!"
echo "Binary available at: $VAULT_BIN"

# -----------------------------------------------------------------------------
# Notes:
# -----------------------------------------------------------------------------
# - Tests are skipped due to dependency on external services like:
#   consul, cockroachDB, nomad, mssql, openssh-server, etc.
#
# - Many of these images are not available or stable on ppc64le.
#
# - Internal validation was performed using locally built or IBM Container Registry (ICR) images.
#
# -----------------------------------------------------------------------------
