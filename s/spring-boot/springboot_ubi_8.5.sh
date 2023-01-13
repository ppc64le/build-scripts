#!/bin/bash
# ----------------------------------------------------------------------------
#
# Package       : spring-boot
# Version       : 3.0.1
# Source repo   : https://github.com/spring-projects/spring-boot
# Tested on     : ubi8.5
# Language      : Java
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Chandranana Naik <Chandranana.Naik@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

VERSION=${1:-v3.0.1}

#Install dependencies
yum update -y
yum install git -y
yum install java-17-openjdk-devel.ppc64le -y

#export variables
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-17.0.5.0.8-2.el8_6.ppc64le

#Build Spring boot
git clone https://github.com/spring-projects/spring-boot
cd spring-boot
git checkout $VERSION
./gradlew build
