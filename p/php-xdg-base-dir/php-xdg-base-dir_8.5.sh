#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: php-xdg-base-dir
# Version	: 0.1
# Source repo	: https://github.com/dnoegel/php-xdg-base-dir.git
# Tested on	: UBI 8.5
# Language	: PHP
# Travis-Check	: True
# Script License: Apache License, Version 2 or later
# Maintainer	: Saraswati patra <saraswati patra@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=php-xdg-base-dir
PACKAGE_VERSION=${1:-0.1}
PACKAGE_URL=https://github.com/dnoegel/php-xdg-base-dir.git

yum install -y git curl php php-curl php-dom php-mbstring php-json php-gd php-pecl-zip
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && php composer-setup.php --install-dir=/bin --filename=composer
HOME_DIR=$(pwd)

#Check if package exists
if [ -d "$PACKAGE_NAME" ] ; then
  rm -rf $PACKAGE_NAME
  echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Removed existing package if any"
fi
if ! git clone $PACKAGE_URL $PACKAGE_NAME; then
    echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails"
    exit 1
fi
cd "$HOME_DIR"/$PACKAGE_NAME || exit
git checkout "$PACKAGE_VERSION"
# Install symfony/error-handler on compatible PHP versions to avoid a deprecation warning of the old DebugClassLoader and ErrorHandler classes
composer require --no-update --dev symfony/error-handler "^4.4 || ^5.0"
composer require --dev phpunit/phpunit --with-all-dependencies ^8

if ! composer install; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
    exit 1
fi
#build success and test in parity with intel
#Test Failed with below error
#1 Failure case
# XdgTest::testGetRuntimeShouldDeleteDirsWithWrongPermission
#Failed asserting that '744' matches expected 764

cd "$HOME_DIR"/$PACKAGE_NAME || exit 1
if ! ./vendor/bin/phpunit; then
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
