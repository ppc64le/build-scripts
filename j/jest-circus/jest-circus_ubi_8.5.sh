#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: jest-circus
# Version	: v27.3.1
# Source repo	: https://github.com/facebook/jest
# Tested on	: UBI: 8.5
# Language      : Node
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: BulkPackageSearch Automation {maintainer}
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=jest-circus
PACKAGE_VERSION=${1:-v27.3.1}
PACKAGE_URL=https://github.com/facebook/jest

yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
# yum install -y yum-utils nodejs nodejs-devel nodejs-packaging npm python38 python38-devel ncurses git gcc gcc-c++ libffi libffi-devel ncurses git jq make cmake
# npm install --global yarn grunt-bump xo testem acorn

# yum install -y yum-utils nodejs nodejs-devel nodejs-packaging npm python38 python38-devel ncurses git gcc gcc-c++ libffi libffi-devel ncurses git jq make cmake

# npm install n -g && n 14 && npm install -g npm@6 && export PATH="$PATH" && npm install --global yarn grunt-bump xo testem acorn
NODE_VERSION=v12.22.4
#installing nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash
source ~/.bashrc
nvm install $NODE_VERSION

yum install -y yum-utils python38 python38-devel ncurses git gcc gcc-c++ libffi libffi-devel ncurses git jq make cmake
npm install --global yarn grunt-bump xo testem acorn

mkdir -p /home/tester/output
cd /home/tester

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

if ! git clone $PACKAGE_URL jest; then
    	echo "------------------jest:clone_fails---------------------------------------"
		echo "$PACKAGE_URL jest" > /home/tester/output/clone_fails
        echo "jest  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails" > /home/tester/output/version_tracker
    	exit 0
fi

cd /home/tester/jest
git checkout $PACKAGE_VERSION
PACKAGE_VERSION=$(jq -r ".version" package.json)

cd packages/$PACKAGE_NAME

if ! yarn add --dev $PACKAGE_NAME; then
     	echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
		echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/install_fails
		echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails" > /home/tester/output/version_tracker
		exit 1
else
		echo "------------------$PACKAGE_NAME:install_success-------------------------------------"
		echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/install_success
		echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Success" > /home/tester/output/version_tracker
		exit 1
fi