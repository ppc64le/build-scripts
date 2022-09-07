#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : z-schema
# Version       : v3.25.1, v4.2.2, v4.2.3, v5.0.0, v5.0.3
# Source repo   : https://github.com/zaggino/z-schema
# Tested on     : ubi 8.5
# Language      : Node
# Travis-Check  : True
# Script License: Apache License Version 2.0
# Maintainer    : sachin.kakatkar@ibm.com, Stuti.Wali@ibm.com
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#Run the script:./z-schema_ubi_8.5.sh v5.0.3
PACKAGE_NAME=z-schema
PACKAGE_VERSION=${1:-v5.0.3}
PACKAGE_URL=https://github.com/zaggino/z-schema.git
dnf module enable nodejs:12 -y
dnf install git wget fontconfig bzip2 npm -y
wget https://github.com/ibmsoe/phantomjs/releases/download/2.1.1/phantomjs-2.1.1-linux-ppc64.tar.bz2
tar -xvf phantomjs-2.1.1-linux-ppc64.tar.bz2
ln -sf $(pwd)/phantomjs-2.1.1-linux-ppc64/bin/phantomjs /usr/local/bin/phantomjs
export PATH=$PATH:/usr/local/bin/phantomjs

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
git submodule update --init --recursive
npm ci
npm test

