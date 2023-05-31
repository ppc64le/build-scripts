#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : calcite-avatica
# Version          : rel/avatica-1.23.0
# Source repo      : https://github.com/apache/calcite-avatica
# Tested on        : UBI 8.7
# Language         : Java
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Shubham Garud <Shubham.Garud@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=calcite-avatica
PACKAGE_VERSION=${1:-rel/avatica-1.23.0}
PACKAGE_URL=https://github.com/apache/calcite-avatica

# Install dependencies
yum install -y wget git java-11-openjdk java-11-openjdk-devel

export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-11.0.19.0.7-4.el8.ppc64le
export PATH=/usr/lib/jvm/java-11-openjdk-11.0.19.0.7-4.el8.ppc64le/bin/:$PATH


git clone $PACKAGE_URL
cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION

if ! ./gradlew build; then
    echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  build_Fails"
    exit 1
fi

if ! ./gradlew --no-parallel --no-daemon build javadoc; then
    echo "------------------$PACKAGE_NAME:build_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  build__success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:build_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Build_and_Test_Success"
    exit 0
fi
