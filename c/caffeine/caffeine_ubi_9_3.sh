#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : caffeine
# Version          : v3.1.8
# Source repo      : https://github.com/ben-manes/caffeine.git
# Tested on        : UBI:9.3
# Language         : Java
# Ci-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Stuti Wali <Stuti.Wali@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------------

#variables
PACKAGE_NAME=caffeine
PACKAGE_URL=https://github.com/ben-manes/caffeine.git
PACKAGE_VERSION=${1:-v3.1.8}
export LC_ALL=C.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8

#dependencies
yum install -y git wget java-11-openjdk-devel.ppc64le
export JAVA_HOME=/usr/lib/jvm/$(ls /usr/lib/jvm/ | grep -P '^(?=.*java-11)(?=.*ppc64le)')
export PATH=$JAVA_HOME/bin:$PATH
java -version

#clone repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#build
if ! ./gradlew build -x test; then
    echo "------------------$PACKAGE_NAME:Build_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_Fails"
    exit 1
fi

#test
if ! ./gradlew caffeine:junitTest; then
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
