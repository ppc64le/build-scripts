#!/bin/bash -e
# ----------------------------------------------------------------------------------------------------------------------
#
# Package       : jquery-form
# Version       : v4.3.0
# Source repo   : https://github.com/jquery-form/form.git
# Tested on     : UBI 8.3 (Docker)
# Language       : NPM
# Travis-Check   : True
# Script License : Apache License, Version 2 or later
# Maintainer    : Raju Sah <Raju.Sah@ibm.com>
# 
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------------------------------------------------

#Variables
PACKAGE_NAME=form
PACKAGE_URL=https://github.com/jquery-form/form.git
PACKAGE_VERSION=${1:-v4.3.0}

#Install dependencies
yum install -y npm git wget bzip2 fontconfig-devel
npm install -g grunt-cli
wget https://github.com/ibmsoe/phantomjs/releases/download/2.1.1/phantomjs-2.1.1-linux-ppc64.tar.bz2
tar -xvf phantomjs-2.1.1-linux-ppc64.tar.bz2
ln -s /phantomjs-2.1.1-linux-ppc64/bin/phantomjs /usr/local/bin/phantomjs
export PATH=$PATH:/phantomjs-2.1.1-linux-ppc64/bin/phantomjs

#clone the repo
cd /opt && git clone $PACKAGE_URL
cd $PACKAGE_NAME/
git checkout $PACKAGE_VERSION

#Install and Test the package.
npm install --save-dev grunt
grunt test
