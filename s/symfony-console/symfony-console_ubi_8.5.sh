#!/bin/bash -e

# ----------------------------------------------------------------------------
# Package          : symfony-console
# Version          : v4.4.14,v4.4.26,v5.1.8,v5.1.11
# Source repo      : https://github.com/symfony/console
# Tested on        : UBI 8.5
# Language         : PHP
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Bhagat Singh <Bhagat.singh1@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#   
# ----------------------------------------------------------------------------

# Variables
PACKAGE_NAME=console
PACKAGE_URL=https://github.com/symfony/console
#PACKAGE_VERSION is configurable can be passed as an argument.
PACKAGE_VERSION=${1:-v4.4.14}

yum module enable php:7.4 -y
yum install -y git curl php php-curl php-dom php-mbstring php-json php-gd php-pecl-zip
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && php composer-setup.php --install-dir=/bin --filename=composer

HOME_DIR=$(pwd)
if ! git clone $PACKAGE_URL $PACKAGE_NAME; then
    echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails"
    exit 1
fi

cd "$HOME_DIR"/$PACKAGE_NAME || exit
git checkout "$PACKAGE_VERSION"

composer require symfony/phpunit-bridge
composer require --dev phpunit/phpunit --with-all-dependencies ^9

if ! composer install; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
    exit 1
fi

cd "$HOME_DIR"/$PACKAGE_NAME || exit
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
