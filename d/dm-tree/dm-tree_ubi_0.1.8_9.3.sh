#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : dm-tree
# Version          : 0.1.8
# Source repo      : https://github.com/deepmind/tree
# Tested on	   : UBI:9.3
# Language         : Python
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Ramnath Nayak <Ramnath.Nayak@ibm.com>
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
PYTHON_VERSION="3.12"

yum install -y gcc-toolset-13 make libtool cmake git wget xz zlib-devel openssl-devel bzip2-devel libffi-devel libevent-devel libjpeg-turbo-devel python python-devel

export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export SITE_PACKAGE_PATH="/lib/python${PYTHON_VERSION}/site-packages"

git clone $PACKAGE_URL
cd $PACKAGE_DIR
git checkout $PACKAGE_VERSION

pip install --upgrade pip setuptools wheel

# install scikit-learn dependencies and build dependencies
pip install pytest absl-py attr numpy wrapt attrs

#Download and apply the patch file
wget https://raw.githubusercontent.com/ramnathnayak-ibm/build-scripts/refs/heads/dm-tree/d/dm-tree/update_abseil_version_and_linking_fix.patch
git apply update_abseil_version_and_linking_fix.patch

#Build
if ! (python3 setup.py build_ext --inplace) ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# Run test cases
if !(pytest); then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
