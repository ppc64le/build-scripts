#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: Twig
# Version	: v2.14.7,v2.14.5,v2.12.0,v1.42.5,v1.38.2
# Source repo	: https://github.com/twigphp/Twig
# Tested on	: UBI: 8.5
# Language      : PHP
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Sunidhi Gaonkar<Sunidhi.Gaonkar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=Twig
PACKAGE_VERSION=${1:-v2.14.7}
PACKAGE_URL=https://github.com/twigphp/Twig

yum module enable php:7.3 -y

yum install php php-json php-devel zip unzip php-zip wget git php-pdo php-dom php-mbstring -y

php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && php composer-setup.php --install-dir=/bin --filename=composer
composer require --dev phpunit/phpunit --with-all-dependencies ^8

export SYMFONY_PHPUNIT_REMOVE_RETURN_TYPEHINT=1
export SYMFONY_PHPUNIT_DISABLE_RESULT_CACHE=1

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

if ! composer install ; then
	echo "$PACKAGE_NAME  |  $PACKAGE_VERSION ------------------Build_fails---------------------"
	exit 1
else
	echo "$PACKAGE_NAME  |  $PACKAGE_VERSION ------------------Build_success-------------------------"	
fi

if ! ./vendor/bin/simple-phpunit; then
	echo "$PACKAGE_NAME  |  $PACKAGE_VERSION ------------------Test_fails---------------------"
	exit 1
else
	echo "$PACKAGE_NAME  |  $PACKAGE_VERSION------------------Test_success-------------------------"	
fi

# For all versions, 2 test cases are failing which are in parity with intel.
# There were 2 failures:
# 1) Twig\Tests\Cache\FilesystemTest::testWriteFailMkdir
# Failed asserting that exception of type "RuntimeException" is thrown.
#
# 2) Twig\Tests\Cache\FilesystemTest::testWriteFailDirWritable
# Failed asserting that exception of type "RuntimeException" is thrown.
#
# FAILURES!
# Tests: 1613, Assertions: 4311, Failures: 2, Skipped: 1.