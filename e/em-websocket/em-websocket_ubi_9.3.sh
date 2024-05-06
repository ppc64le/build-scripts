#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : em-websocket
# Version       : v0.5.3
# Source repo   : https://github.com/igrigorik/em-websocket
# Tested on     : UBI: 9.3
# Language      : Ruby
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Abhishek Dwivedi <Abhishek.Dwivedi6@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
PACKAGE_NAME=em-websocket
PACKAGE_VERSION=${1:-v0.5.3}
PACKAGE_URL=https://github.com/igrigorik/em-websocket

yum -y update && yum install -y git gcc-c++ ruby ruby-devel redhat-rpm-config

gem install bundle

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

sed -i 's~git@github.com:movitto/em-websocket-client.git~https://github.com/movitto/em-websocket-client.git~g' Gemfile

if ! bundle install; then
	echo "------------------$PACKAGE_NAME:Installs_fails-------------------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_Fails"
	exit 1

fi

if ! bundle exec rspec; then
	echo "------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_success_but_test_Fails"
	exit 2
else
	echo "------------------$PACKAGE_NAME:Install_success_&_test_both_success-------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Pass |  Both_Build_and_Test_Success"
	exit 0
fi
