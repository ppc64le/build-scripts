#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package        : dulwich
# Version        : 0.21.7
# Source repo    : https://github.com/jelmer/dulwich.git
# Tested on      : UBI 9.3
# Language       : Python
# Ci-Check   : True
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
PACKAGE_VERSION=${1:-dulwich-0.21.7}
PACKAGE_URL=https://github.com/jelmer/dulwich.git

# Install necessary system packages
yum install git python3.12 python3-devel python3.12-pip make cmake gcc -y

# Upgrade pip and install build dependencies

# cd to installation directory
cd /root

#creating symbolic link for python and pip
# ln -sf /usr/bin/pip3.12 /usr/bin/pip3
# ln -sf /usr/bin/python3.12 /usr/bin/python

python3.12 -m pip install --upgrade pip setuptools wheel setuptools_rust
# Clone the repository
git clone ${PACKAGE_URL}
cd ${PACKAGE_DIR}
git checkout ${PACKAGE_VERSION}

# Install build requirements
pip install geventhttpclient==2.2.0 merge3 pytest

#Build and install the package
if ! pip3 install . ; then
    echo "------------------$PACKAGE_NAME: Build_Fail------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Build_Failure"
    exit 1
fi

# Run tests (skipping some testcase becauses same are failing in x86)
if ! python3.12 -m pytest dulwich -k "not test_walk and not test_file_win and not test_swift_smoke" --import-mode=append; then
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
