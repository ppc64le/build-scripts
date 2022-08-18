#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: MinkGoutteDriver
# Version	: v1.2.1
# Source repo	: https://github.com/minkphp/MinkGoutteDriver
# Tested on	: UBI 8.6
# Language      : PHP
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Siddesh Sangodkar <siddesh.sangodkar1@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=MinkGoutteDriver
PACKAGE_VERSION=v1.2.1
PACKAGE_URL=https://github.com/minkphp/MinkGoutteDriver

yum update -y
yum module enable php:7.4 -y
yum install php php-devel php-json php-dom php-mbstring php-zip php-gd zip git nc gd gd-devel php-gd php-pdo php-mysqlnd php-xdebug -y



#Install MinkGoutteDriver
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
curl -sS https://getcomposer.org/installer | php
php composer.phar require fabpot/goutte '~2' --no-update  --no-interaction 
php composer.phar require behat/mink '1.6' --no-update  --no-interaction 
php composer.phar require behat/mink-browserkit-driver '1.2' --no-update  --no-interaction 
php composer.phar require phpunit/phpunit '5.7' --no-update  --no-interaction 
php composer.phar require symfony/phpunit-bridge '2.7' --no-update  --no-interaction 
php composer.phar install --no-interaction
php composer.phar update --no-interaction --prefer-dist

#Run tests
php -S localhost:8002  -t vendor/behat/mink/driver-testsuite/web-fixtures > /dev/null 2>&1 &
while ! nc -z localhost 8002 </dev/null; do echo Waiting for PHP server to start...; sleep 1; done
export WEB_FIXTURES_HOST=http://localhost:8002
vendor/bin/phpunit --coverage-clover=coverage.clover
