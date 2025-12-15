#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : promise
# Version          : v2.3.0
# Source repo      : https://github.com/syrusakbary/promise
# Tested on        : UBI:9.3
# Language         : Python
# Ci-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Vinod K <Vinod.K1@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# -----------------------------------------------------------------------------
PACKAGE_NAME=promise
PACKAGE_VERSION=${1:-v2.3.0}
PACKAGE_URL=https://github.com/syrusakbary/promise
PACKAGE_DIR=promise
CURRENT_DIR="${PWD}"

yum install -y git wget cmake python python-devel python-pip

echo "------------Cloning the Repository------------"

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

pip install build wheel setuptools

if ! pip install . ; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
    exit 1
fi
echo "------------Installing test dependencies------------"

if ! python3 -m pip install -e ".[test]"; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
    exit 2
fi

echo "------------Testing------------"

if ! (pytest --ignore=tests/test_awaitable.py -k "not test_thrown_exceptions_have_stacktrace and not test_thrown_exceptions_preserve_stacktrace"
);then
        echo "------------------$PACKAGE_NAME:Test_fails-------------------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Test_Fails"
        exit 2
fi

# Building wheel with script itself as the wheel need to create with ppc64le arch.
if ! python3 setup.py bdist_wheel --plat-name manylinux2014_ppc64le --dist-dir="$CURRENT_DIR"; then
    echo "------------------$PACKAGE_NAME: Wheel Build Failed ---------------------"
    exit 1
else
    echo "------------------$PACKAGE_NAME: Wheel Build Success -------------------------"
    exit 0
fi
