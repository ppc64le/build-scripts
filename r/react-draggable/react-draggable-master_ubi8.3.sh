# ----------------------------------------------------------------------------------------------------
#
# Package       : react-draggable
# Version       : master
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
REPO=https://github.com/react-grid-layout/react-draggable.git
PACKAGE_VERSION=master

echo "Usage: $0 [-v <PACKAGE_VERSION>]"
echo "PACKAGE_VERSION is an optional paramater whose default value is master, not all versions are supported."

PACKAGE_VERSION="${1:-$PACKAGE_VERSION}"

#install dependencies
yum install git sed unzip bzip2 make -y

dnf module install -y nodejs:14

#clone the repo
cd /opt && git clone $REPO
cd react-draggable/
git submodule update --init
if [[ "$PACKAGE_VERSION" = "master" ]]
then
	git checkout master
else
	git checkout v$PACKAGE_VERSION
fi

curl --silent --location https://dl.yarnpkg.com/rpm/yarn.repo | tee /etc/yum.repos.d/yarn.repo
rpm --import https://dl.yarnpkg.com/rpm/pubkey.gpg
dnf install -y yarn


#Get phantomjs
cd /opt
yum install -y wget bzip2 fontconfig-devel
wget https://github.com/ibmsoe/phantomjs/releases/download/2.1.1/phantomjs-2.1.1-linux-ppc64.tar.bz2
tar -xvf phantomjs-2.1.1-linux-ppc64.tar.bz2
ln -s /phantomjs-2.1.1-linux-ppc64/bin/phantomjs /usr/local/bin/phantomjs
export PATH=$PATH:/opt/phantomjs-2.1.1-linux-ppc64/bin/

#build
cd react-draggable/
yarn install
yarn build

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
#cd /opt/react-draggable/
#sed -i "s#this.browserDisconnectTimeout = 2000#this.browserDisconnectTimeout = 210000#g" /opt/react-draggable/node_modules/karma/lib/config.js
#sed -i "s#this.captureTimeout = 60000#this.captureTimeout = 210000#g" /opt/react-draggable/node_modules/karma/lib/config.js
#sed -i "s#this.browserNoActivityTimeout = 30000#this.browserNoActivityTimeout = 210000#g" /opt/react-draggable/node_modules/karma/lib/config.js
#sed -i "s#this.browserDisconnectTolerance = 0#this.browserDisconnectTolerance = 3#g" /opt/react-draggable/node_modules/karma/lib/config.js
#sed -i "s#'--headless'#'--headless', '--no-sandbox'#g" /opt/react-draggable/node_modules/karma-chrome-launcher/index.js
#sed -i "s#url, '-profile'#url, '-headless', '-profile'#g" /opt/react-draggable/node_modules/karma-firefox-launcher/index.js
#yarn test
#echo "Tests Complete!"
