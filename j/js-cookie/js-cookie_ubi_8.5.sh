#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: js-cookie
# Version	: v3.0.0
# Source repo	: https://github.com/js-cookie/js-cookie
# Tested on	: UBI: 8.5
# Language      : Node
# Travis-Check  : True
# Script License: MIT License
# Maintainer	: Vishaka Desai <Vedang.Wartikar@ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=js-cookie
PACKAGE_VERSION=${1:-v3.0.0}
PACKAGE_URL=https://github.com/js-cookie/js-cookie.git

yum -y update && yum install -y yum-utils nodejs npm git make wget tar zip nss libXScrnSaver libX11-xcb libXcomposite libXcursor libXfixes libXrender libXdamage atk at-spi2-atk at-spi2-core cups-libs avahi-libs libXrandr libdrm mesa-libgbm libwayland-server alsa-lib pango gtk3

export PUPPETEER_SKIP_DOWNLOAD=true
export PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
# export PUPPETEER_EXECUTABLE_PATH=../chromium/chromium_84_0_4118_0/chrome

mkdir -p output

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

if ! git clone $PACKAGE_URL $PACKAGE_NAME; then
    	echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
		echo "$PACKAGE_URL $PACKAGE_NAME" > ../output/clone_fails
        echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails" > ../output/version_tracker
    	exit 0
fi

cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

if ! npm install && npm audit fix && npm audit fix --force; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME" > ../output/install_fails
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails" > ../output/version_tracker
	exit 1
fi

# The code for testing this package is commented since the chrome binaries required for testing may not be accessible by the developer .
# Please refer to README.md to install the chrome binaries required for the testing

# ************** test ********************

# if ! npm test; then
# 	echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
# 	echo "$PACKAGE_URL $PACKAGE_NAME" > ../output/test_fails 
# 	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails" > ../output/version_tracker
# 	exit 1
# else
# 	echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
# 	echo "$PACKAGE_URL $PACKAGE_NAME" > ../output/test_success 
# 	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success" > ../output/version_tracker
# 	exit 0
# fi

# ************** test ******************** 