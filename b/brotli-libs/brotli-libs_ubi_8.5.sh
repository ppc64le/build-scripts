#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : brotli-libs
# Version       : v1.0.9
# Source repo   : https://github.com/google/brotli.git
# Tested on     : UBI 8.5
# Language      : C
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Raju.Sah@ibm.com
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ------------------------------------------------------------------------------

PACKAGE_NAME=brotli
PACKAGE_VERSION=${1:-1.0.9}
PACKAGE_URL=https://github.com/google/brotli.git

#install dependencies
yum install -y git cmake make gcc-c++

#clone the repo
cd /opt && git clone $PACKAGE_URL
cd $PACKAGE_NAME/
git checkout v$PACKAGE_VERSION

#build and install the repo.
mkdir out && cd $_
../configure-cmake
make  && make install
make test
