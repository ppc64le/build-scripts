#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : pear/archive_tar
# Version       : 1.4.11, 1.4.12, 1.4.14
# Source repo   : https://github.com/pear/Archive_Tar
# Tested on     : UBI 8.5
# Language      : PHP
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Amit Baheti <aramswar@in.ibm.com>
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
PACKAGE_NAME=Archive_Tar
PACKAGE_VERSION=${1:-1.4.12}
PACKAGE_URL=https://github.com/pear/Archive_Tar.git
if [ ! -z "$1" ]; then
	PACKAGE_VERSION=$1
fi
yum -y update && yum install -y git curl php php-curl php-json php-dom php-mbstring make unzip php-pear
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && php composer-setup.php --install-dir=/bin --filename=composer
OS_NAME=`cat /etc/os-release | grep "PRETTY" | awk -F '=' '{print $2}'`
HOME_DIR=`pwd`
if ! git clone $PACKAGE_URL $PACKAGE_NAME; then
        echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
                echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails"
fi
cd $HOME_DIR/$PACKAGE_NAME
git checkout $PACKAGE_VERSION
if ! pear package; then
        echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
        exit 0
else
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Install_Successful"
fi
cd $HOME_DIR/$PACKAGE_NAME
if ! pear run-tests -r; then
        echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails"
        echo "This package require to be test in non-root mode to pass all test"
        exit 0
else
        echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
        exit 0
fi
