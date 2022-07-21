#!/bin/bash -e

# ----------------------------------------------------------------------------
# Package          : drupal-scheduler    
# Version          : 8.x-1.4 ,8.x-1.3
# Source repo      : https://git.drupalcode.org/project/scheduler.git
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
PACKAGE_NAME=scheduler
CORE_PACKAGE_NAME=drupal
PACKAGE_URL=https://git.drupalcode.org/project/scheduler.git
CORE_PACKAGE_URL=https://github.com/drupal/drupal
#PACKAGE_VERSION is configurable can be passed as an argument.
PACKAGE_VERSION=${1:-8.x-1.4}


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
       composer require 'drupal/devel:^4.1'
       composer require 'drupal/rules:^3.0@alpha'


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
 
 
if !  ../vendor/bin/phpunit  ../modules/scheduler/tests/ ; then
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

# drupal-scheduler has 2 types of test cases Functional and FunctionalJavascript . Functional and FunctionalJavascript need drupal framework to test. Unit can run without drupal framework setup.
 
# Please follow README.md file for drupal setup. 

# Version 8.x-1.4 is pass for both build and test, 8.x-1.3 tests are in parity with intel.

# To run all tests in one go :-

# checkout -: 8.x-1.4  

# bash-4.4# ../vendor/bin/phpunit  ../modules/scheduler/tests/
                # PHPUnit 7.5.20 by Sebastian Bergmann and contributors.

                # Testing ../modules/scheduler/tests/
                # ................................................................. 65 / 74 ( 87%)
                # .......SS                                                         74 / 74 (100%)

# Time: 47.85 minutes, Memory: 4.00 MB

                # OK, but incomplete, skipped, or risky tests!
                # Tests: 74, Assertions: 1439, Skipped: 2.

                # Legacy deprecation notices (106)
                # bash-4.4#
         



# Test version  8.x-1.3   ---Pass/Parity 


# bash-4.4# ../vendor/bin/phpunit --filter testRulesEvents ../modules/scheduler/
            # PHPUnit 7.5.20 by Sebastian Bergmann and contributors.

            # Testing ../modules/scheduler/
            # E                                                                   1 / 1 (100%)

            # Time: 17.77 seconds, Memory: 4.00 MB

            # There was 1 error:

            # 1) Drupal\Tests\scheduler\Functional\SchedulerRulesEventsTest::testRulesEvents
            # TypeError: Argument 2 passed to Drupal\rules\Engine\RulesComponent::addContextDefinition() must implement interface Drupal\rules\Context\ContextDefinitionInterface, array given, called in /opt/app-root/src/drupal/modules/contrib/rules/src/Engine/RulesComponent.php on line 176

            # /opt/app-root/src/drupal/modules/contrib/rules/src/Engine/RulesComponent.php:146
            # /opt/app-root/src/drupal/modules/contrib/rules/src/Engine/RulesComponent.php:176
            # /opt/app-root/src/drupal/modules/contrib/rules/src/Entity/ReactionRuleConfig.php:161
            # /opt/app-root/src/drupal/modules/contrib/rules/src/Entity/ReactionRuleConfig.php:268
            # /opt/app-root/src/drupal/core/lib/Drupal/Core/Config/Entity/ConfigEntityBase.php:318
            # /opt/app-root/src/drupal/core/lib/Drupal/Core/Entity/EntityStorageBase.php:499
            # /opt/app-root/src/drupal/core/lib/Drupal/Core/Entity/EntityStorageBase.php:454
            # /opt/app-root/src/drupal/core/lib/Drupal/Core/Config/Entity/ConfigEntityStorage.php:263
            # /opt/app-root/src/drupal/modules/contrib/rules/src/Entity/ReactionRuleStorage.php:118
            # /opt/app-root/src/drupal/core/lib/Drupal/Core/Entity/EntityBase.php:395
            # /opt/app-root/src/drupal/core/lib/Drupal/Core/Config/Entity/ConfigEntityBase.php:616
            # /opt/app-root/src/drupal/modules/scheduler/tests/src/Functional/SchedulerRulesEventsTest.php:72

            # ERRORS!
            # Tests: 1, Assertions: 10, Errors: 1.
                     