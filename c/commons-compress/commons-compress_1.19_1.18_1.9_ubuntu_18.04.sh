#!/bin/bash -e
# ----------------------------------------------------------------------------------------------------
#
# Package       : commons-compress
# Version       : 1.19, 1.18, 1.9
# Source repo	: https://github.com/apache/commons-compress.git
# Tested on     : ubuntu_18.04 (Docker)
# Language      : Java
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Manik Fulpagar <manik.fulpagar@ibm.com>
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------------------------------
# Note : Failed tests are in parity with x86: Failure is ubuntu specific.
#-----------------------------------------------------------------------------------------------------
set -ex

#Variables
PACKAGE_NAME=commons-compress
PACKAGE_VERSION=rel/1.19
PACKAGE_URL=https://github.com/apache/commons-compress.git

#Extract version from command line
echo "Usage: $0 [-v <PACKAGE_VERSION>]"
echo "PACKAGE_VERSION is an optional paramater whose default value is 1.19, not all versions are supported."
PACKAGE_VERSION="${1:-$PACKAGE_VERSION}"

#Dependencies
apt update && apt install -y git wget unzip openjdk-8-jdk openjdk-8-jre maven python3

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


#Build and test
mvn verify -Dorg.ops4j.pax.url.mvn.repositories="https://repo1.maven.org/maven2@id=central"

#The following failing tests are in parity with x86:
#1. UTF8ZipFilesTest.testReadWinZipArchive:137 ? MalformedInput Input length = 1
#2. UTF8ZipFilesTest.testReadWinZipArchiveForStream:165 ? MalformedInput Input len
