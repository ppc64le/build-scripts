#!/bin/bash
# ----------------------------------------------------------------------------
#
# Package       : spring-retry
# Version       : v2.0.10
# Source repo   : https://github.com/spring-projects/spring-retry
# Tested on     : UBI 9.3
# Language      : Java
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Siddesh Sangodkar <siddesh.sangodkar1@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------------------------------

PACKAGE_NAME=spring-retry
PACKAGE_VERSION=${1:-v2.0.10}
PACKAGE_URL=https://github.com/spring-projects/spring-retry.git

yum install -y gcc cmake git wget gcc-c++ yum-utils make automake autoconf libtool gdb* binutils rpm-build gettext wget --skip-broken
yum install -y device-mapper-persistent-data diffutils
yum install -y python3 python3-setuptools python3-devel libevent-devel

#install java-17
yum install -y java-17-openjdk java-17-openjdk-devel 
export LD_LIBRARY_PATH=/usr/local/lib
export JAVA_HOME=export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
export PATH=$JAVA_HOME/bin:$PATH
java -version


#clone package
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

if ! ./mvnw -f pom.xml clean install -Djava.version=17 ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi 

if ! ./mvnw test ; then
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
