#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : RediSearch
# Version       : 2.4.0
# Source repo   : https://github.com/RediSearch/RediSearch.git
# Tested on     : UBI 8.5
# Language      : C,Python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Vinod.K <Vinod.K1@ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_VERSION=v2.4.16
PACKAGE_URL=https://github.com/RediSearch/RediSearch.git
PACKAGE_NAME=RediSearch

yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
yum update -y
yum install -y wget git gcc gcc-c++ make python38 cmake  libstdc++-static python3-devel

alternatives --set python /usr/bin/python3
alias python="python3"

git clone --recursive https://github.com/RediSearch/RediSearch.git
cd $PACKAGE_NAME/
git checkout $PACKAGE_VERSION

make fetch
make build TEST=1

make c_tests
