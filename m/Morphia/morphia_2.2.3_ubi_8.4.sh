#! /bin/bash
# -----------------------------------------------------------------------------
#
# Package	: MorphiaOrg/morphia
# Version	: 2.2.3
# Source repo	: https://github.com/MorphiaOrg/morphia
# Tested on	: UBI 8.4
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
# 2. docker pull <MongoDB(version 4.0.24+) ppc64le Image>
# 3. docker run -d -p 27017:27017  <MongoDB(version 4.0.24+) ppc64le Image> --dbpath=/tmp --bind_ip_all 
# 4. docker run --network host -v /var/run/docker.sock:/var/run/docker.sock -it registry.access.redhat.com/ubi8/ubi:8.4
# Last step with give a prompt inside the container, run this script in it


WORK_DIR=`pwd`
PACKAGE_NAME=morphia
PACKAGE_VERSION=r2.2.3
PACKAGE_URL=https://github.com/MorphiaOrg/morphia.git

yum -y update 

# morphia version(2.2.3) require java 11
dnf install git wget unzip  java-11-openjdk-devel maven python3 python3-devel -y

export HOME=$WORK_DIR
export WORK_DIR=`pwd`

mkdir -p output
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
	echo "$PACKAGE_URL $PACKAGE_NAME" > $WORK_DIR/output/clone_fails
	echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails" > $WORK_DIR/output/version_tracker
	exit 0
fi

export HOME_DIR=$WORK_DIR/$PACKAGE_NAME
cd $HOME_DIR
git checkout $PACKAGE_VERSION
cd $WORKING_PATH

function try_mvn_with_jdk(){
	echo "Building package with jdk "
    export JAVA_HOME="/usr/lib/jvm/java-11-openjdk"
    export PATH="/usr/lib/jvm/java-11-openjdk":$PATH
	if ! mvn install -DskipTests; then
        exit 0
	fi
	cd $WORK_DIR/$PACKAGE_NAME
	if ! mvn test; then
		echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
		echo "$PACKAGE_URL $PACKAGE_NAME" > $WORK_DIR/output/test_fails 
		echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails" > $WORK_DIR/output/version_tracker
		exit 0
	else
		echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
		echo "$PACKAGE_URL $PACKAGE_NAME" > $WORK_DIR/output/test_success
		echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success" > $WORK_DIR/output/version_tracker
		exit 0
	fi
}


if test -f "pom.xml"; then
	export MAVEN_OPTS="-Xmx4G"
	try_mvn_with_jdk
fi

