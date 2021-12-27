# -----------------------------------------------------------------------------
#
# Package	: mongodb/mongo-java-driver
# Version	: 3.9.0
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
PACKAGE_VERSION="${1:-r3.9.0}"
PACKAGE_URL=https://github.com/mongodb/mongo-java-driver.git

dnf install git wget unzip  java-11-openjdk-devel  python3 python3-devel -y

export WORK_DIR=`pwd`

wget https://services.gradle.org/distributions/gradle-4.10-bin.zip -P /tmp && unzip -d $WORK_DIR/gradle /tmp/gradle-4.10-bin.zip
export GRADLE_HOME=$WORK_DIR/gradle/gradle-4.10/
export PATH=${GRADLE_HOME}/bin:${PATH}


mkdir -p output
ln -s /usr/bin/python3 /bin/python

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

if ! git clone $PACKAGE_URL; then
	exit 0
fi

export HOME_DIR=$WORK_DIR/$PACKAGE_NAME

cd $HOME_DIR
git checkout $PACKAGE_VERSION

# build 
cd $WORK_DIR/$PACKAGE_NAME/driver-core
if ! gradle build; then
	exit 0
fi

# test package
cd $WORK_DIR/$PACKAGE_NAME/driver-core

if ! gradle test; then
	echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails" > $WORK_DIR/output/version_tracker
	exit 0
else
	echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success" > $WORK_DIR/output/version_tracker
	exit 0
fi

# The 1 test failure is because mmpapv1 storage engine is not supported by the ppc64le MongoDB image being used.

