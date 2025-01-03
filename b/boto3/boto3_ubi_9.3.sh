#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package        : boto3
# Version        : 1.24.28
# Source repo    : https://github.com/boto/boto3.git
# Tested on      : UBI 9.3
# Language       : Python
# Travis-Check   : True
# Script License : Apache License, Version 2 or later
# Maintainer     : vivek sharma <vivek.sharma20@ibm.com>
#
# Disclaimer: This script has been tested in root mode on the given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such cases, please
#             contact the "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=boto3
PACKAGE_VERSION=${1:-1.24.28}
PACKAGE_URL=https://github.com/boto/boto3.git

# Install necessary system packages
yum install -y git gcc gcc-c++ gzip tar make wget xz cmake yum-utils openssl-devel openblas-devel bzip2-devel bzip2 zip unzip libffi-devel zlib-devel autoconf automake libtool cargo pkgconf-pkg-config.ppc64le info.ppc64le fontconfig.ppc64le fontconfig-devel.ppc64le sqlite-devel python-devel

# Clone the repository
git clone ${PACKAGE_URL} ${PACKAGE_NAME}
cd ${PACKAGE_NAME}
git checkout ${PACKAGE_VERSION}

# Install pytest and other dependencies
pip install pytest botocore s3transfer
pip install .

# Install the package
if ! python3 setup.py install ; then
    echo "------------------$PACKAGE_NAME: Install fails -------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Install_Fails"
    exit 1
fi

# Run tests using pytest
if command -v pytest &> /dev/null; then
    if ! pytest tests/unit; then
        echo "------------------${PACKAGE_NAME}: Tests_Fail------------------"
        echo "${PACKAGE_URL} ${PACKAGE_NAME}"
        echo "${PACKAGE_NAME} | ${PACKAGE_URL} | ${PACKAGE_VERSION} | GitHub | Fail | Tests_Fail"
        exit 1
    fi
else
    echo "------------------$PACKAGE_NAME: Install & test both success ---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Pass | Both_Install_and_Test_Success"
    exit 0
fi

