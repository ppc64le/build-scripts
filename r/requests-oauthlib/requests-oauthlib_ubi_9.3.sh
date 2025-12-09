#!/bin/bash -e
#
# -----------------------------------------------------------------------------
#
# Package       : requests-oauthlib
# Version       : v2.0.0
# Source repo   : https://github.com/requests/requests-oauthlib
# Tested on     : UBI 9.3
# Language      : c
# Ci-Check  : True
# Script License: Apache License 2.0
# Maintainer    : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=requests-oauthlib
PACKAGE_VERSION=${1:-v2.0.0}
PACKAGE_URL=https://github.com/requests/requests-oauthlib
PACKAGE_DIR=requests-oauthlib

# Install dependencies
yum install -y git gcc-toolset-13 gcc-toolset-13-gcc gcc-toolset-13-gcc-c++ python3 python3-devel python3-pip openssl-devel rust-toolset
export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH

pip3 install requests_mock selenium pytest
# Clone the repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

if ! pip3 install .; then
	echo "------------------$PACKAGE_NAME:install_fails---------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
	exit 1
fi

# Skipped on ppc64le architecture due to lack of official ChromeDriver support.
# Google ChromeDriver does not provide binaries for ppc64le, and Selenium Manager
# cannot resolve a compatible driver for this platform.
if ! pytest --deselect="tests/examples/test_native_spa_pkce_auth0.py"; then
	echo "------------------$PACKAGE_NAME:test_fails---------------------"
	echo  "$PACKAGE_URL $PACKAGE_NAME " 
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | Fail |  Test_Fails"
	exit 1
else
	echo "------------------$PACKAGE_NAME:install_and_test_both_success-------------------------"
	echo  "$PACKAGE_URL $PACKAGE_NAME " 
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | Pass |  Both_Install_and_Test_Success"
	exit 0
fi
