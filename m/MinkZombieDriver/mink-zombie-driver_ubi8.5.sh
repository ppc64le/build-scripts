#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: MinkZombieDriver
# Version	: master, v1.5.0
# Source repo	: https://github.com/minkphp/MinkZombieDriver
# Tested on	: UBI 8.5
# Language      : PHP
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Anup Kodlekere <Anup.Kodlekere@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

# Script installs master version as default. 
# To install v1.5.0, use as follows:
# ./<script.sh> v1.5.0

PACKAGE_NAME=MinkZombieDriver
PACKAGE_VERSION=${1:-master}
PACKAGE_URL=https://github.com/minkphp/MinkZombieDriver

# enable and install dependencies
yum module enable php:7.4 -y
yum module enable nodejs:16 -y
yum install -y php php-json php-zip php-dom php-mbstring php-dbg php-gd
yum install -y git python38 nodejs npm

# download package
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

# install composer
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" 
php composer-setup.php --install-dir=/bin --filename=composer

if [[ "$PACKAGE_VERSION" == v1.5.0 ]]; then
	composer require --no-update --dev symfony/error-handler "^4.4 || ^5.0"
fi

# install php dependencies
composer update --no-interaction --prefer-dist

# install zombie package
npm install zombie@^5.0

# make logging directory
mkdir logs

export MINK_HOST='127.0.0.1:8002'

# start test server
./vendor/bin/mink-test-server &> ./logs/mink-test-server.log &

# run tests
if vendor/bin/phpunit -v; then
	echo "$PACKAGE_NAME@$PACKAGE_VERSION successful"
fi