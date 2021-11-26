# ----------------------------------------------------------------------------------------------------
#
# Package       : TypeScript
# Version       : master, 4.4.4
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
REPO=https://github.com/microsoft/TypeScript.git
PACKAGE_VERSION=4.4.4
PACKAGE_NAME=TypeScript

#Usage
echo "Usage: $0 [-v <PACKAGE_VERSION>]"
echo "PACKAGE_VERSION is an optional paramater whose default value is 4.4.4, not all versions are supported."
PACKAGE_VERSION="${1:-$PACKAGE_VERSION}"

#Install dependencies
yum install -y git unzip
#dnf module remove -y nodejs
#dnf module reset -y nodejs
dnf module install -y nodejs:14

#Clone the repo
cd /opt
git clone $REPO
cd $PACKAGE_NAME
if [[ "$PACKAGE_VERSION" = "master" ]]
then
	git checkout main
else
	git checkout v$PACKAGE_VERSION
fi

#Install node dependencies
npm install -g gulp
npm install

#Build
gulp local

#Test
gulp tests
gulp runtests-parallel

#Conclude
echo "Build and tests Complete. Uncomment the following lines to test browser integration, it takes a while to complete."

#npm i -D playwright
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
#CHROME_PLAYWRIGHT=$(find /root/.cache -name chrome-linux)
#rm -rf $CHROME_PLAYWRIGHT
#cp -r /opt/chromium_84_0_4118_0 $CHROME_PLAYWRIGHT
#dnf module install -y nodejs:14
#sed -i 's#"chromium", "firefox"#"chromium"#g' /opt/TypeScript/scripts/browserIntegrationTest.js
#cd /opt/TypeScript
#gulp test-browser-integration
#echo "Browser integration test complete!"
