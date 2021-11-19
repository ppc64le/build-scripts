# ----------------------------------------------------------------------------
#
# Package         : jquery.cron
# Version         : v0.1.4.1
# Source repo     : https://github.com/shawnchin/jquery-cron.git
# Tested on       : rhel 8.3
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
# Node.js and Yarn.
#
# ----------------------------------------------------------------------------

# variables
PKG_NAME="jquery.cron"
PKG_VERSION="v0.1.4.1"
REPOSITORY="https://github.com/shawnchin/jquery-cron.git"

echo "Usage: $0 [v<PKG_VERSION>]"
echo "       PKG_VERSION is an optional paramater whose default value is v0.1.4.1"

PKG_VERSION="${1:-$PKG_VERSION}"

#install dependencies
yum -y update
yum install -y git wget.ppc64le openssl-devel.ppc64le diffutils curl unzip zip cmake make gcc-c++ autoconf ncurses-devel.ppc64le

yum module list nodejs
yum module install -y nodejs:12
npm install yarn --global

npm -v
node -v

cd root/

# create folder for saving logs
mkdir -p /logs
LOGS_DIRECTORY=/logs

#clone and build router
git clone $REPOSITORY $PKG_NAME-$PKG_VERSION
cd $PKG_NAME-$PKG_VERSION/
git checkout $PKG_VERSION
git branch

npm install | tee $LOGS_DIRECTORY/$PKG_NAME-log.txt
