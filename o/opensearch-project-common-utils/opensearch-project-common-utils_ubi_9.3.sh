#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : common-utils
# Version          : 2.13.0.0
# Source repo      : https://github.com/opensearch-project/common-utils
# Tested on        : UBI 9.3
# Language         : Java
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Pankhudi Jain<pnkhudi.17@gmail.com>
#
# Disclaimer       : This script has been tested in non-root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------------

sudo yum install -y git wget java-11-openjdk-devel 

PACKAGE_NAME=common-utils
PACKAGE_VERSION=${1:-2.13.0.0}
PACKAGE_URL=https://github.com/opensearch-project/common-utils

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

if ! ./gradlew clean build -x test; then
    echo "---------------$PACKAGE_NAME:Build_fails------------------"
    echo "$PACKAGE_VERSION $PACKAGE_NAME"
    echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
    exit 1

elif ! ./gradlew test; then
    echo "------------------$PACKAGE_NAME:Build_and _test_fails---------------------"
    echo "$PACKAGE_VERSION $PACKAGE_NAME"
    echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
    exit 2
else
    echo "Build and Test Success"
    exit 0
fi
