# ----------------------------------------------------------------------------
#
# Package       : use-resize-observer
# Version       : master
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
# ----------------------------------------------------------------------------

#!/bin/bash

set -ex

#Variables
REPO=https://github.com/ZeeCoder/use-resize-observer.git
PACKAGE_VERSION=master

echo "Usage: $0 [-v <PACKAGE_VERSION>]"
echo "PACKAGE_VERSION is an optional paramater whose default value is master, not all versions are supported."

PACKAGE_VERSION="${1:-$PACKAGE_VERSION}"

#install dependencies
yum install git make gcc-c++ python2 sed unzip -y

dnf module install -y nodejs:12
curl --silent --location https://dl.yarnpkg.com/rpm/yarn.repo | tee /etc/yum.repos.d/yarn.repo
rpm --import https://dl.yarnpkg.com/rpm/pubkey.gpg
dnf install -y yarn

#clone the repo
cd /opt && git clone $REPO
cd use-resize-observer/
if [[ "$PACKAGE_VERSION" = "master" ]]
then
	git checkout master
else
	git checkout v$PACKAGE_VERSION
fi

#build
yarn install
yarn build

#conclude
echo "Build Complete. Uncomment the following lines to run tests, they may take a while to complete."

#rm -f /usr/bin/python3
#dnf remove -y module nodejs
#dnf module reset nodejs -y
#yum install -y python3 libarchive
#dnf -y install \
#http://mirror.centos.org/centos/8/BaseOS/ppc64le/os/Packages/centos-linux-repos-8-3.el8.noarch.rpm \
#http://mirror.centos.org/centos/8/BaseOS/ppc64le/os/Packages/centos-gpg-keys-8-3.el8.noarch.rpm
#yum install -y firefox
#cd /opt
#git clone https://github.com/ppc64le/build-scripts.git
#cd build-scripts/c/chromium
#sed -i "s#./chromedriver --version#echo \$(pwd) > /opt/chrome.binary#g" Chromium_84.0.4118.0_UBI.sh
#./Chromium_84.0.4118.0_UBI.sh
#CHROME_DIR=$(cat /opt/chrome.binary)
#export CHROME_BIN=$CHROME_DIR/chrome
#chmod 777 $CHROME_BIN
#sed -i "s#'--headless'#'--headless', '--no-sandbox'#g" /opt/use-resize-observer/node_modules/karma-chrome-launcher/index.js
#dnf module install -y nodejs:12
#curl --silent --location https://dl.yarnpkg.com/rpm/yarn.repo | tee /etc/yum.repos.d/yarn.repo
#rpm --import https://dl.yarnpkg.com/rpm/pubkey.gpg
#dnf install -y yarn
#cd /opt/use-resize-observer
#sed -i "s#this.browserDisconnectTimeout = 2000#this.browserDisconnectTimeout = 210000#g" /opt/use-resize-observer/node_modules/karma/lib/config.js
#sed -i "s#this.captureTimeout = 60000#this.captureTimeout = 210000#g" /opt/use-resize-observer/node_modules/karma/lib/config.js
#sed -i "s#this.browserNoActivityTimeout = 30000#this.browserNoActivityTimeout = 210000#g" /opt/use-resize-observer/node_modules/karma/lib/config.js
#sed -i "s#this.browserDisconnectTolerance = 0#this.browserDisconnectTolerance = 3#g" /opt/use-resize-observer/node_modules/karma/lib/config.js
#yarn test
#echo "Tests Complete!"

