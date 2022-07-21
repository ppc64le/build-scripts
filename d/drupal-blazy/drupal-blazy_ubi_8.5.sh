#!/bin/bash -e

# ----------------------------------------------------------------------------
# Package          : drupal-blazy 
# Version          : 8.x-2.5 , 8.x-2.2
# Source repo      : https://git.drupalcode.org/project/blazy
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
PACKAGE_NAME=blazy
CORE_PACKAGE_NAME=drupal
PACKAGE_URL=https://git.drupalcode.org/project/blazy
CORE_PACKAGE_URL=https://github.com/drupal/drupal
#PACKAGE_VERSION is configurable can be passed as an argument.
PACKAGE_VERSION=${1:-8.x-2.5}


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
    	exit 1
fi

cd $CORE_PACKAGE_NAME
git checkout 8.9.0

composer config --no-plugins allow-plugins.composer/installers true
composer config --no-plugins allow-plugins.dealerdirect/phpcodesniffer-composer-installer true
composer config --no-plugins allow-plugins.drupal/core-project-message true
composer config --no-plugins allow-plugins.drupal/core-vendor-hardening true

composer update --no-interaction
# Needed for drupal 9.3.x
# composer require --dev phpspec/prophecy-phpunit:^2


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
    	exit 1
fi

cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

cd ../../
cd core/
 
# To run success with non zero status code use drupal 8.9.0 and phpunit 7 for Unit test.
# For other test cases drupal 9.3.x and phpunit 9 is needed. 
if ! ../vendor/phpunit/phpunit/phpunit ../modules/blazy/tests/src/Unit/; then
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

# drupal-blazy has 3 types of test cases Unit,FunctionalJavascript,Kernel. FunctionalJavascript,Kernel need drupal framework to test.
# Unit tests can run without drupal setup.
  
# Follow README.md for drupal setup.

#To Run all test cases in one go FunctionalJavascript,Kernel.
 
#Checkout 8.x-2.5
# bash-4.4# ../vendor/phpunit/phpunit/phpunit ../modules/blazy/tests/src/
            # PHPUnit 9.5.21 #StandWithUkraine

            # Warning:       Your XML configuration validates against a deprecated schema.
            # Suggestion:    Migrate your XML configuration using "--migrate-configuration"!

            # Testing /opt/app-root/src/drupal/modules/blazy/tests/src
            # SSS..............................................                 49 / 49 (100%)

            # Time: 03:57.545, Memory: 12.00 MB

            # OK, but incomplete, skipped, or risky tests!
            # Tests: 49, Assertions: 441, Skipped: 3
