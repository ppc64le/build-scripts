# ---------------------------------------------------------------------
#
# Package       : angular.js
# Version       : master, 1.8.2
# Tested on     : UBI 8.3 (Docker)
# Script License: Apache License, Version 2 or later
# Maintainer    : Sumit Dubey <Sumit.Dubey2@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------

#!/bin/bash

set -ex

#Variables
REPO=https://github.com/angular/angular.js.git
PACKAGE_VERSION=1.8.2

echo "Usage: $0 [-v <PACKAGE_VERSION>]"
echo "PACKAGE_VERSION is an optional paramater whose default value is 1.8.2, not all versions are supported."

PACKAGE_VERSION="${1:-$PACKAGE_VERSION}"

#install dependencies
yum install git sed wget make gcc gcc-c++ unzip zip python3 java-1.8.0-openjdk-devel -y
dnf module install -y nodejs:14

#Insall yarn
curl --silent --location https://dl.yarnpkg.com/rpm/yarn.repo | tee /etc/yum.repos.d/yarn.repo
rpm --import https://dl.yarnpkg.com/rpm/pubkey.gpg
dnf install -y yarn

#clone the repo
cd /opt && git clone $REPO
cd angular.js/
git submodule update --init
if [[ "$PACKAGE_VERSION" = "master" ]]
then
	git checkout master
else
	git checkout v$PACKAGE_VERSION
fi


#build
yarn global add grunt-cli
yarn install
yarn grunt package

#Unit tests
dnf -y install \
http://mirror.centos.org/centos/8/BaseOS/ppc64le/os/Packages/centos-linux-repos-8-3.el8.noarch.rpm \
http://mirror.centos.org/centos/8/BaseOS/ppc64le/os/Packages/centos-gpg-keys-8-3.el8.noarch.rpm
yum install -y firefox libXScrnSaver libdrm mesa-libgbm alsa-lib
sed -i "s#'-wait-for-browser'#'-wait-for-browser', '-headless'#g" /opt/angular.js/node_modules/karma-firefox-launcher/index.js
yarn grunt test:unit --browsers=Firefox

#conclude
echo "Build and unit tests Complete. Uncomment the following lines to run the end to end tests. End to end tests take a long time to complete."

#dnf remove -y module nodejs
#dnf module reset -y nodejs
#yum install -y python3 libarchive
#cd /opt
#git clone https://github.com/ppc64le/build-scripts.git
#cd build-scripts/c/chromium
#sed -i "s#./chromedriver --version#echo \$(pwd) > /opt/chrome.binary#g" Chromium_84.0.4118.0_UBI.sh
#./Chromium_84.0.4118.0_UBI.sh
#CHROME_DIR=$(cat /opt/chrome.binary)
#export CHROME_BIN=$CHROME_DIR/chrome
#chmod 777 $CHROME_BIN
#PATH=$PATH:$CHROME_DIR
#dnf module install -y nodejs:14
#unalias cp || true
#cp -f $CHROME_BIN $CHROME_DIR/google-chrome
#DRIVER_BIN=$CHROME_DIR/chromedriver
#DRIVER_DIR=/opt/angular.js/node_modules/webdriver-manager/selenium/
#DRIVER_VERSION=$(wget https://chromedriver.storage.googleapis.com/LATEST_RELEASE -q -O -)
#DRIVER_ZIP=chromedriver_$DRIVER_VERSION.zip
#DRIVER_FILENAME=chromedriver_$DRIVER_VERSION
#mkdir -p $DRIVER_DIR
#cd $DRIVER_DIR
#unalias cp || true
#cp -f $DRIVER_BIN $DRIVER_DIR
#cp -f $DRIVER_BIN $DRIVER_FILENAME
#rm -rf $DRIVER_ZIP
#chmod 777 $DRIVER_FILENAME
#zip $DRIVER_ZIP $DRIVER_FILENAME
#sed -i "s#config.capabilities.browserName = 'chrome';#config.capabilities = \
#{ 'browserName': 'chrome', 'chromeOptions': { 'args': ['--no-sandbox', '--headless'] } };#g" \
#/opt/angular.js/protractor-conf.js

#cd /opt/angular.js
#yarn grunt test:e2e

#echo "E2E tests Complete!"