#!/bin/bash
# -----------------------------------------------------------------------------
#
# Package       : json-path
# Version       : json-path-2.9.0
# Source repo   : https://github.com/json-path/JsonPath
# Tested on     : UBI 9.3
# Language      : Java
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Pratibh Goshi<pratibh.goshi@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ========== platform using the mentioned version of the package.
# It may not work as expected with newer versions of the
# package and/or distribution. In such case, please
# contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
set -e

PACKAGE_NAME=JsonPath
PACKAGE_VERSION=${1:-json-path-2.9.0}
PACKAGE_URL=https://github.com/json-path/JsonPath

# install tools and dependent packages
yum install -y git wget

# setup java environment
yum install -y java java-devel unzip

export JAVA_HOME=/usr/lib/jvm/$(ls /usr/lib/jvm/ | grep -P '^(?=.*java-)(?=.*ppc64le)') 
# update the path env. variable
export PATH=$PATH:$JAVA_HOME/bin


#install gradle
wget https://services.gradle.org/distributions/gradle-7.2-rc-1-bin.zip -P /tmp && unzip -d /gradle /tmp/gradle-7.2-rc-1-bin.zip
export GRADLE_HOME=/gradle/gradle-7.2-rc-1/

# update the path env. variable
export PATH=${GRADLE_HOME}/bin:${PATH}


# clone and checkout specified version
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#Build
if ! ./gradlew build --warning-mode all; then
    echo "------------------$PACKAGE_NAME:Build_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_Fails"
    exit 1
fi

#Test
if ! ./gradlew check; then
    echo "------------------$PACKAGE_NAME::Build_and_Test_fails-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Fail|  Build_and_Test_fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME::Build_and_Test_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Build_and_Test_Success"
    exit 0
fi

