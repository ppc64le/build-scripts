#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package        : dulwich
# Version        : 0.21.7
# Source repo    : https://github.com/jelmer/dulwich.git
# Tested on      : UBI 9.3
# Language       : Python
# Travis-Check   : True
# Script License : Apache License, Version 2 or later
# Maintainer     : Soham Badjate <soham.badjate@ibm.com>
#
# Disclaimer: This script has been tested in root mode on the given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such cases, please
#             contact the "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

PACKAGE_NAME=dulwich
PACKAGE_DIR=dulwich
PACKAGE_VERSION=${1:-0.21.7}
PACKAGE_URL=https://github.com/jelmer/dulwich.git

# Install necessary system packages
yum install git python3 python3-devel python3-pip make cmake gcc -y

# Upgrade pip and install build dependencies
pip3 install --upgrade pip setuptools wheel setuptools_rust

# cd to installation directory
cd /root

# Clone the repository
git clone ${PACKAGE_URL}
cd ${PACKAGE_DIR}
git checkout dulwich-${PACKAGE_VERSION}

# Install build requirements
pip install geventhttpclient==2.2.0 merge3

#Build and install the package
if ! pip3 install . ; then
    echo "------------------$PACKAGE_NAME: Build_Fail------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Build_Failure"
    exit 1
fi

# Run tests
if ! python -m pytest dulwich -k "not test_file_win and not test_swift_smoke" --import-mode=append; then
    echo "------------------$PACKAGE_NAME: Tests_Fail------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Tests_Fail"
    exit 2

else
    echo "------------------$PACKAGE_NAME: Install & test both success ---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Pass | Both_Install_and_Test_Success"
    exit 0
fi
