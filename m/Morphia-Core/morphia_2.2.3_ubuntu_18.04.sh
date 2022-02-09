#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	    : morphia
# Version	    : 2.2.3
# Source repo	: https://github.com/MorphiaOrg/morphia
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
# 3. docker run -d -p 27017:27017  <MongoDB(version 4.0.24) ppc64le Image> --dbpath=/tmp --bind_ip_all 
# 4. docker run --network host -v /var/run/docker.sock:/var/run/docker.sock -it --name morphia-testcontainer docker.io/ppc64le/ubuntu:18.04
# Last step with give a prompt inside the container, run this script in it

set -ex

# variables
PACKAGE_NAME=morphia
PACKAGE_VERSION=r2.2.3
PACKAGE_URL="https://github.com/MorphiaOrg/morphia.git"

echo "Usage: $0 [r<PKG_VERSION>]"
echo "       PKG_VERSION is an optional paramater whose default value is r2.2.3"
PKG_VERSION="${1:-$PKG_VERSION}"

#install dependencies
apt update && apt install -y git wget curl unzip nano vim make diffutils python3 openjdk-11-jdk
# install maven
apt install -y maven

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
   
function get_list_of_jars_generated(){
	VALIDATE_DIR=$1
	FILE_NAME=$1
	find -name *.jar >> $FILE_NAME
}

export HOME_DIR=/home/tester/$PACKAGE_NAME
cd $HOME_DIR
git checkout $PACKAGE_VERSION
cd $WORKING_PATH

# run the test command from test.sh

# Check the type of Java build tool, 
# ant = build.xml file exists
# maven = pom.xml file exists
# gradle = gradle.properties file exists

function try_mvn_with_jdk11(){
	echo "Building package with jdk 11"
    # setup java environment
    export JAVA_HOME=/usr/lib/jvm/$(ls /usr/lib/jvm/ | grep -P '^(?=.*java-11)(?=.*ppc64el)')
    echo "JAVA_HOME is $JAVA_HOME"
    export PATH=$PATH:$JAVA_HOME/bin
    echo $PATH

	if ! mvn -T 4 clean install; then
        exit 0
	fi
	cd /home/tester/$PACKAGE_NAME
	if ! mvn test; then
		echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
		echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/test_fails 
		echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails" > /home/tester/output/version_tracker
		exit 1
	else
		echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
		echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/test_success 
		echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success" > /home/tester/output/version_tracker
		#get_list_of_jars_generated $HOME_DIR /home/tester/output/post_build_jars.txt
		exit 0
	fi
}

#get_list_of_jars_generated $HOME_DIR /home/tester/output/pre_build_jars.txt
if test -f "pom.xml"; then
	export MAVEN_OPTS="-Xmx4G"
	try_mvn_with_jdk11
fi