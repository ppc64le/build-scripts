#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : symfony/console
# Version       : v5.2.3, v5.2.0, v5.1.10, v5.1.9, v5.0.7, v4.4.8, v4.4.23, v4.4.20, v4.4.18, v3.4.41, v3.4.15, v2.8.52, 4.4
# Source repo   : https://github.com/symfony/console.git
# Tested on     : UBI 8.5
# Language      : PHP
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Amit Mukati <amit.mukati3@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME="console"
PACKAGE_VERSION=${1:-v5.2.3}
PACKAGE_URL="https://github.com/symfony/console.git"
yum module enable php:7.3 -y
yum install -y git php php-curl php-dom php-mbstring php-json php-gd php-pecl-zip zip php-process
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && php composer-setup.php --install-dir=/bin --filename=composer
OS_NAME=`cat /etc/os-release | grep PRETTY_NAME | cut -d '=' -f2 | tr -d '"'`
HOME_DIR=`pwd`

#Check if package exists
if [ -d "$PACKAGE_NAME" ] ; then
  rm -rf $PACKAGE_NAME
  echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Removed existing package if any"
fi

if ! git clone $PACKAGE_URL $PACKAGE_NAME; then
    echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails"
    exit 0
fi
cd "$HOME_DIR"/$PACKAGE_NAME || exit 1
git checkout "$PACKAGE_VERSION"
if [[ $PACKAGE_VERSION == v5.1.3 ]] || [[ $PACKAGE_VERSION == v5.0.7 ]] || [[ $PACKAGE_VERSION == v4.4.8 ]] || [[ $PACKAGE_VERSION == v3.4.41 ]] || [[ $PACKAGE_VERSION == v3.4.15 ]] || [[ $PACKAGE_VERSION == v2.8.52 ]]; then
        composer require --dev phpunit/phpunit --with-all-dependencies ^7
else
        composer require --dev phpunit/phpunit --with-all-dependencies ^9.5
fi
composer require --dev symfony/phpunit-bridge --with-all-dependencies
export SYMFONY_DEPRECATIONS_HELPER=disabled
if ! composer install; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
    exit 1
fi

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

