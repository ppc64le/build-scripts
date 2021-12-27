# -----------------------------------------------------------------------------
#
# Package		: hoverIntent
# Version		: v1.9.0
# Source repo	: https://github.com/briancherne/jquery-hoverIntent
# Tested on	: ubi 8.5
# Script License: Apache License, Version 2 or later
# Maintainer	: Sapna Shukla <Sapna.Shukla@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

HOME_DIR=`pwd`
PACKAGE_NAME=jquery-hoverIntent
PACKAGE_VERSION=${1:-v1.9.0}
PACKAGE_URL=https://github.com/briancherne/jquery-hoverIntent


OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

yum install git npm -y

#clone the repository
git clone $PACKAGE_URL

export WORK_DIR=$HOME_DIR/$PACKAGE_NAME
cd $WORK_DIR
git checkout $PACKAGE_VERSION

#Only npm install as there are no test for the package.
if ! npm install; then
	echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
	echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
	exit 1

else
	echo "------------------$PACKAGE_NAME:install_success_no_test_available-------------------------"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Install_Success"
	exit 0
fi
