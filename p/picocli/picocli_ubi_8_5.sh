#!/bin/bash -ex
# ----------------------------------------------------------------------------
#
# Package       : picocli
# Version       : 4.0.4 / 4.6.1 
# Source repo   : https://github.com/remkop/picocli
# Tested on		: UBI 8.5
# Language      : Java
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Saurabh Gore <Saurabh.Gore@ibm.com> 
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=picocli
PACKAGE_VERSION="${1:-v4.0.4}"
PACKAGE_URL=https://github.com/remkop/picocli.git

# Install required dependencies
yum install -y git  java-1.8.0-openjdk-devel

rm -rf $PACKAGE_NAME

#Clonning repo
git config --global core.longpaths true
git clone -b $PACKAGE_VERSION $PACKAGE_URL
cd $PACKAGE_NAME/


export JAVA_TOOL_OPTIONS="-Dfile.encoding=UTF8"

#Build and test package
./gradlew build
