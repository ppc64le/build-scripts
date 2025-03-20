#!/bin/bash -e
# ----------------------------------------------------------------------------
# Package       : kafka
# Version       : v3.7.0
# Source repo   : https://github.com/apache/kafka
# Tested on     : UBI 9.3
# Language      : Java
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Apoorva Sahu <Apoorva.Sahu@ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------


#Variables
PACKAGE_NAME=kafka
PACKAGE_VERSION=${1:-'3.7.0'}
PACKAGE_URL=https://github.com/apache/kafka

dnf install -y git make gcc gcc-c++ java-11-openjdk-devel.ppc64le libtool file diffutils wget
export JAVA_HOME=/usr/lib/jvm/$(ls /usr/lib/jvm/ | grep -P '^(?=.*java-11)(?=.*ppc64le)')
export PATH=$JAVA_HOME/bin:$PATH

#Build and run unit tests
cd $HOME
git clone https://github.com/apache/kafka
cd kafka
git checkout $PACKAGE_VERSION

#Build package
echo "---------------------Building the package------------------------------------------"
if ! (./gradlew jar) ; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

#Test package
echo "---------------------Testing the package------------------------------------------"
if ! (./gradlew unitTest integrationTest --continue -PtestLoggingEvents=started,passed,skipped,failed -PignoreFailures=true -PmaxParallelForks=2) ; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi

