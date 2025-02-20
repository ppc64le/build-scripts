#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : brunsli
# Version          : v0.1
# Source repo      : https://github.com/google/brunsli.git
# Tested on        : UBI:9.3
# Language         : Python
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Ramnath Nayak <Ramnath.Nayak@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------------

PACKAGE_NAME=brunsli
PACKAGE_VERSION=${1:-v0.1}
PACKAGE_URL=https://github.com/google/brunsli.git
PACKAGE_DIR=brunsli

# Install dependencies
yum install -y git gcc gcc-c++ make cmake wget sudo openssl-devel bzip2-devel libffi-devel zlib-devel python-devel python-pip

# Clone the repository
git clone $PACKAGE_URL
cp pyproject.toml brunsli
cd $PACKAGE_DIR
git checkout $PACKAGE_VERSION

git submodule update --init --recursive
cmake ./
make -j
make -j install

pip install wheel setuptools

#Install
if !(python3 -m pip install .); then
    echo "------------------$PACKAGE_NAME:Install_success---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Pass |  Install_Success"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Fail |  Install_Fails"
    exit 0
fi

# No tests are included in this package.
