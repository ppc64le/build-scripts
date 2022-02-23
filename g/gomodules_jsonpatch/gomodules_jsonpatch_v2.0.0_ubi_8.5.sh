#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package		: jsonpatch
# Version		: v2.0.0
# Source repo	: https://github.com/gomodules/jsonpatch
# Tested on		: UBI 8.5
# Language      	: GO
# Travis-Check  	: True
# Script License	: Apache License 2.0
# Maintainer	: Reynold Vaz / Vedang Wartikar <Vedang.Wartikar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=jsonpatch
PACKAGE_URL=https://github.com/gomodules/jsonpatch.git
PACKAGE_VERSION=${1:-v2.0.0}

export GOPATH=${GOPATH:-$HOME/go}

#Install the required dependencies
yum install -y go git

mkdir -p $GOPATH/src/github.com/jsonpatch_main && cd $GOPATH/src/github.com/jsonpatch_main
git clone $PACKAGE_URL && cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
cd v2

go build
go test -v