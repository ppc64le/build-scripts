#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package         : shrinksafe
# Version         : master(commit-id:0f46e2942af3b4894e7f0790e9f4e7f7d1a7969c)
# Source repo     : https://github.com/zazl/shrinksafe.git
# Tested on       : Ubuntu 18.04 (Docker)
# Language        : Java
# Travis-Check    : True
# Script License  : Apache License, Version 2 or later
# Maintainer      : Sumit Dubey <Sumit Dubey@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

# variables
PKG_NAME="shrinksafe"
PKG_VERSION="0f46e2942af3b4894e7f0790e9f4e7f7d1a7969c"
PKG_URL="https://github.com/zazl/shrinksafe.git"
PKG_VERSION="${1:-$PKG_VERSION}"

#install dependencies
apt-get -y update
apt-get install -y git wget libssl-dev diffutils curl unzip zip openjdk-8-jdk

#create folder for saving logs
mkdir -p /logs
LOGS_DIRECTORY=/logs
LOCAL_DIRECTORY=/root

#clone and build
cd $LOCAL_DIRECTORY
git clone $PKG_URL
cd $PKG_NAME
git checkout $PKG_VERSION

chmod +x build.sh
bash build.sh