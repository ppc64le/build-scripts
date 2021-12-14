# -----------------------------------------------------------------------------
#
# Package       : tsutils
# Version       : v3.21.0
# Source repo   : https://github.com/ajafff/tsutils
# Tested on     : UBI 8.4
# Script License: Apache License, Version 2 or later
# Maintainer    : Siddhesh Ghadi <Siddhesh.Ghadi@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
# ----------------------------------------------------------------------------

WORD_DIR=`pwd`

PACKAGE_NAME=tsutils
PACKAGE_VERSION=${1:-v3.21.0}
PACKAGE_URL=https://github.com/ajafff/tsutils.git

yum -y update && yum install -y yum-utils nodejs nodejs-devel nodejs-packaging npm python38 python38-devel ncurses git gcc gcc-c++ libffi libffi-devel ncurses git jq make cmake

npm install n -g && n latest && npm install -g npm@latest && export PATH="$PATH" && npm install --global yarn grunt-bump xo testem acorn


OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

if ! git clone $PACKAGE_URL $PACKAGE_NAME; then
    echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails" 

fi

cd $WORD_DIR/$PACKAGE_NAME
git checkout $PACKAGE_VERSION
PACKAGE_VERSION=$(jq -r ".version" package.json)
# run the test command from test.sh
yarn install
if ! npm install; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME" 
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails" 
	exit 0
fi
yarn compile
yarn lint
cd $WORD_DIR/$PACKAGE_NAME
if ! npm test; then
	echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"  
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails" 
	exit 0
else
	echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME" 
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success" 
	exit 0
fi