#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: composer-merge-plugin
# Version	: v1.4.0
# Source repo	: https://github.com/wikimedia/composer-merge-plugin
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

PACKAGE_NAME=composer-merge-plugin
PACKAGE_VERSION=${1:-v1.4.0}
PACKAGE_URL=https://github.com/wikimedia/composer-merge-plugin

yum update -y

yum module enable php:7.2 -y

yum install php php-json php-dom git -y

php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && php composer-setup.php --install-dir=/bin --filename=composer

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

composer self-update --1

composer install --prefer-source --no-interaction

./vendor/bin/phpunit
