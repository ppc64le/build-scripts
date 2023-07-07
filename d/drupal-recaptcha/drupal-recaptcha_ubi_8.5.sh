#!/bin/bash -e

# ----------------------------------------------------------------------------
# Package          : drupal-recaptcha   
# Version          : 8.x-3.0
# Source repo      : https://git.drupalcode.org/project/recaptcha
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
PACKAGE_NAME=recaptcha
CORE_PACKAGE_NAME=drupal
PACKAGE_URL=https://git.drupalcode.org/project/recaptcha
CORE_PACKAGE_URL=https://github.com/drupal/drupal
#PACKAGE_VERSION is configurable can be passed as an argument.
PACKAGE_VERSION=${1:-8.x-3.0}


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
       
       composer require --dev phpunit/phpunit --with-all-dependencies ^7 --no-interaction
       composer require  drupal/captcha

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
 
 
if !  ../vendor/phpunit/phpunit/phpunit ../modules/recaptcha/tests/ ; then
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

# drupal-recaptcha has 1 type of test case that is Functional. Functional need drupal framework to test. Unit can run without drupal framework setup.
 
# Please follow README.md file for drupal setup. 

# Test is parity with intel.

# To run all tests in one go :-

# bash-4.4# ../vendor/phpunit/phpunit/phpunit ../modules/recaptcha/tests/
            # PHPUnit 7.5.20 by Sebastian Bergmann and contributors.

            # Testing ../modules/recaptcha/tests/
            # FFF                                                                 3 / 3 (100%)

            # Time: 52.61 seconds, Memory: 4.00 MB

            # There were 3 failures:

            # 1) Drupal\Tests\recaptcha\Functional\ReCaptchaBasicTest::testReCaptchaAdminAccess
            # Invalid permission <em class="placeholder">administer content types</em>.

            # /opt/app-root/src/drupal/core/modules/user/tests/src/Traits/UserCreationTrait.php:314
            # /opt/app-root/src/drupal/core/modules/user/tests/src/Traits/UserCreationTrait.php:261
            # /opt/app-root/src/drupal/core/modules/user/tests/src/Traits/UserCreationTrait.php:164
            # /opt/app-root/src/drupal/modules/recaptcha/tests/src/Functional/ReCaptchaBasicTest.php:68

            # 2) Drupal\Tests\recaptcha\Functional\ReCaptchaBasicTest::testReCaptchaAdminSettingsForm
            # Invalid permission <em class="placeholder">administer content types</em>.

            # /opt/app-root/src/drupal/core/modules/user/tests/src/Traits/UserCreationTrait.php:314
            # /opt/app-root/src/drupal/core/modules/user/tests/src/Traits/UserCreationTrait.php:261
            # /opt/app-root/src/drupal/core/modules/user/tests/src/Traits/UserCreationTrait.php:164
            # /opt/app-root/src/drupal/modules/recaptcha/tests/src/Functional/ReCaptchaBasicTest.php:68

            # 3) Drupal\Tests\recaptcha\Functional\ReCaptchaBasicTest::testReCaptchaOnLoginForm
            # Invalid permission <em class="placeholder">administer content types</em>.

            # /opt/app-root/src/drupal/core/modules/user/tests/src/Traits/UserCreationTrait.php:314
            # /opt/app-root/src/drupal/core/modules/user/tests/src/Traits/UserCreationTrait.php:261
            # /opt/app-root/src/drupal/core/modules/user/tests/src/Traits/UserCreationTrait.php:164
            # /opt/app-root/src/drupal/modules/recaptcha/tests/src/Functional/ReCaptchaBasicTest.php:68

            # FAILURES!
            # Tests: 3, Assertions: 18, Failures: 3.