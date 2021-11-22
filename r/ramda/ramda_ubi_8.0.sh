# ----------------------------------------------------------------------------
#
# Package         : RAMda
# Version         : v0.21.0
# Source repo     : https://github.com/ramda/ramda.git
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
# Node.js 
#
#
# ----------------------------------------------------------------------------

# variables
PKG_NAME="RAMda"
PKG_VERSION="v0.21.0"
REPOSITORY="https://github.com/ramda/ramda.git"

echo "Usage: $0 [v<PKG_VERSION>]"
echo "       PKG_VERSION is an optional paramater whose default value is v0.21.0"

PKG_VERSION="${1:-$PKG_VERSION}"

#install dependencies
yum -y update
yum install -y git cmake make gcc-c++ autoconf ncurses-devel.ppc64le wget.ppc64le openssl-devel.ppc64le diffutils procps-ng bzip2 python3 fontconfig-devel
yum module list nodejs
yum module install -y nodejs:14

# create folder for saving logs
mkdir -p /logs
LOGS_DIRECTORY=/logs

LOCAL_DIRECTORY=/root

#clone and build 
cd $LOCAL_DIRECTORY
git clone $REPOSITORY $PKG_NAME-$PKG_VERSION
cd $PKG_NAME-$PKG_VERSION/
git checkout $PKG_VERSION

npm ci
npm run build | tee $LOGS_DIRECTORY/$PKG_NAME-$PKG_VERSION.txt
npm run test
