#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : site-process
# Version       : 4.1.0
# Source repo   : https://github.com/consolidation/site-process.git
# Tested on     : UBI 8.5
# Language      : PHP
# Travis-Check  : False
# Script License: Apache License, Version 2 or later
# Maintainer    : vathsala . <vaths367@in.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
PACKAGE_NAME=site-process
PACKAGE_VERSION=${1:-4.1.0}
PACKAGE_URL=https://github.com/consolidation/site-process.git
yum install -y git php php-json php-dom php-mbstring php-pdo php-intl zip unzip
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && php composer-setup.php --install-dir=/bin --filename=composer
OS_NAME=`cat /etc/os-release | grep PRETTY_NAME | cut -d '=' -f2 | tr -d '"'`
HOME_DIR=`pwd`
if ! git clone $PACKAGE_URL $PACKAGE_NAME; then
        echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails"
        exit 1
fi
cd $HOME_DIR/$PACKAGE_NAME
git checkout $PACKAGE_VERSION
composer require --dev phpunit/phpunit --with-all-dependencies ^7
if ! composer install; then
        echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
        exit 1
fi
cd $HOME_DIR/$PACKAGE_NAME
if ! vendor/bin/phpunit; then
        echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails"
        exit 1
else
        echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
        exit 0
fi

#Travis job failing with this permission related error..that is why flag has set to False : errorSymfony\Component\Process\Exception\RuntimeException: TTY mode requires /dev/tty to be read/writable.
#.......................S..............S................           55 / 55 (100%)
#Time: 248 ms, Memory: 4.00 MB
#OK, but incomplete, skipped, or risky tests!
#Tests: 55, Assertions: 59, Skipped: 2.
#Build and test success
