# ---------------------------------------------------------------------
#
# Package       : carbon-components
# Version       : 10.44.2. 10.45.0
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
REPO=https://github.com/carbon-design-system/carbon.git
PACKAGE_VERSION=10.44.2

echo "Usage: $0 [-v <PACKAGE_VERSION>]"
echo "PACKAGE_VERSION is an optional paramater whose default value is 10.44.2, not all versions are supported."

PACKAGE_VERSION="${1:-$PACKAGE_VERSION}"

#install dependencies
yum install git make gcc-c++ python3 unzip sed -y
dnf module install -y nodejs:14
curl --silent --location https://dl.yarnpkg.com/rpm/yarn.repo | tee /etc/yum.repos.d/yarn.repo
rpm --import https://dl.yarnpkg.com/rpm/pubkey.gpg
dnf install -y yarn

#clone the repo
cd /opt && git clone $REPO
cd carbon/
git checkout v$PACKAGE_VERSION
yarn install || true

#apply patches
sed -i 's/x64/ppc64/g' node_modules/chromedriver/install.js
sed -i 's/x64/ppc64/g' node_modules/gulp-axe-webdriver/node_modules/chromedriver/install.js
sed -i 's/x64/ppc64/g' node_modules/node-sass/test/errors.js

#build
yarn rebuild node-sass
yarn install
yarn build

#test
yarn test

#echo "Build and tests complete. Uncomment the following section to run Components specific tests."
#echo "Be aware that Components specific tests take a long time to complete."

#dnf -y install \
#http://mirror.centos.org/centos/8/BaseOS/ppc64le/os/Packages/centos-linux-repos-8-3.el8.noarch.rpm \
#http://mirror.centos.org/centos/8/BaseOS/ppc64le/os/Packages/centos-gpg-keys-8-3.el8.noarch.rpm
#yum install -y firefox libXScrnSaver libdrm mesa-libgbm alsa-lib libxshmfence
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
#rm -f $(find /opt/carbon -name chromedriver) || true
#sed -i "s#'--no-default-browser-check',#'--no-default-browser-check', '--headless',#g" /opt/carbon/node_modules/karma-chrome-launcher/index.js
#sed -i "s#: {}# : { 'args': ['--headless'] }#g" /opt/carbon/node_modules/gulp-axe-webdriver/index.js
#sed -i "s#'--headless'#'--headless', '--no-sandbox'#g"  $(grep -Ril '/opt/carbon/node_modules/' -e '--headless')
#cd carbon/packages/components
#yarn test
#echo "Components Tests Complete!"
