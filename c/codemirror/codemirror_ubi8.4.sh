# ----------------------------------------------------------------------------
#
# Package	: CodeMirror
# Version	: 5.26.0
# Source repo	: https://github.com/codemirror/CodeMirror
# Tested on	: rhel_8.4
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
#!/bin/bash


# variables
PKG_NAME="CodeMirror"
PKG_VERSION=${1:-5.26.0}
LOCAL_DIRECTORY=/home/tester
REPOSITORY="https://github.com/codemirror/CodeMirror"

yum -y install wget bzip2 git 
wget https://github.com/ibmsoe/phantomjs/releases/download/2.1.1/phantomjs-2.1.1-linux-ppc64.tar.bz2
tar -xvf phantomjs-2.1.1-linux-ppc64.tar.bz2 

mv phantomjs-2.1.1-linux-ppc64/bin/phantomjs /usr/bin
rm -rf phantomjs-2.1.1-linux-ppc64.tar.bz2

wget -qO- https://raw.githubusercontent.com/creationix/nvm/v0.31.1/install.sh | sh
source $HOME/.nvm/nvm.sh
nvm install stable
nvm use stable


# ------- Clone and build source -------

mkdir -p $LOCAL_DIRECTORY
cd $LOCAL_DIRECTORY

git clone $REPOSITORY
cd $PKG_NAME
git checkout $PKG_VERSION
npm install -g npm@8.3.0
npm install
npm test

