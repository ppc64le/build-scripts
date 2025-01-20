#!/bin/bash
# ----------------------------------------------------------------------------
#
# Package       : asm
# Version       : ASM_9_7
# Source repo   : https://gitlab.ow2.org/asm/asm
# Tested on     : UBI 9.3
# Language      : Java
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Siddesh Sangodkar <siddesh.sangodkar1@ibm.com>
#
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------


set -e

#Variables
REPO=https://gitlab.ow2.org/asm/asm

# Default tag for asm
if [ -z "$1" ]; then
  export VERSION="ASM_9_7"
else
  export VERSION="$1"
fi

# install tools and dependent packages
yum update -y
yum install -y git wget unzip 

# install java
yum install -y java-11-openjdk-devel

#Cloning Repo
git clone $REPO
cd asm
git checkout ${VERSION}

#Build and test package
if ! ./gradle/gradlew build ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi 

if ! ./gradle/gradlew test jacocoTestCoverageVerification ; then
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
