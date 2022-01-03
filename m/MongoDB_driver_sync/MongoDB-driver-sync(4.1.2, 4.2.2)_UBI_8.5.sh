#! /bin/bash
# -----------------------------------------------------------------------------
#
# Package	: mongodb/mongo-java-driver
# Version	: 4.1.2/4.2.2
# Source repo	: https://github.com/mongodb/mongo-java-driver
# Tested on	: UBI 8.5
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
# Steps to test script
# 1. docker pull registry.access.redhat.com/ubi8
# 2. docker pull <MongoDB(version 4.0.24) ppc64le Image>
# 3. docker run -d -p 27017:27017  <MongoDB(version 4.0.24) ppc64le Image> --dbpath=/tmp --bind_ip_all 
# 4. docker run --network host -v /var/run/docker.sock:/var/run/docker.sock -it registry.access.redhat.com/ubi8/ubi:8.4
# Last step with give a prompt inside the container, run this script in it


PACKAGE_NAME=mongo-java-driver
PACKAGE_VERSION="${1:-r4.1.2}"
PACKAGE_URL=https://github.com/mongodb/mongo-java-driver.git

# install dependencies
dnf install git wget unzip  java-11-openjdk-devel -y

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
	exit 0
fi

export HOME_DIR=$WORK_DIR/$PACKAGE_NAME

cd $HOME_DIR
git checkout $PACKAGE_VERSION

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

