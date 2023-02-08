#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	    : node-red
# Version	    : 3.0.2
# Source repo	: https://github.com/node-red/node-red.git
# Tested on	    : UBI 8.5
# Language      : NodeJs
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Pratik Tonage <Pratik.Tonage@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
PACKAGE_NAME=node-red
PACKAGE_VERSION=${1:-3.0.2}
PACKAGE_URL=https://github.com/node-red/node-red.git
NODE_VERSION=v16.13.0
DISTRO=linux-ppc64le

WORKDIR=`pwd`

#Install required dependencies
 yum install -y git wget python3  
 

 wget https://nodejs.org/dist/$NODE_VERSION/node-$NODE_VERSION-$DISTRO.tar.gz
 tar -C $WORKDIR -xzf node-$NODE_VERSION-$DISTRO.tar.gz
 rm -rf node-$NODE_VERSION-$DISTRO.tar.gz
 
 PATH=$WORKDIR/node-$NODE_VERSION-$DISTRO/bin:$PATH
 
 cd $WORKDIR
#Clone the repo
 git clone $PACKAGE_URL
 cd  $PACKAGE_NAME
 git checkout $PACKAGE_VERSION
 
if ! npm install; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $DISTRO | GitHub | Fail |  Install_Fails"
    exit 1
fi

#Build and test
 
if ! npm test; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME" 
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $DISTRO | GitHub | Fail |  Install_success_but_test_Fails"
    exit 1
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $DISTRO | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
