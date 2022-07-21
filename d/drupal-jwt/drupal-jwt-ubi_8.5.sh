#!/bin/bash -e

# ----------------------------------------------------------------------------
# Package          : drupal-jwt
# Version          : 8.x-1.0-beta5 ,8.x-1.0-rc1
# Source repo      : https://git.drupalcode.org/project/jwt
# Tested on        : UBI 8.5
# Language         : PHP
# Travis-Check     : False
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
PACKAGE_NAME=jwt
CORE_PACKAGE_NAME=drupal
PACKAGE_URL=https://git.drupalcode.org/project/jwt
CORE_PACKAGE_URL=https://github.com/drupal/drupal
#PACKAGE_VERSION is configurable can be passed as an argument.
PACKAGE_VERSION=${1:-8.x-1.0-rc1}


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
    composer require 'drupal/key'
    composer require drupal/jwt
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

# Version 8.x-1.0-beta5 is in parity with intel.
# Behat\Mink\Exception\ExpectationException: Current response status code is 403, but 200 expected.

#8.x-1.0-rc1 is pass for tests execution.

if ! ../vendor/phpunit/phpunit/phpunit ../modules/jwt/tests/; then
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

# drupal-jwt has 2 types of test cases Functional,Kernel. Functional,Kernel need drupal framework to test.
# Unit tests can run without drupal setup.
  
# Follow README.md for drupal setup.

#To Run all test cases in one go Functional,Kernel.
 
#Checkout 8.x-1.0-rc1
# bash-4.4#  ../vendor/phpunit/phpunit/phpunit ../modules/jwt/tests/
            # PHPUnit 7.5.20 by Sebastian Bergmann and contributors.

            # Testing ../modules/jwt/tests/
            # .......                                                             7 / 7 (100%)

            # Time: 1.12 minutes, Memory: 4.00 MB

            # OK (7 tests, 133 assertions)
            

# Checkout 8.x-1.0-beta5  :-  Version 8.x-1.0-beta5 is in parity with intel.

# bash-4.4#     ../vendor/bin/phpunit ../modules/jwt/tests
                # PHPUnit 7.5.20 by Sebastian Bergmann and contributors.

                # Testing ../modules/jwt/tests
                # E......                                                             7 / 7 (100%)

                # Time: 1.05 minutes, Memory: 4.00 MB

                # There was 1 error:

                # 1) Drupal\Tests\jwt\Functional\JwtAuthTest::testJwtAuth
                # Behat\Mink\Exception\ExpectationException: Current response status code is 403, but 200 expected.

                # /opt/app-root/src/drupal/vendor/behat/mink/src/WebAssert.php:768
                # /opt/app-root/src/drupal/vendor/behat/mink/src/WebAssert.php:130
                # /opt/app-root/src/drupal/modules/contrib/jwt/tests/src/Functional/JwtAuthTest.php:93

                # ERRORS!
                # Tests: 7, Assertions: 117, Errors: 1.