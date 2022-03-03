# -----------------------------------------------------------------------------
#
# Package	    : path-loader
# Version	    : v1.0.10
# Source repo	: https://github.com/whitlockjc/path-loader.git
# Tested on	    : UBI 8.3
# Language      : Node
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Srividya Chittiboina <Srividya.Chittiboina@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -e

WORK_DIR=`pwd`

PACKAGE_NAME=path-loader
PACKAGE_VERSION=${1:-v1.0.10}
PACKAGE_URL=https://github.com/whitlockjc/path-loader.git

yum install git -y

#install phantomjs
yum install wget bzip2 freetype fontconfig -y
wget https://github.com/ibmsoe/phantomjs/releases/download/2.1.1/phantomjs-2.1.1-linux-ppc64.tar.bz2
tar -xvf phantomjs-2.1.1-linux-ppc64.tar.bz2
ln -s $WORK_DIR/phantomjs-2.1.1-linux-ppc64/bin/phantomjs /usr/local/bin/phantomjs

#install node version-10
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash
source ~/.bashrc
nvm install 10.0.0

#clone repo
cd $WORK_DIR
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout ${PACKAGE_VERSION}

#build repo
npm install
#test repo
npm test