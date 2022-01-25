# -----------------------------------------------------------------------------
#
# Package	: isomorphic-form-data
# Version	: v2.0.0
# Source repo	: https://github.com/form-data/isomorphic-form-data
# Tested on	: UBI 8.5
# Language      : Node
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Atharv Phadnis <Atharv.Phadnis@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=isomorphic-form-data
PACKAGE_VERSION=${1:-v2.0.0}
PACKAGE_URL=https://github.com/form-data/isomorphic-form-data

yum install -y nodejs npm git

npm install n -g && n latest && npm install -g npm@latest

HOME_DIR=`pwd`

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

if ! git clone $PACKAGE_URL $PACKAGE_NAME; then
	echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails"
	exit 0
fi

cd $HOME_DIR/$PACKAGE_NAME
git checkout $PACKAGE_VERSION

# Only Installation as no Test cases present
if ! npm install; then
	echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
	exit 0
else
	echo "------------------$PACKAGE_NAME:install_success-------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Pass |  Install_Success"
	exit 0
fi
