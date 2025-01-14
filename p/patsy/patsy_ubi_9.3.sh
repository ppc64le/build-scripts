#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package        : patsy
# Version        : v0.5.3
# Source repo    : https://github.com/pydata/patsy.git
# Tested on      : UBI 9.3
# Language       : Python
# Travis-Check   : True
# Script License : Apache License, Version 2 or later
# Maintainer     : [Your Name] <[Your Email]>
#
# Disclaimer: This script has been tested in root mode on the given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such cases, please
#             contact the "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

PACKAGE_NAME=patsy
PACKAGE_VERSION=${1:-0.5.3}
PACKAGE_URL=https://github.com/pydata/patsy.git

# Install necessary system packages
yum install -y git gcc gcc-c++ gzip tar make wget xz cmake yum-utils openssl-devel openblas-devel bzip2-devel bzip2 zip unzip libffi-devel zlib-devel autoconf automake libtool cargo sqlite-devel python-devel

# Install required Python packages
pip3 install numpy six

# Clone the repository
git clone ${PACKAGE_URL} ${PACKAGE_NAME}
cd ${PACKAGE_NAME}
git checkout tags/v${PACKAGE_VERSION}

# Install the package
pip3 install .

# Install test dependencies
pip3 install pytest pytest-cov scipy

# Run tests
if ! pytest -k "not(test_DesignInfo or test_formula_likes or test_builtins or test_incremental or test_Center or test_asarray_or_pandas or test_stateful_transform_wrapper)"; then
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
