# -----------------------------------------------------------------------------
#
# Package	: react-modal
# Version	: v.3.12.1
# Source repo	: https://github.com/reactjs/react-modal.git
# Tested on	: {distro_name} {distro_version}
# Language      : Node
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: BulkPackageSearch Automation {maintainer}
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
# ************ Important Note *****************************************
# This package needs chrome binaries for testing. 
# This build script assumes that prebuilt binary already available at /chromium
# During testing I had used binaries on my host machine and mapped folder to conatiner 
# by running below command
# docker run -it -v /nfsrepos/chromium:/chromium registry.access.redhat.com/ubi8/ubi /bin/bash

PACKAGE_NAME=react-modal
PACKAGE_VERSION=v3.12.1
PACKAGE_URL=https://github.com/reactjs/react-modal.git

set -e

yum install -y git npm nodejs

mkdir -p /home/tester
cd /home/tester

#install chrome driver
git clone https://github.com/giggio/node-chromedriver.git
cd node-chromedriver/
git checkout 94.0.0
sed -i 's/x64/ppc64/g' install.js

cd ..
git clone https://github.com/felixzapata/gulp-axe-webdriver.git
cd gulp-axe-webdriver
git checkout 3.1.3
sed -i "s/options.headless ? { 'args': \['--headless'\] } : {}/options.headless ? { 'args': \['--headless', '--no-sandbox'\] } : { 'args': \['--no-sandbox'\] }/g" index.js
npm install --save file:../node-chromedriver --chromedriver_filepath=/chromium/chromium_84_0_4118_0/chromedriver
npm install


#install libraries required to run chrome
#dnf -y --disableplugin=subscription-manager install http://mirror.centos.org/centos/8/BaseOS/ppc64le/os/Packages/centos-gpg-keys-8-2.el8.noarch.rpm http://mirror.centos.org/centos/8/BaseOS/ppc64le/os/Packages/centos-linux-repos-8-2.el8.noarch.rpm https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm

yum install -y nss libXScrnSaver libX11-xcb libXcomposite libXcursor libXfixes libXrender libXdamage atk at-spi2-atk at-spi2-core cups-libs avahi-libs libXrandr libdrm mesa-libgbm libwayland-server alsa-lib pango gtk3

# chrome integration
cd /home/tester
git clone https://github.com/karma-runner/karma-chrome-launcher.git
cd karma-chrome-launcher
git checkout v2.2.0
sed -i "s/'--remote-debugging-port=9222'/'--remote-debugging-port=9222', '--no-sandbox'/g" index.js

# clone package to be tested
cd /home/tester
git clone $PACKAGE_URL
cd $PACKAGE_NAME

git checkout $PACKAGE_VERSION

npm install --save file:../karma-chrome-launcher
npm install

export CHROME_BIN=/chromium/chromium_84_0_4118_0/chrome

# Note: test completed successfully but did not exit automatically. Same observation on x86 as well
#	Press Ctrl-C to exit
npm test

exit 0
