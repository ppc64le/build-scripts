#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package         : Cordova-spatialite-storage
# Version         : 92c4df0
# Source repo     : https://github.com/DisyInformationssysteme/Cordova-spatialite-storage.git
# Tested on       : Ubuntu 18.04 (Docker)
# Script License  : MIT or Apache 2.0 License
# Language        : Node
# Travis-Check    : True
# Maintainer      : Sumit Dubey <sumit.dubey2@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -e

# variables
PKG_NAME="Cordova-spatialite-storage"
PKG_VERSION="2.0.0"

echo "Usage: $0 [<PKG_VERSION>]"
echo "PKG_VERSION is an optional paramater whose default value is 2.0.0"
PKG_VERSION="${1:-$PKG_VERSION}"

#install dependencies
apt-get -y update
apt-get install -y git wget libssl-dev diffutils curl unzip zip
curl https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
nvm install 14.18.2
node -v

# create folder for saving logs
mkdir -p /logs
LOGS_DIRECTORY=/logs

mkdir Cordova-spatialite-storage2
cd Cordova-spatialite-storage2
wget https://github.com/ckaz18/Cordova-spatialite-storage/archive/92c4df03a795af0bed32962446e3915d63ea1c52.zip
unzip 92c4df03a795af0bed32962446e3915d63ea1c52.zip
rm -rf 92c4df03a795af0bed32962446e3915d63ea1c52.zip
chmod -R +w .
ls
cd Cordova-spatialite-storage-92c4df03a795af0bed32962446e3915d63ea1c52/

LOCAL_DIRECTORY=/root

#clone and build
#cd $LOCAL_DIRECTORY
#git clone https://github.com/DisyInformationssysteme/Cordova-spatialite-storage.git $PKG_NAME-$PKG_VERSION
#cd $PKG_NAME-$PKG_VERSION/
#git checkout $PKG_VERSION

npm install | tee $LOGS_DIRECTORY/$PKG_NAME-log.txt