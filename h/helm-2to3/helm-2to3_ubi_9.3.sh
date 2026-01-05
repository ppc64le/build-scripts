#!/bin/bash -e

# -----------------------------------------------------------------------------
#
# Package           : helm-2to3
# Version           : v0.10.3
# Source repo       : https://github.com/helm/helm-2to3.git
# Tested on         : UBI:9.3
# Language          : Go
# Ci-Check      : True
# Script License    : Apache License, Version 2.0
# Maintainer        : Vinod K <Vinod.K1@ibm.com>
#
# Disclaimer        : This script has been tested in root mode on given
# ==========          platform using the mentioned version of the package.
#                     It may not work as expected with newer versions of the
#                     package and/or distribution. In such case, please
#                     contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=helm-2to3
PACKAGE_VERSION=${1:-v0.10.3}
PACKAGE_URL=https://github.com/helm/helm-2to3.git
OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

dnf install -y git make gcc gcc-c++

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

GO_VERSION=$(cat go.mod | grep "^go" | sed -E "s/^.*go\s+(.+)\s*$/\1/g")
cd ..
curl -LO https://go.dev/dl/go$GO_VERSION.linux-$(arch).tar.gz
rm -rf /usr/local/go && tar -C /usr/local -xzf go$GO_VERSION.linux-$(arch).tar.gz
export PATH=$PATH:/usr/local/go/bin

cd $PACKAGE_NAME

if ! make build; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
    exit 1
else
    echo "------------------$PACKAGE_NAME:install_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Install_Success"
    exit 0
fi

# there are no tests available for this reposiory as of v0.10.3
