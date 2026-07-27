#!/bin/bash -e

# ----------------------------------------------------------------------------
# Package          : minkseleniumdriver
# Version          : v1.5.0
# Source repo      : https://github.com/minkphp/MinkSelenium2Driver.git
# Tested on        : UBI 8.5
# Language         : PHP
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Ankit Paraskar <Ankit.Paraskar@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

# Variables

PACKAGE_NAME=minkseleniumdriver
PACKAGE_URL=https://github.com/minkphp/MinkSelenium2Driver.git
#PACKAGE_VERSION is configurable can be passed as an argument.
PACKAGE_VERSION=v1.5.0


yum install -y git curl php php-curl php-dom php-mbstring php-json php-gd php-pecl-zip
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && php composer-setup.php --install-dir=/bin --filename=composer
php composer-setup.php --install-dir=/usr/local/bin --filename=composer
yum install unzip -y

HOME_DIR=$(pwd)
echo $HOME_DIR

if ! git clone $PACKAGE_URL $PACKAGE_NAME; then
    echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails"
    exit 1
fi



cd "$HOME_DIR"/$PACKAGE_NAME || exit
git checkout $PACKAGE_VERSION
# Install symfony/error-handler on compatible PHP versions to avoid a deprecation warning of the old DebugClassLoader and ErrorHandler classes

curl -sS https://getcomposer.org/installer | php
php composer.phar install
if ! composer install; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
    exit 1
fi


