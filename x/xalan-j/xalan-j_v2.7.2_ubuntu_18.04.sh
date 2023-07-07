#!/bin/bash -e
#----------------------------------------------------------------------------
#
# Package	    : xalan-j
# Version	    : 2.7.2
# Source repo	: https://github.com/apache/xalan-j
# Tested on     : ubuntu_18.04 (Docker)
# Language      : Java
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Jotirling Swami <Jotirling.Swami1@ibm.com>
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
PACKAGE_NAME=xalan-j
PACKAGE_VERSION=xalan-j_2_7_2
PACKAGE_URL=https://github.com/apache/xalan-j

#Extract version from command line
echo "Usage: $0 [-v <PACKAGE_VERSION>]"
echo "PACKAGE_VERSION is an optional paramater whose default value is $PACKAGE_VERSION and building for ${1:-$PACKAGE_VERSION}"

PACKAGE_VERSION="${1:-$PACKAGE_VERSION}"

#Dependencies
apt update -y && apt install -y git openjdk-8-jdk wget

#Home dir
HOME_DIR=`pwd`

#Install ANT
apt install -y wget
wget https://downloads.apache.org/ant/binaries/apache-ant-1.10.12-bin.tar.gz
tar xzf apache-ant-1.10.12-bin.tar.gz
ln -s apache-ant-1.10.12 ant
export M2_HOME=$HOME_DIR/ant
export PATH=${M2_HOME}/bin:${PATH}
ant -version

#Clone repo
OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

#Get the sources
cd $HOME_DIR
mkdir ${PACKAGE_NAME}
cd $HOME_DIR/$PACKAGE_NAME
if ! git clone $PACKAGE_URL $PACKAGE_NAME; then
	echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | Fail |  Clone_Fails"
	exit 0
fi

#Build and test
cd $HOME_DIR/$PACKAGE_NAME/$PACKAGE_NAME
git checkout $PACKAGE_VERSION
if ! ant; then
	echo "------------------$PACKAGE_NAME:build_fails---------------------"
	echo  "$PACKAGE_URL $PACKAGE_NAME " 
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | Fail |  Build_Fails"
	exit 0
else
	echo "------------------$PACKAGE_NAME:build_success-------------------------"
	echo  "$PACKAGE_URL $PACKAGE_NAME " 
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | Pass |  Build_Success"
	exit 0
fi