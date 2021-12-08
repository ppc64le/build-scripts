# ----------------------------------------------------------------------------
#
# Package       : soap-common
# Version       : 1.0.0-SNAPSHOT
# Source repo   : https://github.com/reficio/soap-ws
# Tested on     : ubi: 8.4
# Script License: Apache License 2.0
# Maintainer's	: Sapna Shukla <Sapna.Shukla@ibm.com> 
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
PACKAGE_NAME=soap-ws/soap-common
PACKAGE_URL=https://github.com/reficio/soap-ws
PACKAGE_COMMIT_ID=93e5a7956ed68b6125ab756e9c6cddea266a9dc6

# Installation of required sotwares. 
yum install git maven -y 

# Cloning the repository from remote to local. 
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_COMMIT_ID

# Build and test.
if ! mvn clean install -Dlicense.skip=true -Dadditionalparam=-Xdoclint:none -DskipTests; then
	echo "------------------$PACKAGE_NAME:INSTALL_FAILED-------------------------------------"
	exit 1
fi
if ! mvn test -Dlicense.skip=true; then
	echo "------------------$PACKAGE_NAME:INSTALL_PASSED_BUT_TEST_FAILED---------------------"
	exit 1
else
        echo -e "\n------------------$PACKAGE_NAME:INSTALL_&_TEST_BOTH_PASSED-------------------------"
        PATH=$(find -name *.jar)
        echo -e "\n------------------.JAR CREATED IN DIRECTORY:$PACKAGE_NAME, PATH-------------------------"
        echo "$PATH"
	exit 0
fi
