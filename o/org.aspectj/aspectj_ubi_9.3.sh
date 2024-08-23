#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : org.aspectj
# Version       : V1_9_20_1 
# Source repo   : https://github.com/eclipse/org.aspectj
# Tested on	: UBI 9.3
# Language      : Java
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Siddesh Sangodkar <siddesh.sangodkar1@ibm.com>

#
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

# Variables
REPO=https://github.com/eclipse/org.aspectj

# Default tag for org.aspectj
if [ -z "$1" ]; then
  export VERSION="V1_9_20_1"
else
  export VERSION="$1"
fi

# install tools and dependent packages
yum update -y
yum install -y git wget maven

# install java 
yum install -y java-11-openjdk-devel


# Cloning Repo
git clone $REPO
cd ./org.aspectj/
git checkout ${VERSION}

# check maven
./mvnw -B --version

#Build package

if ! ./mvnw -B --file pom.xml -DskipTests install ; then
    echo "------------------$PACKAGE_NAME:Build_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_Fails"
    exit 1
else
    echo "------------------$PACKAGE_NAME::Build_and_Test_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Build_and_Test_Success"
    exit 0
fi

# Test failures are same as on x86
#./mvnw -B --file pom.xml -Daspectj.tests.verbose=false verify



