#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: phpunit
# Version	: 9.0.0, 9.5.10
# Source repo	: https://github.com/sebastianbergmann/phpunit
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

PACKAGE_NAME=phpunit
PACKAGE_VERSION=${1:-9.0.0}
PACKAGE_URL=https://github.com/sebastianbergmann/phpunit

yum update -y

yum module enable php:7.4 -y

yum install php php-json php-devel zip unzip php-zip wget git -y

yum install php-xdebug php-soap -y

php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && php composer-setup.php --install-dir=/bin --filename=composer

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

composer install

sed -i '1474d' /etc/php.ini && sed -i '1474izend.assertions = 1' /etc/php.ini

sed -i '1482d' /etc/php.ini && sed -i '1482iassert.exception = 1' /etc/php.ini

./phpunit
