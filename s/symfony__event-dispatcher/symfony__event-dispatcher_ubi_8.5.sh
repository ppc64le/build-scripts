#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: event-dispatcher
# Version	: v4.4.8,v3.4.41,v3.4.15
# Source repo	: https://github.com/symfony/event-dispatcher
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

PACKAGE_NAME=event-dispatcher
PACKAGE_VERSION=${1:-v4.4.8}   
PACKAGE_URL=https://github.com/symfony/event-dispatcher

yum module enable php:7.3 -y

yum install php php-json php-devel zip unzip php-zip wget git php-pdo php-dom php-mbstring -y

php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && php composer-setup.php --install-dir=/bin --filename=composer
composer require --dev phpunit/phpunit --with-all-dependencies ^7

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

if ! composer install ; then
	echo "$PACKAGE_NAME  |  $PACKAGE_VERSION ------------------Build_fails---------------------"
	exit 1
else
	echo "$PACKAGE_NAME  |  $PACKAGE_VERSION ------------------Build_success-------------------------"	
fi

if ! /vendor/bin/phpunit --dont-report-useless-tests ; then
	echo "$PACKAGE_NAME  |  $PACKAGE_VERSION ------------------Test_fails---------------------"
	exit 1
else
	echo "$PACKAGE_NAME  |  $PACKAGE_VERSION------------------Test_success-------------------------"	
fi