#!/bin/bash -ex
# -----------------------------------------------------------------------------
#
# Package       : rethinkdb
# Version       : v2.4.x
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


PACKAGE_VERSION=v2.4.x
PACKAGE_URL=https://github.com/rethinkdb/rethinkdb.git
PACKAGE_NAME=rethinkdb

yum update -y

yum install -y patch bzip2 git make gcc-c++ python2-devel openssl-devel libcurl-devel wget python2 m4 ncurses-devel libicu-devel python36 

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
make -j4
make install

make unit

