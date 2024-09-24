#!/bin/bash
# ----------------------------------------------------------------------------
#
# Package			: java-annotations
# Version			: 24.1.0
# Source repo		: https://github.com/JetBrains/java-annotations
# Tested on     : UBI 9.3
# Language      : Java
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Siddesh Sangodkar <siddesh.sangodkar1@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------


set -e
# install tools and dependent packages
#yum -y update
yum install -y git wget 
yum install -y gcc-c++ jq cmake ncurses unzip make  gcc-gfortran

CUR_DIR=$('pwd')

wget https://github.com/adoptium/temurin8-binaries/releases/download/jdk8u302-b08/OpenJDK8U-jdk_ppc64le_linux_hotspot_8u302b08.tar.gz;
tar xf OpenJDK8U-jdk_ppc64le_linux_hotspot_8u302b08.tar.gz;

wget https://github.com/adoptium/temurin11-binaries/releases/download/jdk-11.0.24%2B8/OpenJDK11U-jdk_ppc64le_linux_hotspot_11.0.24_8.tar.gz;
tar xf OpenJDK11U-jdk_ppc64le_linux_hotspot_11.0.24_8.tar.gz;

wget https://github.com/AdoptOpenJDK/openjdk9-binaries/releases/download/jdk-9.0.4%2B11/OpenJDK9U-jdk_ppc64le_linux_hotspot_9.0.4_11.tar.gz;
tar xf OpenJDK9U-jdk_ppc64le_linux_hotspot_9.0.4_11.tar.gz;

# setup java environment
export JAVA_HOME=$CUR_DIR/jdk-11.0.24+8;
export JDK_9=$CUR_DIR/jdk-9.0.4+11;
export JDK_5=$CUR_DIR//jdk8u302-b08

# update the path env. variable 
export PATH="$JAVA_HOME/bin/":$PATH

# variables
PACKAGE_NAME=java-annotations
PACKAGE_URL=https://github.com/JetBrains/java-annotations
PACKAGE_VERSION=${1:-24.1.0}

# clone, build and test specified version
java -version


#clone package
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

if ! ./gradlew build ; then
    echo "------------------$PACKAGE_NAME:Build_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
    exit 1
fi

if ! ./gradlew test ; then
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
