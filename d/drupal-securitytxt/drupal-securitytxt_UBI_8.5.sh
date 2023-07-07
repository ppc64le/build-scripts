#!/bin/bash -e

# ----------------------------------------------------------------------------
# Package          : securitytxt
# Version          : 8.x-1.2, 8.x-1.1
# Source repo      : https://git.drupalcode.org/project/securitytxt
# Tested on        : UBI 8.5
# Language         : PHP
# Travis-Check     : False
# Script License   : Apache License, Version 2 or later
# Maintainer       : Vikas Kumar <kumar.vikas@in.ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

# Variables
PACKAGE_NAME=securitytxt
CORE_PACKAGE_NAME=drupal
PACKAGE_URL=https://git.drupalcode.org/project/securitytxt
CORE_PACKAGE_URL=https://github.com/drupal/drupal
#PACKAGE_VERSION is configurable can be passed as an argument.
PACKAGE_VERSION=${1:-8.x-1.2}


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
  exit 1
fi

cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

cd ../../
cd core/

if ! ../vendor/phpunit/phpunit/phpunit ../modules/$PACKAGE_NAME/tests/; then
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

# drupal-securitytxt has only Functional test cases. Functional, Kernel tests need drupal framework to test. Unit tests can run without drupal framework setup.

# Follow https://github.com/ppc64le/build-scripts/blob/master/d/drupal-securitytxt/README.md link for drupal setup.
​
# To Run all test cases in one go:
​
# cd /opt/app-root/src/drupal/modules
# git clone  https://git.drupalcode.org/project/securitytxt
# cd securitytxt
# git checkout 8.x-1.2

# cd /opt/app-root/src/drupal/core/
# ../vendor/bin/drush pm:enable securitytxt

# ../vendor/phpunit/phpunit/phpunit ../modules/securitytxt/tests

# Output:
# -------
# PHPUnit 7.5.20 by Sebastian Bergmann and contributors.

# Testing ../modules/securitytxt/tests
# ...                                                                 3 / 3 (100%)

# Time: 1.04 minutes, Memory: 4.00 MB

# OK (3 tests, 139 assertions)

# cd /opt/app-root/src/drupal/modules/securitytxt
# git checkout 8.x-1.1

# cd /opt/app-root/src/drupal/core/
# ../vendor/bin/drush pm:enable securitytxt

# ../vendor/phpunit/phpunit/phpunit ../modules/securitytxt/tests

# Output:
# -------
# PHPUnit 7.5.20 by Sebastian Bergmann and contributors.

# Testing ../modules/securitytxt/tests
# ...                                                                 3 / 3 (100%)

# Time: 1.06 minutes, Memory: 4.00 MB

# OK (3 tests, 139 assertions)
