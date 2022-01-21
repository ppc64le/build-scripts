#!/bin/bash -e
# ----------------------------------------------------------------------------------------------------
#
# Package       : lz4-java
# Version       : 1.7.1, 1.5.0
# Source repo	: https://github.com/lz4/lz4-java.git
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

set -ex

#Variables
PACKAGE_NAME=lz4-java
PACKAGE_VERSION=1.7.1
PACKAGE_URL=https://github.com/lz4/lz4-java.git

ARCH=$(arch)

#Extract version from command line
echo "Usage: $0 [-v<PACKAGE_VERSION>]"
echo "PACKAGE_VERSION is an optional paramater whose default value is 1.7.1, not all versions are supported."
PACKAGE_VERSION="${1:-$PACKAGE_VERSION}"

#Dependencies
apt-get update && apt-get install -y git wget unzip build-essential python3 openjdk-8-jdk openjdk-8-jre
apt install -y xxhash liblz4-tool

cd /opt/
wget https://dlcdn.apache.org//ant/binaries/apache-ant-1.10.12-bin.zip
unzip apache-ant-1.10.12-bin.zip
export ANT_HOME=/opt/apache-ant-1.10.12
export PATH=/opt/apache-ant-1.10.12/bin:$PATH

export WORK_DIR=`pwd`
export HOME=$WORK_DIR

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

# clone repo
if ! git clone $PACKAGE_URL; then
	echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails" > $WORK_DIR/output/version_tracker
	exit 0
fi

export HOME_DIR=$WORK_DIR/$PACKAGE_NAME

cd $HOME_DIR
git checkout $PACKAGE_VERSION

git submodule init
git submodule update

# to build
function try_ant_with_jdk8(){
	echo "Building package with jdk 1.8"
    cd $WORK_DIR/$PACKAGE_NAME
	
    if ! ant ivy-bootstrap; then
	exit 0
        fi

	cd $WORK_DIR/$PACKAGE_NAME

	if ! ant test; then
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

if test -f "build.xml"; then
	try_ant_with_jdk8
fi
