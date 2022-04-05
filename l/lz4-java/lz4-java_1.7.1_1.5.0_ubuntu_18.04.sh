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
cd ..

export HOME=/home/tester

mkdir -p /home/tester/output
cd /home/tester

ln -s /usr/bin/python3 /bin/python

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

function get_checkout_url(){
        url=$1
        CHECKOUT_URL=`python3 -c "url='$url';github_url=url.split('tree')[0];print(github_url);"`
        echo $CHECKOUT_URL
}

function get_working_path(){
        url=$1
        CHECKOUT_URL=`python3 -c "url='$url';github_url,uri=url.split('tree');uris=uri.split('/');print('/'.join(uris[2:]));"`
        echo $CHECKOUT_URL
}

CLONE_URL=$(get_checkout_url $PACKAGE_URL)

if [ "$PACKAGE_URL" = "$CLONE_URL" ]; then
        WORKING_PATH="./"
else
        WORKING_PATH=$(get_working_path $PACKAGE_URL)
fi

if ! git clone $CLONE_URL $PACKAGE_NAME; then
	echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/clone_fails
	echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails" > /home/tester/output/version_tracker
	exit 1
fi

cd /home/tester/$PACKAGE_NAME
git checkout $PACKAGE_VERSION

git submodule init
git submodule update

# to build
function try_ant_with_jdk8(){
	echo "Building package with jdk 1.8"
    cd /home/tester/$PACKAGE_NAME

    if ! ant ivy-bootstrap; then
	exit 0
    fi

	cd /home/tester/$PACKAGE_NAME

	if ! ant test; then
		echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
		echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/test_fails 
		echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails" > /home/tester/output/version_tracker
		exit 1
	else
		echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
		echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/test_success
		echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success" > /home/tester/output/version_tracker
		exit 0
	fi
}

if test -f "build.xml"; then
	try_ant_with_jdk8
fi
