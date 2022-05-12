#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : fancytree
# Version       : v2.37.0
# Source repo   : https://github.com/mar10/fancytree
# Tested on     : UBI: 8.5
# Language      : Node
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Shreya Kajbaje <Vedang.Wartikar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=fancytree
PACKAGE_VERSION=${1:-v2.37.0}
PACKAGE_URL=https://github.com/mar10/fancytree.git

sudo yum -y update && sudo yum install -y yum-utils nodejs npm git make wget tar zip nss libXScrnSaver libX11-xcb libXcomposite libXcursor libXfixes libXrender libXdamage atk at-spi2-atk at-spi2-core cups-libs avahi-libs libXrandr libdrm mesa-libgbm libwayland-server alsa-lib pango gtk3



git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

export PUPPETEER_SKIP_DOWNLOAD=true
export PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
#export PUPPETEER_EXECUTABLE_PATH=../../../../../../nfsrepos/chromium/chromium_84_0_4118_0/chrome

if ! npm install  ; then
	echo "------------------$PACKAGE_NAME:build_failure---------------------"
	exit 1
else
	echo "------------------$PACKAGE_NAME:build_success-------------------------"
fi

#if ! npm test ; then
#	echo "------------------$PACKAGE_NAME:test_failure---------------------"
#	exit 1
#else
#	echo "------------------$PACKAGE_NAME:test_success-------------------------"
#fi