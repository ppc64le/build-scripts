#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : cassandra-java-driver
# Version          : 4.18.1
# Source repo      : https://github.com/apache/cassandra-java-driver.git
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
PACKAGE_NAME=cassandra-java-driver
PACKAGE_VERSION=${1:-4.18.1}
PACKAGE_URL=https://github.com/apache/cassandra-java-driver.git

#install dependencies
yum install -y git wget java-1.8.0-openjdk-devel maven-openjdk8.noarch

# Clone the repository
git clone $PACKAGE_URL 
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
./install-snapshots.sh

#install
if ! mvn install -DskipTests=true -Dmaven.javadoc.skip=true -B -V ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

#test
if ! mvn test -Djacoco.skip=true -Dmaven.test.failure.ignore=true -Dmaven.javadoc.skip=true -B -V ; then
    echo "------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
