#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	      : mongodb/mongo-java-driver
# Version	      : 3.9.0
# Source repo	  : https://github.com/mongodb/mongo-java-driver
# Tested on	      : Ubuntu 18.04 (Docker)
# Language        : Java
# Travis-Check    : True
# Script License  : Apache License, Version 2 or later
# Maintainer	  : Sumit Dubey <sumit.dubey2@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
# Steps to test script
# 1. docker pull docker.io/ppc64le/ubuntu:18.04
# 2. docker pull quay.io/opencloudio/ibm-mongodb@sha256:563f4b3e582c52b9ae47fac5783fcb8e92ed4285d17893e79a37a5fa2f84c58e
# 3. docker run -d -p 27017:27017 quay.io/opencloudio/ibm-mongodb@sha256:563f4b3e582c52b9ae47fac5783fcb8e92ed4285d17893e79a37a5fa2f84c58e --dbpath=/tmp --bind_ip_all 
# 4. docker run --network host -v /var/run/docker.sock:/var/run/docker.sock -it sumit_u docker.io/ppc64le/ubuntu:18.04
# Last step with give a prompt inside the container, run this script in it

PACKAGE_NAME=mongo-java-driver
PACKAGE_VERSION="${1:-r3.9.0}"
PACKAGE_URL=https://github.com/mongodb/mongo-java-driver.git

apt-get update -y
apt-get install git wget unzip openjdk-11-jdk python3 python3-dev -y

export WORK_DIR=`pwd`

wget https://services.gradle.org/distributions/gradle-4.10-bin.zip -P /tmp && unzip -d $WORK_DIR/gradle /tmp/gradle-4.10-bin.zip
export GRADLE_HOME=$WORK_DIR/gradle/gradle-4.10/
export PATH=${GRADLE_HOME}/bin:${PATH}

mkdir -p output
ln -s /usr/bin/python3 /bin/python

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

git clone $PACKAGE_URL
export HOME_DIR=$WORK_DIR/$PACKAGE_NAME
cd $HOME_DIR
git checkout $PACKAGE_VERSION

# build 
cd $WORK_DIR/$PACKAGE_NAME/driver-core
gradle build

# test package
cd $WORK_DIR/$PACKAGE_NAME/driver-core
gradle test

# The 1 test failure is because mmpapv1 storage engine is not supported by the ppc64le MongoDB image being used...
# [TEST FAILURE] should pass through storage engine options (18 ms)