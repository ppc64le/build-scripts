#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: php-encryption
# Version	: v2.2.1
# Source repo	: https://github.com/defuse/php-encryption
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

PACKAGE_NAME=php-encryption
PACKAGE_VERSION=${1:-v2.2.1}
PACKAGE_URL=https://github.com/defuse/php-encryption

yum update -y

yum module enable php:7.4 -y

yum install php php-json php-devel zip unzip php-zip wget git -y

php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && php composer-setup.php --install-dir=/bin --filename=composer

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

composer install

sed -i '23d' test.sh && sed -i '23i./test/phpunit.sh "$BOOTSTRAP"' test.sh

./test.sh
