#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : openshift/oc
# Version       : openshift-clients-4.12.0-202208031327
# Source repo   : https://github.com/openshift/oc.git
# Tested on     : UBI 8.6
# Language      : Go
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Shreya Kajbaje <Shreya.Kajbaje@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=openshift/oc
PACKAGE_VERSION=${1:-openshift-clients-4.12.0-202208031327}
PACKAGE_URL=https://github.com/openshift/oc.git

yum install -y git gcc make wget

GO_VERSION=1.20

wget https://golang.org/dl/go$GO_VERSION.linux-ppc64le.tar.gz
tar -C /bin -xf go$GO_VERSION.linux-ppc64le.tar.gz

rm -f go$GO_VERSION.linux-ppc64le.tar.gz

export PATH=$PATH:/bin/go/bin
export GOPATH=/home/go

mkdir -p $GOPATH/src && cd $GOPATH/src

dnf install krb5-devel
dnf install gpgme-devel
dnf install libassuan-devel

if ! git clone $PACKAGE_URL; then
    echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    exit 0
fi

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
fi