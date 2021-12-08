# ----------------------------------------------------------------------------
#
# Package         : Cordova-spatialite-storage
# Version         : 0.7.11
# Source repo     : https://github.com/DisyInformationssysteme/Cordova-spatialite-storage.git
# Tested on       : UBI 8.0
# Script License  : MIT or Apache 2.0 License
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
# ----------------------------------------------------------------------------

# variables
PKG_NAME="Cordova-spatialite-storage"
PKG_VERSION="2.0.0"

echo "Usage: $0 [<PKG_VERSION>]"
echo "       PKG_VERSION is an optional paramater whose default value is 2.0.0"

PKG_VERSION="${1:-$PKG_VERSION}"

#install dependencies
yum -y update
yum install -y git wget.ppc64le openssl-devel.ppc64le diffutils curl unzip zip
yum module list nodejs
yum module install -y nodejs:14

# create folder for saving logs
mkdir -p /logs
LOGS_DIRECTORY=/logs

#source for 0.7.11
mkdir Cordova-spatialite-storage
cd Cordova-spatialite-storage
wget https://github.com/davidovich/Cordova-spatialite-storage/archive/33d9faac87796a3a74c8f2330f97bd7cdf32a29b.zip
unzip 33d9faac87796a3a74c8f2330f97bd7cdf32a29b.zip
chmod -R +w .
ls
cd Cordova-spatialite-storage-33d9faac87796a3a74c8f2330f97bd7cdf32a29b/

LOCAL_DIRECTORY=/root

#clone and build 
#cd $LOCAL_DIRECTORY
#git clone https://github.com/DisyInformationssysteme/Cordova-spatialite-storage.git $PKG_NAME-$PKG_VERSION
#cd $PKG_NAME-$PKG_VERSION/

#git checkout $PKG_VERSION

npm install | tee $LOGS_DIRECTORY/$PKG_NAME-log.txt

npm test

