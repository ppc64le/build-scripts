#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : tempo-operator
# Version          : v0.11.1
# Source repo      : https://github.com/grafana/tempo-operator
# Tested on        : UBI 9.3
# Language         : Go
# Travis-Check     : true
# Script License   : version 3 of the GNU Affero General Public License
# Maintainer       : Anurag Chitrakar <Anurag.Chitrakar@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=tempo-operator
PACKAGE_URL=https://github.com/grafana/tempo-operator
PACKAGE_VERSION=${1:-0.11.1}
export SOURCE_ROOT=/root

# Install dependencies

yum -y install wget git make docker

# Cloning the repository

cd $SOURCE_ROOT
git clone ${PACKAGE_URL}
cd ${PACKAGE_NAME} && git checkout v${PACKAGE_VERSION}
export GO_VERSION=$(cat go.mod | grep go | head -n 1 | cut -d " " -f2)

# Install go 1.22.0

export PATH=$PATH:/usr/local/go/bin
export GOPATH=/root/go
export GOBIN=/usr/local/go/bin
if [ $( go version | cut -d " " -f3 ) = "go$GO_VERSION" ]; then
    echo "$GO_VERSION is already installed"
else
    cd $SOURCE_ROOT
    rm -rf $GOPATH
    rm -rf /usr/local/go
    wget https://go.dev/dl/go$GO_VERSION.linux-ppc64le.tar.gz
    tar -C /usr/local -xzf go$GO_VERSION.linux-ppc64le.tar.gz
    export PATH=$PATH:/usr/local/go/bin
    export GOPATH=/root/go
    export GOBIN=/usr/local/go/bin
    which go
    go version
fi

# Build tempo-operator

cd ${PACKAGE_NAME}
make build
make test
