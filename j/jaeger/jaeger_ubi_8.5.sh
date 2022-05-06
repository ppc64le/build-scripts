#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: github.com/uber/jaeger-lib
# Version	: v2.2.0
# Source repo	: https://github.com/uber/jaeger-lib
# Tested on	: UBI: 8.5
# Language      : GO
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Muskaan Sheik <Muskaan.Sheik@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=jaeger-lib
PACKAGE_VERSION=${1:-v2.2.0}
PACKAGE_URL=https://github.com/uber/jaeger-lib

yum -y update && yum install -y wget git golang make python38 python38-devel python39 python39-devel python2 python2-devel python3 python3-devel jq

export TEST=true
export COVERAGE=true
export USE_DEP=true
   
mkdir -p /home/tester/go/bin /home/tester/go/src/github.com/uber

export PATH=$PATH:/bin/go/bin
export GOPATH=/home/tester/go
export PATH=$GOPATH/bin:$PATH

curl https://raw.githubusercontent.com/golang/dep/master/install.sh | sh

cd $GOPATH/src/github.com/uber
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

go mod init
go mod tidy


make install-ci USE_DEP=$USE_DEP

go mod vendor

sed -i '5d' ./scripts/updateLicenses.sh && sed -i "5ipython3 scripts/updateLicense.py \$(go list -json ./... | jq -r '.Dir + \"/\" + (.GoFiles | .[])')" ./scripts/updateLicenses.sh

if [ "$COVERAGE" == true ]; then make test-ci ; else echo 'skipping tests'; fi
if [ "$TEST" == true ]; then make test-only-ci ; else echo 'skipping tests'; fi
