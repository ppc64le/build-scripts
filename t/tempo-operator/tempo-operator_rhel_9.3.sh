#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : tempo-operator
# Version          : main
# Source repo      : https://github.com/grafana/tempo-operator
# Tested on        : RHEL:9.3
# Language         : Go
# Travis-Check     : talse
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
export SOURCE_ROOT=/root

# Install dependencies

yum -y install wget git docker

# cloning the repository

cd $SOURCE_ROOT
git clone ${PACKAGE_URL}
cd ${PACKAGE_NAME}
export GO_VERSION=$(cat go.mod | grep go | head -n 1 | cut -d " " -f2)

# install go 1.22.0

cd $SOURCE_ROOT
wget https://go.dev/dl/go$GO_VERSION.linux-ppc64le.tar.gz
tar -C /usr/local -xzf go$GO_VERSION.linux-ppc64le.tar.gz
export PATH=$PATH:/usr/local/go/bin
export GOPATH=/root/go
export GOBIN=/usr/local/go/bin
which go
go version

# Build tempo-operator

cd ${PACKAGE_NAME}
make docker-build
