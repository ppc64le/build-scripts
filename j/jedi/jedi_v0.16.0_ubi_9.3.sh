#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package        : jedi
# Version        : v0.16.0
# Source repo    : https://github.com/davidhalter/jedi.git
# Tested on      : UBI 9.3
# Language       : Python
# Travis-Check   : True
# Script License : Apache License, Version 2 or later
# Maintainer     : Simran Sirsat <Simran.Sirsat@ibm.com>
#
# Disclaimer: This script has been tested in root mode on the given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such cases, please
#             contact the "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

PACKAGE_NAME=jedi
PACKAGE_VERSION=${1:-v0.16.0}
PACKAGE_URL=https://github.com/davidhalter/jedi.git

# Install necessary system packages
yum install -y git gcc gcc-c++ gzip tar make wget xz cmake yum-utils openssl-devel openblas-devel bzip2-devel bzip2 zip unzip libffi-devel zlib-devel autoconf automake libtool cargo pkgconf-pkg-config.ppc64le info.ppc64le fontconfig.ppc64le fontconfig-devel.ppc64le sqlite-devel python-devel

# Upgrade pip
pip3 install --upgrade pip

# Clone the repository
git clone ${PACKAGE_URL}
cd ${PACKAGE_NAME}
git checkout ${PACKAGE_VERSION}
git submodule update --init --recursive

# Install the package
pip3 install .

# Install test dependencies
pip3 install pytest tox chardet==4.0.0
if ! tox ; then
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
