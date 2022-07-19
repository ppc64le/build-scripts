#!/bin/bash -e
# ----------------------------------------------------------------------------
# Package          : video_embed_field
# Version          : 8.x-2.4
# Source repo      : https://git.drupalcode.org/project/video_embed_field.git
# Tested on        : UBI 8.5
# Language         : PHP
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Saraswati Patra <saraswati.patra@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#   
# ----------------------------------------------------------------------------
# Variables
PACKAGE_NAME=video_embed_field
CORE_PACKAGE_NAME=drupal
PACKAGE_URL=https://git.drupalcode.org/project/video_embed_field.git
CORE_PACKAGE_URL=https://github.com/drupal/drupal
#PACKAGE_VERSION is configurable can be passed as an argument.
PACKAGE_VERSION=${1:-8.x-2.4}

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
composer config allow-plugins true
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
if ! ../vendor/bin/phpunit ../modules/video_embed_field/tests/src/Unit; then
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
#video_embed_field has 4 types of test cases Unit/Functional/FunctionalJavascript/Kernel.Unit test don't need drupal framework and DB etc. So can be executed by given script.
# Please follow README file for more information to run FunctionalJavascript/Functional/Kernel test cases.and make the script travis-check false for Functional/FunctionalJavascript/Kernel test.
#bash-4.4# ../vendor/bin/phpunit ../modules/video_embed_field/tests/src/Unit
#PHPUnit 7.5.20 by Sebastian Bergmann and contributors.

#Testing ../modules/video_embed_field/tests/src/Unit
#....................................................              52 / 52 (100%)

#Time: 854 ms, Memory: 4.00 MB

#OK (52 tests, 53 assertions)
#====
#note:for Functional/FunctionalJavascript/Kernel test cases required below modules drupal/colorbox,drupal/colorbox_library_test
#execute command under drupal
#cd /opt/app-root/src/drupal
#composer require drupal/colorbox
#composer require drupal/picture
#testoutput:
#=================
#bash-4.4# ../vendor/bin/phpunit ../modules/video_embed_field/tests
#PHPUnit 7.5.20 by Sebastian Bergmann and contributors.

#Testing ../modules/video_embed_field/tests
#.....SS.......................................................... 65 / 91 ( 71%)
#..........................                                        91 / 91 (100%)

#Time: 7.11 minutes, Memory: 4.00 MB

#OK, but incomplete, skipped, or risky tests!
#Tests: 91, Assertions: 314, Skipped: 2.