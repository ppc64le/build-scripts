#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : Chart.js
# Version       : v2.9.3
# Source repo   : https://github.com/chartjs/Chart.js
# Tested on     : UBI: 8.5
# Language      : Node
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Valen Mascarenhas <Valen.Mascarenhas@ibm.com>
#
# Disclaimer: This script has been tested in non root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=Chart.js
PACKAGE_VERSION=${1:-v2.9.3}
PACKAGE_URL=https://github.com/chartjs/Chart.js.git

yum install -y sudo
sudo yum -y update && sudo yum install -y yum-utils nodejs npm git make wget tar zip nss libXScrnSaver libX11-xcb libXcomposite libXcursor libXfixes libXrender libXdamage atk at-spi2-atk at-spi2-core cups-libs avahi-libs libXrandr libdrm mesa-libgbm libwayland-server alsa-lib pango gtk3

mkdir -p home/tester && cd home/tester

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

npm install
sudo npm install -g gulp

if ! gulp build  ; then
	echo "------------------$PACKAGE_NAME:build_failure---------------------"
	exit 1
else
	echo "------------------$PACKAGE_NAME:build_success-------------------------"
fi


# ************** test ********************

#cd ..
# git clone https://github.com/karma-runner/karma-chrome-launcher.git
# cd karma-chrome-launcher
# git checkout v2.2.0
# sed -i "s/'--remote-debugging-port=9222'/'--remote-debugging-port=9222', '--no-sandbox'/g" index.js
# cd ..

#cd $PACKAGE_NAME
# sed -i "61s/Chrome/ChromeHeadless/" karma.conf.js
# npm install --save file:../karma-chrome-launcher
#export CHROME_BIN=/chromium/chromium_84_0_4118_0/chrome

# if ! node_modules/karma/bin/karma start karma.coverage.js --single-run ; then
# 	echo "------------------$PACKAGE_NAME:test_failure---------------------"
# 	exit 1
# else
# 	echo "------------------$PACKAGE_NAME:test_success-------------------------"
# fi

# ************** test ********************


# The code for testing this package is commented since the chrome binaries required for testing may not be accessible by the developer .
# Please refer to README.md to install the chrome binaries required for the testing 