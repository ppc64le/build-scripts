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

#Install dependencies
pip3 install Django==5.1.4 asgiref==3.8.1 attrs==24.3.0 colorama==0.4.6 docopt==0.6.2 iniconfig==2.0.0 packaging==24.2 parso==0.8.4 pluggy==1.5.0 pytest==8.3.4 sqlparse==0.5.3 jedi==0.16.0

# Install test dependencies
pip3 install pytest tox==4.23.2

if ! tox -e py39 ; then
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
