#!/bin/bash -e

# ----------------------------------------------------------------------------
# Package          : drupal/graphql 
# Version          : 8.x-3.1
# Source repo      : https://git.drupalcode.org/project/graphql
# Tested on	: UBI: 8.5
# Language      : PHP
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Vishaka Desai <Vishaka.Desai@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=graphql
CORE_PACKAGE_NAME=drupal
PACKAGE_URL=https://git.drupalcode.org/project/graphql
CORE_PACKAGE_URL=https://github.com/drupal/drupal
PACKAGE_VERSION=${1:-8.x-3.1}

yum module enable php:7.3 -y
yum install php php-json php-devel zip unzip php-zip wget git php-pdo php-dom php-mbstring -y
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && php composer-setup.php --install-dir=/bin --filename=composer

rm -rf $CORE_PACKAGE_NAME

if ! git clone $CORE_PACKAGE_URL $CORE_PACKAGE_NAME; then
    	echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
		echo "$CORE_PACKAGE_URL $CORE_PACKAGE_NAME"
        echo "$CORE_PACKAGE_NAME  |  $CORE_PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails"
    	exit 1
fi

cd $CORE_PACKAGE_NAME
git checkout 8.9.0
cd core/modules/
 
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

cd ../../..
composer config allow-plugins true
composer update --ignore-platform-req=ext-gd
cd core/

# functional and kernel test will not run without drupal specific database set up
# running unit test cases, no additional set up required
if ! ../vendor/bin/phpunit modules/$PACKAGE_NAME/tests/src/Unit; then
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