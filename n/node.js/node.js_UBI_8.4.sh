# ----------------------------------------------------------------------------
#
# Package         : node.js
# Version         : v12.16.0
# Source repo     : https://github.com/nodejs/node.git
# Tested on       : rhel 8.4
# Script License  : MIT License
# Maintainer      : Manik Fulpagar <Manik.Fulpagar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash

# ----------------------------------------------------------------------------
# Prerequisites:
#
#gcc and g++ >= 6.3 or newer, or GNU Make 3.81 or newer
# 
#Python 2.7
#
# ----------------------------------------------------------------------------

# variables
PKG_NAME="node.js"
PKG_VERSION="v12.16.0"
REPOSITORY="https://github.com/nodejs/node.git"

echo "Usage: $0 [r<PKG_VERSION>]"
echo "       PKG_VERSION is an optional paramater whose default value is v12.16.0"

PKG_VERSION="${1:-$PKG_VERSION}"

#install dependencies
yum -y update
yum install -y git cmake make gcc-c++ python2 autoconf ncurses-devel.ppc64le wget.ppc64le openssl-devel.ppc64le diffutils procps-ng
  
# create folder for saving logs
mkdir -p /logs
LOGS_DIRECTORY=/logs

LOCAL_DIRECTORY=/root

#clone and build 
cd $LOCAL_DIRECTORY

git clone $REPOSITORY $PKG_NAME-$PKG_VERSION
cd $PKG_NAME-$PKG_VERSION/
git checkout $PKG_VERSION
git branch

./configure
make -j4 | tee $LOGS_DIRECTORY/$PKG_NAME_build.txt
make test-only | tee $LOGS_DIRECTORY/$PKG_NAME_test.txt