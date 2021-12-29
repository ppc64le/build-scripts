# ----------------------------------------------------------------------------------------------------
#
# Package       : jquery.i18n
# Version       : 1.0.7
# Tested on     : UBI 8.3 (Docker)
# Script License: Apache License, Version 2 or later
# Maintainer    : Sumit Dubey <Sumit.Dubey2@ibm.com>
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------------------------------
#!/bin/bash

set -ex

#Variables
REPO=https://github.com/wikimedia/jquery.i18n.git
PACKAGE_VERSION=v1.0.7

echo "Usage: $0 [-v <PACKAGE_VERSION>]"
echo "PACKAGE_VERSION is an optional paramater whose default value is v1.0.7, not all versions are supported."
PACKAGE_VERSION="${1:-$PACKAGE_VERSION}"

#install dependencies
yum install git sed unzip -y
dnf module install -y nodejs:14

#clone the repo
cd /opt && git clone $REPO
cd jquery.i18n/
git submodule update --init
git checkout $PACKAGE_VERSION

#node dependencies
npm install

#build
npm build

#conclude
echo "Build Complete. Uncomment the following lines to run tests, they may take a while to complete."

#dnf remove -y module nodejs
#dnf module reset nodejs -y
#dnf -y install \
#http://mirror.centos.org/centos/8/BaseOS/ppc64le/os/Packages/centos-linux-repos-8-3.el8.noarch.rpm \
#http://mirror.centos.org/centos/8/BaseOS/ppc64le/os/Packages/centos-gpg-keys-8-3.el8.noarch.rpm
#yum install -y firefox libXScrnSaver libdrm mesa-libgbm alsa-lib python3 libarchive
#cd /opt
#git clone https://github.com/ppc64le/build-scripts.git
#cd build-scripts/c/chromium
#sed -i "s#./chromedriver --version#echo \$(pwd) > /opt/chrome.binary#g" Chromium_84.0.4118.0_UBI.sh
#./Chromium_84.0.4118.0_UBI.sh
#CHROME_DIR=$(cat /opt/chrome.binary)
#export CHROME_BIN=$CHROME_DIR/chrome
#chmod 777 $CHROME_BIN
#CHROME_PUPPETEER=$(find /opt/jquery.i18n -name chrome-linux)
#rm -rf $CHROME_PUPPETEER
#cp -r /opt/chromium_84_0_4118_0 $CHROME_PUPPETEER
#dnf module install -y nodejs:14
#cd /opt/jquery.i18n
#sed -i "s#'--headless',#'--headless', '--no-sandbox',#g" $(grep -Ril './' -e '--headless')
#npm test
#echo "Tests Complete!"
