#!/bin/bash -e

# ----------------------------------------------------------------------------
# Package          : entity_embed
# Version          : 8.x-1.1
# Source repo      : https://git.drupalcode.org/project/entity_embed.git
# Tested on        : UBI 8.5
# Language         : PHP
# Travis-Check     : False
# Script License   : Apache License, Version 2 or later
# Maintainer       : Ambuj Kumar <Ambuj.Kumar3@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

# Variables
PACKAGE_NAME=entity_embed
CORE_PACKAGE_NAME=drupal
PACKAGE_URL=https://git.drupalcode.org/project/entity_embed.git
CORE_PACKAGE_URL=https://github.com/drupal/drupal
PACKAGE_VERSION=${1:-8.x-1.1}

yum module enable php:7.4 -y
yum install -y git php php-dom php-mbstring zip unzip gd gd-devel php-gd php-pdo php-mysqlnd

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
rm -rf composer.lock
composer config allow-plugins true --no-interaction
composer require --dev phpunit/phpunit --with-all-dependencies ^7 --no-interaction
composer require drupal/embed:*
composer require drupal/entity_browser:*

if ! composer install --no-interaction; then
	echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
	exit 1
fi
cd modules/

if ! git clone $PACKAGE_URL $PACKAGE_NAME; then
	echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails"
	exit 0
fi

cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
cd ../..
cd core/

if ! ../vendor/phpunit/phpunit/phpunit ../modules/entity_embed/tests/src/; then
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

# drupal-entity_embed has 3 types of test Kernel/Functional/FunctionalJavascript. Unit test case is not avialable for this package.
# Please follow README file for more information to run Kernel/Functional/FunctionalJavascript test cases.
