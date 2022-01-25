# ----------------------------------------------------------------------------
#
# Package       : soap-builder
# Version       : 93e5a7956ed68b6125ab756e9c6cddea266a9dc6 (commit ID)
# Source repo   : https://github.com/reficio/soap-ws
# Tested on     : ubi: 8.4
# Script License: Apache License 2.0
# Maintainer's  : Sapna Shukla<Sapna.Shukla@ibm.com>
#
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

#Variables.
BASE_PACKAGE_NAME=soap-ws
PACKAGE_NAME=soap-builder
PACKAGE_URL=https://github.com/reficio/soap-ws
PACKAGE_VERSION=93e5a7956ed68b6125ab756e9c6cddea266a9dc6

# Installation of required sotwares. 
yum install git maven -y 

# Cloning the repository from remote to local. 
git clone $PACKAGE_URL
cd $BASE_PACKAGE_NAME
git checkout $PACKAGE_VERSION

# Build and test.
if ! mvn -T 1C clean install -Dlicense.skip=true -Dadditionalparam=-Xdoclint:none -DskipTests; then
	echo "------------------$BASE_PACKAGE_NAME:INSTALL_FAILED-------------------------------------"
	exit 1
fi
cd $PACKAGE_NAME
if ! mvn clean install -Dlicense.skip=true; then
	echo "------------------$PACKAGE_NAME:INSTALL_AND_TEST_FAILED-------------------------------------------"
	exit 1
else
        echo -e "\n------------------$PACKAGE_NAME:INSTALL_AND_TEST_PASSED-------------------------"
        PATH=$(find -name *.jar)
        echo -e "\n------------------.JAR CREATED IN DIRECTORY:$BASE_PACKAGE_NAME/$PACKAGE_NAME, PATH-------------------------"
        echo "$PATH"
	exit 0
fi
