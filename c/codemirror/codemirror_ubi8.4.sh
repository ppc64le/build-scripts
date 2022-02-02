#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package	: CodeMirror
# Version	: 5.26.0
# Source repo	: https://github.com/codemirror/CodeMirror
# Tested on	: rhel_8.4
# Language      : Node
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Vikas Gupta <vikas.gupta8@ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
set -e

# variables
PACKAGE_NAME="CodeMirror"
PACKAGE_VERSION=${1:-5.26.0}
PACKAGE_URL="https://github.com/codemirror/CodeMirror"

yum install -y wget bzip2 git 
yum install -y yum-utils nodejs nodejs-devel nodejs-packaging npm
yum install -y fontconfig freetype freetype-devel fontconfig-devel libstdc++

npm install n -g && n latest && npm install -g npm@latest && export PATH="$PATH"

mkdir -p /home/tester/output
cd /home/tester

wget https://github.com/ibmsoe/phantomjs/releases/download/2.1.1/phantomjs-2.1.1-linux-ppc64.tar.bz2 && tar -xvf phantomjs-2.1.1-linux-ppc64.tar.bz2 

mv phantomjs-2.1.1-linux-ppc64/bin/phantomjs /usr/bin
rm -rf phantomjs-2.1.1-linux-ppc64.tar.bz2

#wget -qO- https://raw.githubusercontent.com/creationix/nvm/v0.31.1/install.sh | sh
#source $HOME/.nvm/nvm.sh
#nvm install stable
#nvm use stable


# ------- Clone and build source -------
if ! git clone $PACKAGE_URL $PACKAGE_NAME; then
    	echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
		echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/clone_fails
        echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails" > /home/tester/output/version_tracker
    	exit 0
fi

cd /home/tester/$PACKAGE_NAME
git checkout $PACKAGE_VERSION
# run the test command from test.sh

if ! npm install && npm audit fix && npm audit fix --force; then
     	echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/install_fails
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails" > /home/tester/output/version_tracker
	exit 1
fi

cd /home/tester/$PACKAGE_NAME

npm test

