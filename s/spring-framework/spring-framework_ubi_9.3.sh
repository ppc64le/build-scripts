#!/bin/bash
# -----------------------------------------------------------------------------
#
# Package       : spring-framework
# Version       : v6.0.19
# Source repo   : https://github.com/spring-projects/spring-framework.git
# Tested on     : UBI 9.3
# Language      : Java, Others
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Pratibh Goshi<pratibh.goshi@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
set -e

PACKAGE_NAME=spring-framework
PACKAGE_VERSION=${1:-v6.0.19}
PACKAGE_URL=https://github.com/spring-projects/spring-framework.git

# install tools and dependent packages
yum install -y git wget unzip

# setup java environment
yum install -y java-17-openjdk java-17-openjdk-devel
export JAVA_HOME=/usr/lib/jvm/$(ls /usr/lib/jvm/ | grep -P '^(?=.*java-)(?=.*ppc64le)') 
# update the path env. variable
export PATH=$PATH:$JAVA_HOME/bin

# clone and checkout specified version
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#Build
./gradlew build -x test   >> /tmp/BUILD.log 2>&1 

if ! tail -c 1000 /tmp/BUILD.log | grep 'BUILD SUCCESSFUL' ; then
    echo "------------------$PACKAGE_NAME:Build_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
    exit 1
fi

#test
# ./gradlew test >> /tmp/TEST.log 2>&1 


# if !  tail -c 1000 /tmp/TEST.log | grep 'BUILD SUCCESSFUL' ; then
#     echo "------------------$PACKAGE_NAME::Build_and_Test_fails-------------------------"
#     echo "$PACKAGE_URL $PACKAGE_NAME"
#     echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Fail|  Build_and_Test_fails"
#     exit 2
# else
#     echo "------------------$PACKAGE_NAME::Build_and_Test_success-------------------------"
#     echo "$PACKAGE_URL $PACKAGE_NAME"
#     echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Build_and_Test_Success"
#     exit 0
# fi
