#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : markdown
# Version       : 3.5.1
# Source repo   : https://github.com/Python-Markdown/markdown
# Tested on     : UBI: 8.7
# Language      : python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Abhishek Dwivedi <Abhishek.Dwivedi6@ibm.com>
#
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -e


# Variables
export PACKAGE_VERSION=${1:-"3.5.1"}
export PACKAGE_NAME=markdown
export PACKAGE_URL=https://github.com/Python-Markdown/markdown

# Install dependencies
yum install -y wget gcc git gcc-c++
yum install -y python38-devel.ppc64le
python3 -m pip install build tox coverage codecov

# Clone the repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

# Build package
if ! python3 -m build ; then
    echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_Fails"
    exit 1
fi

# Run test cases
if ! python3 -m tox -e py3 ; then
    echo "------------------$PACKAGE_NAME:build_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:build_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Build_and_Test_Success"
    exit 0
fi