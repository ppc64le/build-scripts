#!/bin/bash
# ----------------------------------------------------------------------------
#
# Package       : spring-boot-configuration-processor
# Version       : v3.3.3 
# Source repo   : https://github.com/spring-projects/spring-boot
# Tested on	: UBI 9.3
# Language      : Java
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Siddesh Sangodkar <siddesh.sangodkar1@ibm.com>

# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -e

PACKAGE_NAME=spring-boot-configuration-processor
PACKAGE_URL=https://github.com/spring-projects/spring-boot
PACKAGE_VERSION=${1:-3.3.3}

yum install wget maven java-17-openjdk java-17-openjdk-devel -y
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
export PATH=$JAVA_HOME/bin:$PATH

wget https://repo1.maven.org/maven2/org/springframework/boot/spring-boot-configuration-processor/$PACKAGE_VERSION/spring-boot-configuration-processor-$PACKAGE_VERSION-sources.jar 
jar -xvf spring-boot-configuration-processor-$PACKAGE_VERSION-sources.jar
wget https://repo1.maven.org/maven2/org/springframework/boot/spring-boot-configuration-processor/$PACKAGE_VERSION/spring-boot-configuration-processor-$PACKAGE_VERSION.pom
mv spring-boot-configuration-processor-$PACKAGE_VERSION.pom pom.xml

# Build and Test
if ! mvn clean install ; then
    echo "------------------$PACKAGE_NAME:Build_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
    exit 1
fi

if ! mvn test ; then
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
