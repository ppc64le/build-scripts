#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: grails-xss-sanitizer
# Version	: master
# Source repo	: https://github.com/rpalcolea/grails-xss-sanitizer
# Tested on	: UBI: 8.5
# Language      : Java
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Sunidhi Gaonkar<Sunidhi.Gaonkar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=grails-xss-sanitizer
PACKAGE_VERSION=${1:-master}
PACKAGE_URL=https://github.com/rpalcolea/grails-xss-sanitizer

# install tools and dependent packages
yum update -y
yum install -y git


# install java
yum -y install java-1.8.0-openjdk-devel

# Cloning the repository from remote to local
cd /home
git clone $PACKAGE_URL 
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION


# Build and validate
./gradlew check
./gradlew build -Dscan

# No test cases are available.