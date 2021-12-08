# ----------------------------------------------------------------------------
#
# Package         : shrinksafe
# Version         : 1.7.2 (master)
# Source repo     : https://github.com/zazl/shrinksafe.git
# Tested on       : UBI 8
# Script License  : MPL 1.1
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
# Java version 8 or later must be installed.
#
# ----------------------------------------------------------------------------

# variables
PKG_NAME="shrinksafe"
PKG_VERSION="v1.7.2"
REPOSITORY="https://github.com/zazl/shrinksafe.git"

echo "Usage: $0 [r<PKG_VERSION>]"
echo "       PKG_VERSION is an optional paramater whose default value is v1.7.2"

PKG_VERSION="${1:-$PKG_VERSION}"

#install dependencies
yum -y update
yum install -y git wget.ppc64le openssl-devel.ppc64le diffutils curl unzip zip

yum install -y java java-devel
whichJavaString=$(ls /usr/lib/jvm/ | grep -P '^(?=.*java-1.8)(?=.*ppc64le)')
# Set JAVA_HOME variable
export JAVA_HOME=/usr/lib/jvm/$whichJavaString
# update the path env. variable
export PATH=$PATH:$JAVA_HOME/bin

# create folder for saving logs
mkdir -p /logs
LOGS_DIRECTORY=/logs

LOCAL_DIRECTORY=/root

#clone and build 
cd $LOCAL_DIRECTORY
git clone $REPOSITORY $PKG_NAME-$PKG_VERSION
ls
cd $PKG_NAME-$PKG_VERSION/
git branch
#git checkout $PKG_VERSION

chmod +x build.sh
#./build.sh

bash build.sh

