#!/bin/bash -e

# -----------------------------------------------------------------------------
#
# Package       : mimalloc
# Version       : v1.7.3
# Source repo   : https://github.com/microsoft/mimalloc.git
# Tested on     : UBI 8.3
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
# ----------------------------------------------------------------------------

PACKAGE_NAME=mimalloc
PACKAGE_VERSION=${1:-v1.7.3}
PACKAGE_URL=https://github.com/microsoft/mimalloc.git

yum install -y git cmake gcc-c++ libarchive.ppc64le

#Clone the Repo.
git clone $PACKAGE_URL
cd $PACKAGE_NAME/
git checkout $PACKAGE_VERSION

#Build and test the package.
mkdir -p out/release
cd out/release
cmake ../..
make
make install
make test
