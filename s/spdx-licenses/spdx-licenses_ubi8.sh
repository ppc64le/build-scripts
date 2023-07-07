#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: spdx-licenses
# Version	: 1.5.5
# Source repo	: https://github.com/composer/spdx-licenses
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

PACKAGE_NAME=spdx-licenses
PACKAGE_VERSION=${1:-1.5.5}
PACKAGE_URL=https://github.com/composer/spdx-licenses

yum update -y

yum module enable php:7.4 -y

yum install php php-json php-devel zip unzip php-zip wget git -y

php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && php composer-setup.php --install-dir=/bin --filename=composer

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

composer install --no-interaction --no-progress --prefer-dist --ansi

sed -i '409d' /etc/php.ini && sed -i '409imemory_limit = 500M' /etc/php.ini

./vendor/bin/phpunit --coverage-clover=coverage.xml
