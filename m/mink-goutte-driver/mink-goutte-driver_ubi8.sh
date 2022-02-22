#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: MinkGoutteDriver
# Version	: v2.0.0
# Source repo	: https://github.com/minkphp/MinkGoutteDriver
# Tested on	: UBI 8.5
# Language      : PHP
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Vedang Wartikar <Vedang.Wartikar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=MinkGoutteDriver
PACKAGE_VERSION=v2.0.0
PACKAGE_URL=https://github.com/minkphp/MinkGoutteDriver

yum update -y

yum install php php-devel php-json php-dom php-mbstring php-zip php-gd zip git nc -y

php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && php composer-setup.php --install-dir=/bin --filename=composer

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

composer update --no-interaction --prefer-dist

mkdir ./logs

./vendor/bin/mink-test-server &> ./logs/mink-test-server.log &

while ! nc -z localhost 8002 </dev/null; do echo Waiting for PHP server to start...; sleep 1; done

vendor/bin/phpunit -v --coverage-clover=coverage.clover
