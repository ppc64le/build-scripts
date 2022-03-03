# -----------------------------------------------------------------------------
#
# Package	: sphinx-gallery
# Version	: 0.9.0
# Source repo	: https://github.com/sphinx-gallery/sphinx-gallery
# Tested on	: UBI 8.5
# Language      : Python
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

PACKAGE_NAME=sphinx-gallery
PACKAGE_VERSION=${1:-0.9.0}
PACKAGE_URL=https://github.com/sphinx-gallery/sphinx-gallery

yum -y update && yum install -y python3 python3-devel python3-pytest git gcc

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

HOME_DIR=`pwd`

if ! git clone $PACKAGE_URL $PACKAGE_NAME; then
	echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | Github | Fail |  Clone_Fails"
	exit 1
fi

cd $HOME_DIR/$PACKAGE_NAME
git checkout $PACKAGE_VERSION

if ! python3 setup.py install; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
	echo  "$PACKAGE_URL $PACKAGE_NAME "
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | Github | Fail |  Install_Fails"
	exit 1
fi

cd $HOME_DIR/$PACKAGE_NAME
if ! python3 setup.py test; then
	echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
	echo  "$PACKAGE_URL $PACKAGE_NAME "
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | Github | Fail |  Install_success_but_test_Fails"
	exit 1
else
	echo "------------------$PACKAGE_NAME:install_and_test_both_success-------------------------"
	echo  "$PACKAGE_URL $PACKAGE_NAME "
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | Github | Pass |  Both_Install_and_Test_Success"
	exit 0
fi
