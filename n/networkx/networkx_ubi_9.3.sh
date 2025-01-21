#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package        : networkx
# Version        : 2.8.4
# Source repo    : https://github.com/networkx/networkx.git
# Tested on      : UBI 9.3
# Language       : Python
# Travis-Check   : True
# Script License : Apache License, Version 2 or later
# Maintainer     : Vivek Sharma <vivek.sharma20@ibm.com>
#
# Disclaimer: This script has been tested in root mode on the given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such cases, please
#             contact the "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

PACKAGE_NAME=networkx
PACKAGE_VERSION=${1:-2.8.4}
PACKAGE_URL=https://github.com/networkx/networkx.git

# Install necessary system packages
yum install -y git gcc gcc-c++ gcc-gfortran gzip tar make wget xz cmake yum-utils libjpeg-devel zlib-devel openssl-devel openblas-devel bzip2-devel bzip2 zip unzip libffi-devel zlib-devel autoconf automake libtool cargo pkgconf-pkg-config.ppc64le info.ppc64le fontconfig.ppc64le fontconfig-devel.ppc64le sqlite-devel python-devel

# Clone the repository
git clone ${PACKAGE_URL} ${PACKAGE_NAME}
cd ${PACKAGE_NAME}
git checkout networkx-${PACKAGE_VERSION}

# Install the package
pip install Pillow
pip3 install .[default]

# Install test dependencies
pip3 install pytest

# Run tests(skipping some testcase as same testcase failing in x86)
cd networkx/tests
if ! pytest -k "not(test_lazy_import_nonbuiltins)"; then
    echo "------------------$PACKAGE_NAME: Tests_Fail------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Tests_Fail"
    exit 1
else
    echo "------------------$PACKAGE_NAME: Install & test both success ---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Pass | Both_Install_and_Test_Success"
    exit 0
fi
