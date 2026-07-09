#!/bin/bash -e
# ----------------------------------------------------------------------------------------------------------------------
#
# Package       : popper.js (popper-core)
# Version       : master, 2.10.2, 2.9.2
# Source repo   : https://github.com/chtd/psycopg2cffi.git
# Tested on     : UBI 8.3 (Docker)
# Script License: Apache License, Version 2 or later
# Language       : NPM
# Travis-Check   : True
# Maintainer    : Sumit Dubey <Sumit.Dubey2@ibm.com>
# Instructions	: 1. Run the docker container as: 
#		  docker run -t -d --privileged --shm-size=1gb registry.access.redhat.com/ubi8/ubi:8.3 /usr/sbin/init
#		  2. Connect to the docker container
#		  docker exec -it <container id> bash
#		  3. Run this script
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------------------------------------------------
#Variables
PACKAGE_NAME=popper-core
PACKAGE_URL=https://github.com/popperjs/popper-core.git
PACKAGE_VERSION=${1:-2.9.2}

echo "PACKAGE_VERSION is an optional paramater whose default value is master, not all versions are supported."

PACKAGE_VERSION="${1:-$PACKAGE_VERSION}"

#install dependencies
yum install gcc-c++ make python3 python3-pip git sed unzip procps java-1.8.0-openjdk java-1.8.0-openjdk-devel -y
dnf module install -y nodejs:14
curl --silent --location https://dl.yarnpkg.com/rpm/yarn.repo | tee /etc/yum.repos.d/yarn.repo
rpm --import https://dl.yarnpkg.com/rpm/pubkey.gpg
dnf install -y yarn

#clone the repo
cd /opt && git clone $PACKAGE_URL
cd $PACKAGE_NAME/
if [[ "$PACKAGE_VERSION" = "master" ]]
then
	git checkout master
else
	git checkout v$PACKAGE_VERSION
fi

#install node dependencies
yarn install
yarn add closure-compiler -W

#patch
sed -i "s#firstSupportedPlatform !== Platform.JAVA#firstSupportedPlatform === Platform.JAVA#g" /opt/popper-core/node_modules/@ampproject/rollup-plugin-closure-compiler/dist/index.js
sed -i "s#google-closure-compiler-linux#google-closure-compiler-java#g" /opt/popper-core/node_modules/@ampproject/rollup-plugin-closure-compiler/node_modules/google-closure-compiler/lib/utils.js
sed -i "s#'--use-mock-keychain',#'--use-mock-keychain', '--disable-gpu', '--disable-software-rasterizer',#g" /opt/popper-core/node_modules/puppeteer/lib/cjs/puppeteer/node/Launcher.js
sed -i "s#'--use-mock-keychain',#'--use-mock-keychain', '--disable-gpu', '--disable-software-rasterizer',#g" /opt/popper-core/node_modules/puppeteer/lib/esm/puppeteer/node/Launcher.js


#build
yarn build

#conclude
echo "Build Complete. Uncomment the following lines to run tests, they may take a while to complete."


#dnf remove -y module nodejs
#dnf module reset nodejs -y
#dnf -y install \
#http://mirror.centos.org/centos/8/BaseOS/ppc64le/os/Packages/centos-linux-repos-8-3.el8.noarch.rpm \
#http://mirror.centos.org/centos/8/BaseOS/ppc64le/os/Packages/centos-gpg-keys-8-3.el8.noarch.rpm
#yum install -y firefox libXScrnSaver libdrm mesa-libgbm alsa-lib libxshmfence python3 libarchive
#cd /opt
#git clone https://github.com/ppc64le/build-scripts.git
#cd build-scripts/c/chromium
#sed -i "s#./chromedriver --version#echo \$(pwd) > /opt/chrome.binary#g" Chromium_84.0.4118.0_UBI.sh
#./Chromium_84.0.4118.0_UBI.sh
#CHROME_DIR=$(cat /opt/chrome.binary)
#CHROME_PUPPETEER=$(find /opt/popper-core -name chrome-linux)
#rm -rf $CHROME_PUPPETEER
#cp -r $CHROME_DIR $CHROME_PUPPETEER
#dnf module install -y nodejs:14
#curl --silent --location https://dl.yarnpkg.com/rpm/yarn.repo | tee /etc/yum.repos.d/yarn.repo
#rpm --import https://dl.yarnpkg.com/rpm/pubkey.gpg
#dnf install -y yarn
#cd /opt/popper-core
#yarn run test:unit
#yarn run test:functional -u
#echo "Tests Complete!"

