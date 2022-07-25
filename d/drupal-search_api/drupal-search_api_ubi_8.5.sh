#!/bin/bash -e

# ----------------------------------------------------------------------------
# Package          : drupal-search_api
# Version          : 8.x-1.20 ,8.x-1.19
# Source repo      : https://git.drupalcode.org/project/search_api
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
PACKAGE_NAME=search_api
CORE_PACKAGE_NAME=drupal
PACKAGE_URL=https://git.drupalcode.org/project/search_api
CORE_PACKAGE_URL=https://github.com/drupal/drupal
#PACKAGE_VERSION is configurable can be passed as an argument.
PACKAGE_VERSION=${1:-8.x-1.20}


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

if ! composer install --no-interaction; then
     	echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
	exit 1
fi
    composer require 'drupal/language_fallback_fix:^1.0' --no-interaction
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
 
 
if ! ../vendor/bin/phpunit ../modules/search_api/tests/src/Unit/; then
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

# drupal-search_api has 3 types of test cases Functional,Kernel,Unit,FunctionalJavascript . Functional,Kernel,FunctionalJavascript need drupal framework to test. Unit can run without drupal framework setup.
 
# Follow README.md for drupal setup.

#To Run all test cases in one go Functional,Kernel,Unit,FunctionalJavascript.
 
#Checkout 8.x-1.19

        #../vendor/bin/phpunit ../modules/search_api/tests/
        # bash-4.4# ../vendor/bin/phpunit ../modules/search_api/tests/
        # PHPUnit 7.5.20 by Sebastian Bergmann and contributors.

        # Testing ../modules/search_api/tests/
        # ......................S........................................  63 / 480 ( 13%)
        # ............................................................... 126 / 480 ( 26%)
        # ............................................................... 189 / 480 ( 39%)
        # ............................................................... 252 / 480 ( 52%)
        # ............................................................... 315 / 480 ( 65%)
        # ............................................................... 378 / 480 ( 78%)
        # ............................................................... 441 / 480 ( 91%)
        # .......................................                         480 / 480 (100%)

        # Time: 43.44 minutes, Memory: 22.00 MB

        # OK, but incomplete, skipped, or risky tests!
        # Tests: 480, Assertions: 5396, Skipped: 1.


 #Checkout 8.x-1.20 

        # bash-4.4# ../vendor/bin/phpunit ../modules/search_api/tests/
        # PHPUnit 7.5.20 by Sebastian Bergmann and contributors.

        # Testing ../modules/search_api/tests/
        # ......................S........................................  63 / 489 ( 12%)
        # ............................................................... 126 / 489 ( 25%)
        # ............................................................... 189 / 489 ( 38%)
        # ............................................................... 252 / 489 ( 51%)
        # ............................................................... 315 / 489 ( 64%)
        # ............................................................... 378 / 489 ( 77%)
        # ............................................................... 441 / 489 ( 90%)
        # ................................................                489 / 489 (100%)

        # Time: 43.5 minutes, Memory: 22.00 MB

        # OK, but incomplete, skipped, or risky tests!
        # Tests: 489, Assertions: 5509, Skipped: 1.
