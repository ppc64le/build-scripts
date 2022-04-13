#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package		: mongodb-driver-sync
# Version		: 4.1.2, 4.2.2
# Source repo	: https://github.com/mongodb/mongo-java-driver.git
# Tested on     : ubuntu_18.04 (Docker)
# Language      : Java
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Manik Fulpagar <Manik_Fulpagar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------------------------------
# Prerequisites:
# MongoDB running and accesible on port 27017
# Java version 11 or later must be installed.
# ----------------------------------------------------------------------------
# Steps to test script
# 1. Pull  mongodb 4.0.24 image from quay.io and create container 
# 2. docker pull <MongoDB(version 4.0.24) ppc64le Image>
# The mongoDB docker container needs to be started with the following command:
# 3. docker run -d -p 27017:27017 <MongoDB(version 4.0.24) ppc64le Image> --dbpath=/tmp --setParameter enableTestCommands=1 --nojournal
# the mongo-java-driver test container run with following command.
# 4. docker run --network host -v /var/run/docker.sock:/var/run/docker.sock -it --name driver-sync-testcontainer docker.io/ppc64le/ubuntu:18.04
# Last step with give a prompt inside the container, run this script in it

set -ex

#Variables
PACKAGE_NAME=mongo-java-driver
PACKAGE_URL=https://github.com/mongodb/mongo-java-driver.git
PACKAGE_VERSION=4.1.2

echo "Usage: $0 [-v <PACKAGE_VERSION>]"
echo "PACKAGE_VERSION is an optional paramater whose default value is 4.1.2, not all versions are supported."
PACKAGE_VERSION="${1:-$PACKAGE_VERSION}"

# install dependencies
apt update && apt install git wget unzip openjdk-11-jdk -y

# install gradle
export WORK_DIR=`pwd`
export HOME=$WORK_DIR

wget https://services.gradle.org/distributions/gradle-6.0.1-all.zip -P /tmp && unzip -d $WORK_DIR/gradle /tmp/gradle-6.0.1-all.zip
export GRADLE_HOME=$WORK_DIR/gradle/gradle-6.0.1/
export PATH=${GRADLE_HOME}/bin:${PATH}

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

# clone repo
if ! git clone $PACKAGE_URL; then
	echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails" > $WORK_DIR/output/version_tracker
	exit 0
fi

export HOME_DIR=$WORK_DIR/$PACKAGE_NAME

cd $HOME_DIR
git checkout r$PACKAGE_VERSION

# to build
cd $WORK_DIR/$PACKAGE_NAME/driver-sync

if ! gradle build; then
	exit 0
fi

# to test
cd $WORK_DIR/$PACKAGE_NAME/driver-sync
if ! gradle test; then
	echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails" 
	exit 0
else
	echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success" 
	exit 0
fi
