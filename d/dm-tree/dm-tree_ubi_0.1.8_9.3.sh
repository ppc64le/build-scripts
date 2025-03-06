#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : dm-tree
# Version          : 0.1.8
# Source repo      : https://github.com/deepmind/tree
# Tested on	: UBI:9.3
# Language      : Python
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

PACKAGE_NAME=dm-tree
PACKAGE_VERSION=${1:-0.1.8}
PACKAGE_URL=https://github.com/deepmind/tree
PACKAGE_DIR="tree/"

yum install -y gcc gcc-c++ make libtool cmake git wget xz zlib-devel openssl-devel bzip2-devel libffi-devel libevent-devel libjpeg-turbo-devel python python-devel

git clone $PACKAGE_URL
cd $PACKAGE_DIR
git checkout $PACKAGE_VERSION

# install scikit-learn dependencies and build dependencies
pip install pytest absl-py attr numpy wrapt

if ! (python setup.py install) ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
else
    echo "------------------$PACKAGE_NAME:Install_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Install_Success"
    exit 0
fi

#skipping tests as they are parity with intel for 0.1.8 version on x86_64 also