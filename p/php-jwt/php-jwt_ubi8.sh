#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: php-jwt
# Version	: v5.2.0
# Source repo	: https://github.com/firebase/php-jwt
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

PACKAGE_NAME=php-jwt
PACKAGE_VERSION=${1:-v5.2.0}
PACKAGE_URL=https://github.com/firebase/php-jwt

yum update -y

yum module enable php:7.4 -y

yum install php php-json php-devel zip git -y

php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && php composer-setup.php --install-dir=/bin --filename=composer

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

composer install

composer require friendsofphp/php-cs-fixer && vendor/bin/php-cs-fixer fix --diff --dry-run . &&  vendor/bin/php-cs-fixer fix --rules=native_function_invocation --allow-risky=yes --diff src;

vendor/bin/phpunit
