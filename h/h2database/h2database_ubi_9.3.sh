#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : h2database
# Version          : version-2.3.232
# Source repo      : https://github.com/h2database/h2database.git
# Tested on        : UBI:9.3
# Language         : Java
# Ci-Check     : True
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
PACKAGE_NAME=h2database
PACKAGE_VERSION=${1:-version-2.3.232}
PACKAGE_URL=https://github.com/h2database/h2database.git

export JAVA_OPTS=-Xmx512m

#install dependencies
yum install -y git wget maven

export JAVA_HOME=/usr/lib/jvm/java-11-openjdk
export PATH=$PATH:$JAVA_HOME/bin

#clone repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
cd h2

#build
if ! ./build.sh jar; then
    echo "------------------$PACKAGE_NAME:Build_fails-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Fail |  Build_fails"
    exit 1
else
    echo "------------------$PACKAGE_NAME:Build_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Build_Success"
    exit 0
fi

#Skipping the test-cases because they don't use pom.xml and can also test using ./build.sh testCI but is also parity with x_86
