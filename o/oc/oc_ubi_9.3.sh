#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : openshift/oc
# Version       : openshift-clients-4.17.0-202409111134
# Source repo   : https://github.com/openshift/oc.git
# Tested on     : UBI 9.3
# Language      : Go
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Shubham Gupta <Shubham.Gupta43@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=oc
PACKAGE_VERSION=${1:-openshift-clients-4.17.0-202409111134}
PACKAGE_URL=https://github.com/openshift/oc.git

yum install -y git gcc make wget

GO_VERSION=1.23.2
wget https://golang.org/dl/go$GO_VERSION.linux-ppc64le.tar.gz && \
tar -C /usr/local -xzf go$GO_VERSION.linux-ppc64le.tar.gz && \
rm -rf go$GO_VERSION.linux-ppc64le.tar.gz
export GOROOT=/usr/local/go && \
export GOPATH=$HOME && \
export PATH=$GOPATH/bin:$GOROOT/bin:$PATH

dnf install -y krb5-devel
dnf install -y gpgme-devel
dnf install -y libassuan-devel

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

if ! make oc; then
    echo "------------------$PACKAGE_NAME:build_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    exit 1
fi

if ! make test; then
    echo "------------------$PACKAGE_NAME:test_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    exit 2
else
   echo "------------------$PACKAGE_NAME:Both_build_and_test_passed---------------------------------------"
   echo "$PACKAGE_URL $PACKAGE_NAME"
   exit 0

fi

