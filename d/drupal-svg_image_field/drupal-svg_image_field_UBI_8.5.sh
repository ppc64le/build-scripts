#!/bin/bash -e

# ----------------------------------------------------------------------------
# Package          : svg_image_field
# Version          : 2.1.0
# Source repo      : https://git.drupalcode.org/project/svg_image_field
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
PACKAGE_NAME=svg_image_field
CORE_PACKAGE_NAME=drupal
PACKAGE_URL=https://git.drupalcode.org/project/svg_image_field
CORE_PACKAGE_URL=https://github.com/drupal/drupal
#PACKAGE_VERSION is configurable can be passed as an argument.
PACKAGE_VERSION=${1:-2.1.0}


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
composer config --no-plugins allow-plugins.composer/installers true
composer config --no-plugins allow-plugins.dealerdirect/phpcodesniffer-composer-installer true
composer config --no-plugins allow-plugins.drupal/core-project-message true
composer config --no-plugins allow-plugins.drupal/core-vendor-hardening true

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

# Test failures in parity with Intel
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
# drupal-svg_image_field has only Functional test cases. Functional, Kernel tests need drupal framework to test. Unit tests can run without drupal framework setup.

# Follow https://github.com/ppc64le/build-scripts/blob/master/d/drupal-svg_image_field/README.md link for drupal setup.
​
# To Run all test cases in one go:
​
# cd /opt/app-root/src/drupal/modules
# git clone  https://git.drupalcode.org/project/svg_image_field
# cd svg_image_field
# git checkout 2.1.0

# cd /opt/app-root/src/drupal
# composer config --no-plugins allow-plugins.composer/installers true
# composer config --no-plugins allow-plugins.drupal/core-project-message true
# composer config --no-plugins allow-plugins.drupal/core-vendor-hardening true
# composer require enshrined/svg-sanitize

# cd /opt/app-root/src/drupal/core/
# ../vendor/bin/drush pm:enable svg_image_field

# ../vendor/phpunit/phpunit/phpunit ../modules/svg_image_field/tests

# Output:
# -------
# PHPUnit 7.5.20 by Sebastian Bergmann and contributors.

# Testing ../modules/svg_image_field/tests
# F                                                                   1 / 1 (100%)

# Time: 4.88 seconds, Memory: 4.00 MB

# There was 1 failure:

# 1) Drupal\Tests\svg_image_field\Unit\FileValidationTest::testFileValidation
# Check that <em class="placeholder">invalid_svg1.svg</em> is invalid
# Failed asserting that false matches expected true.

# /opt/app-root/src/drupal/modules/svg_image_field/tests/src/Unit/FileValidationTest.php:85

# FAILURES!
# Tests: 1, Assertions: 6, Failures: 1.
