#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package           : Dex
# Version           : v2.35.3
# Source repo       : https://github.com/dexidp/dex.git
# Tested on         : UBI: 8.5
# Language          : Go
# Travis-Check      : True
# Script License    : Apache License, Version 2 or later
# Maintainer        : Vishaka Desai <Vishaka.Desai@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=dex
PACKAGE_URL=https://github.com/dexidp/dex.git
PACKAGE_VERSION=${1:-v2.35.3}

yum install -y git make golang

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

make build

make test