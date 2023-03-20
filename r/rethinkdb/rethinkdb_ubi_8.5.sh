#!/bin/bash -ex
# -----------------------------------------------------------------------------
#
# Package       : rethinkdb
# Version       : v2.4.3
# Source repo   : https://github.com/rethinkdb/rethinkdb.git
# Tested on     : UBI 8.5
# Language      : C++
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Vinod K <Vinod.K1@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------


PACKAGE_VERSION=${1:-v2.4.3}
PACKAGE_URL=https://github.com/rethinkdb/rethinkdb.git
PACKAGE_NAME=rethinkdb

yum update -y

yum install -y patch bzip2 git make gcc-c++ python2-devel openssl-devel libcurl-devel wget python2 m4 ncurses-devel libicu-devel python36 python3-devel protobuf-c

curl -O https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
dnf install -y epel-release-latest-8.noarch.rpm
rm -f epel-release-latest-8.noarch.rpm

curl https://raw.githubusercontent.com/creationix/nvm/v0.33.0/install.sh| bash
source ~/.nvm/nvm.sh
nvm install stable
nvm use stable

ln -s /usr/bin/python2 /usr/bin/python

git clone $PACKAGE_URL
cd $PACKAGE_NAME

git checkout $PACKAGE_VERSION
./configure --allow-fetch

if ! make && make install; then
    echo "------------------$PACKAGE_NAME:Build_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
    exit 1
fi

if ! make unit; then
    echo "------------------$PACKAGE_NAME::Build_and_Test_fails-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Fail|  Build_and_Test_fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME::Build_and_Test_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Build_and_Test_Success"
    exit 0
fi


