#!/bin/bash
# -----------------------------------------------------------------------------
#
# Package           : ansible-navigator
# Version           : v25.5.0
# Source repo       : https://github.com/ansible/ansible-navigator.git
# Tested on         : UBI:9.3
# Language          : Python
# Travis-Check      : True
# Script License    : Apache License, Version 2 or later
# Maintainer        : Bharti Somra(Bharti.Somra@ibm.com)
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
# ----------------------------------------------------------------------------
#

PACKAGE_NAME=ansible-navigator
PACKAGE_URL=https://github.com/ansible/ansible-navigator.git
PACKAGE_VERSION=${1:-v25.5.0}

dnf update -y && dnf upgrade -y

dnf install -y git python3.11 python3.11-pip gcc gcc-c++ make python3.11-devel rust cargo libffi-devel openssl-devel automake autoconf libtool

git clone https://github.com/kkos/oniguruma.git
cd oniguruma
./autogen.sh
./configure
make
make install

cd ..

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#To create virtual environment
python3.11 -m venv .venv
source .venv/bin/activate

pip install --upgrade pip setuptools build tox
export LD_LIBRARY_PATH=$(find / -name 'libonig.so.5*' 2>/dev/null | grep '/usr/local/lib' | head -n 1 | xargs dirname):$LD_LIBRARY_PATH

if ! python3 -m build ; then
    echo "------------------$PACKAGE_NAME:Build_Failure---------------------"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_Failure"
    exit 1
fi

#Installing test dependencies
pip install -e .[test]

#To run whole tests
#tox -e py311
#Dependency image - ghcr.io/ansible/community-ansible-dev-tools:latest

#Test: Code quality checks, Build package, verify metadata, install package and Bump all test dependencies
if ! (tox -e lint && tox -e packaging && tox -e deps) ; then
    echo "------------------$PACKAGE_NAME:Test_Failure---------------------"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Test_Failure"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Build & Test Passed Successfully---------------------"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Pass |  Build_&_Test_Successfull"
    exit 0
fi
