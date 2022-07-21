#!/bin/bash -e

# ----------------------------------------------------------------------------
# Package          : drupal-field_encrypt  
# Version          : 8.x-2.0-alpha2
# Source repo      : https://git.drupalcode.org/project/field_encrypt
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
PACKAGE_NAME=field_encrypt
CORE_PACKAGE_NAME=drupal
PACKAGE_URL=https://git.drupalcode.org/project/field_encrypt
CORE_PACKAGE_URL=https://github.com/drupal/drupal
#PACKAGE_VERSION is configurable can be passed as an argument.
PACKAGE_VERSION=${1:-8.x-2.0-alpha2}


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
git checkout 9.0.x

composer config --no-plugins allow-plugins.composer/installers true
composer config --no-plugins allow-plugins.dealerdirect/phpcodesniffer-composer-installer true
composer config --no-plugins allow-plugins.drupal/core-project-message true
composer config --no-plugins allow-plugins.drupal/core-vendor-hardening true

composer update --no-interaction

if ! composer install --no-interaction; then
     	echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
	exit 1
fi

    composer require --dev phpunit/phpunit --with-all-dependencies ^7 --no-interaction
    
# Module required to run funtional test cases.
      composer require drupal/encrypt
      composer require  drupal/key
      #composer require drupal/commerce:^2.1

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
 
 
if ! ../vendor/phpunit/phpunit/phpunit ../modules/field_encrypt/tests/src/Unit/; then
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

# drupal-field_encrypt has 2 types of test cases Functional,Unit. Functional need drupal framework to test. Unit can run without drupal framework setup.
 
# Please follow README.md file for drupal setup.

#To run functional test.

    #Drupal-core 'origin/9.3.x'.  and phpunit 9
 

# bash-4.4#  ../vendor/phpunit/phpunit/phpunit ../modules/field_encrypt/tests/src/Functional/
            # PHPUnit 9.5.21 #StandWithUkraine

            # Warning:       Your XML configuration validates against a deprecated schema.
            # Suggestion:    Migrate your XML configuration using "--migrate-configuration"!

            # Testing /opt/app-root/src/drupal/modules/field_encrypt/tests/src/Functional
            # ......                                                              6 / 6 (100%)

            # Time: 03:45.305, Memory: 6.00 MB

            # OK (6 tests, 270 assertions)
            
#To run unit test.
  
        #drupal core  9.0.x and phpunit 7 fine.


# PHPUnit 7.5.20 by Sebastian Bergmann and contributors.

        # Testing ../modules/field_encrypt/tests/src/Unit/
        # ...........................                                       27 / 27 (100%)

        # Time: 1.72 seconds, Memory: 6.00 MB

        # OK (27 tests, 82 assertions)
        # bash-4.4#