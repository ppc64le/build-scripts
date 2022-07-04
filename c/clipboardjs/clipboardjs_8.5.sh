#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: clipboardjs
# Version	: 2.0.1
# Source repo	: https://git.drupalcode.org/project/clipboardjs.git
# Tested on	: RHEL 8.5 
#Travis-Check   : True
#Language       : PHP
# Script License: Apache License, Version 2 or later
# Maintainer	: Saraswati Patra <saraswati.patra@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
# Variables
PACKAGE_NAME=clipboardjs
CORE_PACKAGE_NAME=drupal
PACKAGE_URL=https://git.drupalcode.org/project/clipboardjs.git
CORE_PACKAGE_URL=https://github.com/drupal/drupal
#PACKAGE_VERSION is configurable can be passed as an argument.
PACKAGE_VERSION=${1:-2.0.1}

yum module enable php:7.4 -y
yum install -y git php php-json php-dom php-mbstring zip unzip gd gd-devel php-gd php-pdo php-mysqlnd
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && php composer-setup.php --install-dir=/bin --filename=composer

OS_NAME=`cat /etc/os-release | grep PRETTY_NAME | cut -d '=' -f2 | tr -d '"'`

#Check if package exists
if [ -d "$CORE_PACKAGE_NAME" ] ; then
  rm -rf $CORE_PACKAGE_NAME
  echo "$CORE_PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Removed existing package if any"

fi

if ! git clone $CORE_PACKAGE_URL $CORE_PACKAGE_NAME; then
        echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
                echo "$CORE_PACKAGE_URL $CORE_PACKAGE_NAME"
        echo "$CORE_PACKAGE_NAME  |  $CORE_PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails"
        exit 0
fi

cd $CORE_PACKAGE_NAME
git checkout 8.9.0
composer update --no-interaction

if ! composer install --no-interaction; then
        echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
        exit 1
fi

    composer require --dev phpunit/phpunit --with-all-dependencies ^7 --no-interaction

    cd modules/

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

cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
cd ../../
cd core/
if ! composer update --ignore-platform-req=ext-gd ; then
        echo "$PACKAGE_NAME  |  $PACKAGE_VERSION ------------------Build_fails---------------------"
        exit 1
else
        echo "$PACKAGE_NAME  |  $PACKAGE_VERSION ------------------Build_success-------------------------"
		exit 0
fi
#Build pass test cases not available.
#Generating autoload files
#> Drupal\Core\Composer\Composer::preAutoloadDump
#> Drupal\Core\Composer\Composer::ensureHtaccess
#38 packages you are using are looking for funding.
#Use the `composer fund` command to find out more!
#clipboardjs  |  2.0.1 ------------------Build_success-------------------------



