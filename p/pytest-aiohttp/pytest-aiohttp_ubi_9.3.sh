#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : pytest-aiohttp
# Version       : v1.0.5
# Source repo   : https://github.com/aio-libs/pytest-aiohttp
# Tested on     : UBI:9.3
# Language      : Python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Anumala Rajesh <Anumala.Rajesh@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -ex 

PACKAGE_NAME=pytest-aiohttp
PACKAGE_VERSION=${1:-v1.0.5}
PACKAGE_URL=https://github.com/aio-libs/pytest-aiohttp

yum install -y git make wget sudo gcc-toolset-13 openssl-devel bzip2-devel wget
yum install -y python3.12 python3.12-devel python3.12-pip xz zlib-devel libffi-devel 

export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH

python3.12 -m pip install pytest tox aiohttp pytest-asyncio

# Clone the repository
git clone $PACKAGE_URL $PACKAGE_NAME
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

if ! python3.12 -m pip install .; then
    echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_Fails"
    exit 1
fi 

# Skipping tests due to missing event_loop fixture causing compatibility issues with pytest-asyncio.
# This issue occurs on both ppc64le and x86_64 architectures.
