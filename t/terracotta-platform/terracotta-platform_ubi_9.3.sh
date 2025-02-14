#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : terracotta-platform
# Version          : v5.10.22
# Source repo      : https://github.com/Terracotta-OSS/terracotta-platform.git
# Tested on        : UBI:9.3
# Language         : Java
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Vipul Ajmera <Vipul.Ajmera@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------------

#variables
PACKAGE_NAME=terracotta-platform
PACKAGE_URL=https://github.com/Terracotta-OSS/terracotta-platform.git
PACKAGE_VERSION=${1:-v5.10.22}

#dependencies
yum install -y git wget java-1.8.0-openjdk java-1.8.0-openjdk-devel hostname

#copying toolchains.xml file to .m2 folder needed to build and test
wget https://raw.githubusercontent.com/ppc64le/build-scripts/master/t/terracotta-platform/toolchains.xml
mkdir ~/.m2
cp toolchains.xml ~/.m2/

#clone repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#build
if ! ./mvnw clean install -DskipTests -Dfast -Djava.build.vendor=openjdk ; then
    echo "------------------$PACKAGE_NAME:Build_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_Fails"
    exit 1
fi

#test
if ! ./mvnw verify -DskipITs -Dfast -Djava.test.vendor=openjdk; then
    echo "------------------$PACKAGE_NAME:Build_success_and_Test_fails-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Fail |  Build_Success_and_Test_fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Build_and_Test_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Build_and_Test_Success"
    exit 0
fi
