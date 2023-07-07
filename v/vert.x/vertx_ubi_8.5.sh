#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : vert.x
# Version       : 4.3.7
# Source repo   : https://github.com/eclipse-vertx/vert.x
# Tested on     : UBI 8.6
# Language      : JAVA
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

PACKAGE_NAME=vert.x
PACKAGE_VERSION=${1:-4.3.7}
PACKAGE_URL=https://github.com/eclipse-vertx/vert.x.git

yum update -y
yum install git wget  gcc gcc-c++ openssl  -y
dnf install java-1.8.0-openjdk-devel -y

dnf -y install maven

if ! git clone $PACKAGE_URL; then
    echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    exit 0
fi

cd $PACKAGE_NAME

git checkout $PACKAGE_VERSION

if ! mvn package; then
    echo "------------------$PACKAGE_NAME:build_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    exit 1
fi

if ! mvn test; then
    echo "------------------$PACKAGE_NAME:build_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    exit 2
fi

#tests failing due to netty issue refer links for the same -
#https://github.com/netty/netty-tcnative/issues/531
#https://github.com/eclipse-vertx/vert.x/issues/4227
#https://github.com/netty/netty/issues/12432
