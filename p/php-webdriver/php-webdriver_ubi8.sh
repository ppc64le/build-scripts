#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: php-webdriver
# Version	: 1.4.7
# Source repo	: https://github.com/instaclick/php-webdriver
# Tested on	: UBI 8.5
# Language	: PHP
# Travis-Check	: True
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

PACKAGE_NAME=php-webdriver
PACKAGE_VERSION=${1:-1.4.7}
PACKAGE_URL=https://github.com/instaclick/php-webdriver

yum update -y

yum module enable php:7.4 -y

yum install php php-json php-devel zip unzip php-zip wget git -y

php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && php composer-setup.php --install-dir=/bin --filename=composer

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

composer install --no-interaction

mkdir -p build/logs

./vendor/bin/phpunit --coverage-clover build/logs/clover.xml --group Unit
