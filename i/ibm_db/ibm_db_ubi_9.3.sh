#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package        : ibm_db
# Version        : v3.2.3
# Source repo    : https://github.com/ibmdb/python-ibmdb.git
# Tested on      : UBI 9.3
# Language       : Python
# Ci-Check   : True
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

PACKAGE_NAME=ibm_db
PACKAGE_VERSION=${1:-v3.2.3}
PACKAGE_DIR=python-ibmdb
PACKAGE_URL=https://github.com/ibmdb/python-ibmdb.git
CURRENT_DIR="${PWD}"

# Install necessary system packages
yum install -y git python-devel gcc gcc-c++ libxcrypt gzip tar make wget xz cmake yum-utils openssl-devel openblas-devel bzip2-devel bzip2 zip unzip libffi-devel zlib-devel autoconf automake libtool cargo pkgconf-pkg-config.ppc64le info.ppc64le fontconfig.ppc64le fontconfig-devel.ppc64le sqlite-devel

yum install -y numactl-libs libxcrypt-compat

# Clone the repository
git clone $PACKAGE_URL
cd $PACKAGE_DIR
git checkout $PACKAGE_VERSION

# Install test dependencies
pip install pytest config tox

export LD_LIBRARY_PATH=${CURRENT_DIR}/python-ibmdb/clidriver/lib/:$LD_LIBRARY_PATH

# Install the package
if ! python3 -m pip install .; then
    echo "------------------$PACKAGE_NAME: Installation failed ---------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Installation_Failure"
    exit 1
fi

# Run tests
if ! python3 -m tox -e py3; then
    echo "------------------$PACKAGE_NAME: Tests failed ------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Tests_Failure"
    exit 2
else
    echo "------------------$PACKAGE_NAME: Install & test both successful ---------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Pass | Both_Install_and_Test_Success"
    exit 0
fi
