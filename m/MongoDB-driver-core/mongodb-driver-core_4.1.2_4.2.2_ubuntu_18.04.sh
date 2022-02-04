#!/bin/bash -e
# ----------------------------------------------------------------------------------------------------
#
# Package       : MongoDB-driver-core
# Version       : 4.1.2, 4.2.2
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
# MongoDB running on port 27017
# Java version 11 or later must be installed.
# ----------------------------------------------------------------------------
# Steps to test script
# 1.  Pull following mongodb image from quay.io and create container 
# quay.io/opencloudio/ibm-mongodb@sha256:19eb7cca57c1876cf4e93a0b0a4814a7f4001e1026527f901e59e538c7b2945e
# 2. docker pull <MongoDB(version 4.2.6) ppc64le Image>
# 3. docker run -d -p 27017:27017  <MongoDB(version 4.2.6) ppc64le Image> --dbpath=/tmp --bind_ip_all 
# 4. docker run --network host -v /var/run/docker.sock:/var/run/docker.sock -it --name driver-core-testcontainer docker.io/ppc64le/ubuntu:18.04
# Last step with give a prompt inside the container, run this script in it

set -ex

# variables
PACKAGE_NAME="mongo-java-driver"
PACKAGE_VERSION=r4.2.2
PACKAGE_VERSION_LATEST=r4.3.1
PACKAGE_URL="https://github.com/mongodb/mongo-java-driver.git"

#Extract version from command line
echo "Usage: $0 [r<PACKAGE_VERSION>]"
echo "       PACKAGE_VERSION is an optional paramater whose default value is r4.2.2"
PACKAGE_VERSION="${1:-$PACKAGE_VERSION}"

ARCH=$(arch)

# install tools and dependent packages
apt update && apt install -y git wget curl unzip nano vim make dos2unix openjdk-11-jdk

# install gradle 
GRADLE_VERSION=6.2.2
wget https://services.gradle.org/distributions/gradle-$GRADLE_VERSION-bin.zip
mkdir -p usr/local/gradle
unzip -d /usr/local/gradle gradle-$GRADLE_VERSION-bin.zip
ls usr/local/gradle/gradle-$GRADLE_VERSION/
rm -rf gradle-$GRADLE_VERSION-bin.zip
export GRADLE_HOME=/usr/local/gradle
export PATH=$PATH:$GRADLE_HOME/gradle-$GRADLE_VERSION/bin

export WORK_DIR=`pwd`
export HOME=$WORK_DIR

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

# clone repo
if ! git clone $PACKAGE_URL ; then
	echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails" > $WORK_DIR/output/version_tracker
	exit 0
fi

export HOME_DIR=$WORK_DIR/$PACKAGE_NAME

cd $HOME_DIR
git checkout $PACKAGE_VERSION

#gradle build | tee $LOGS_DIRECTORY/$PACKAGE_NAME-$PACKAGE_VERSION.txt

function try_gradle_with_jdk11(){
	echo "Building package with jdk 11"
    export JAVA_HOME=/usr/lib/jvm/$(ls /usr/lib/jvm/ | grep -P '^(?=.*java-11)(?=.*ppc64el)')
    echo "JAVA_HOME is $JAVA_HOME"
    export PATH=$PATH:$JAVA_HOME/bin
	
    cd $WORK_DIR/$PACKAGE_NAME/driver-core
	if ! gradle build; then
        exit 0
	fi

	cd $WORK_DIR/$PACKAGE_NAME/driver-core
	if ! gradle test; then
		echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
		echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/test_fails 
		echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails" > /home/tester/output/version_tracker
		exit 1
	else
		echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
		echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/test_success 
		echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success" > /home/tester/output/version_tracker
		get_list_of_jars_generated $HOME_DIR /home/tester/output/post_build_jars.txt
		exit 0
	fi
}

if test -f "gradlew"; then
	try_gradle_with_jdk11
fi
