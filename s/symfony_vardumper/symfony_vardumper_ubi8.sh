#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: symfony_vardumper
# Version	: v4.4.7
# Source repo	: https://github.com/symfony/symfony
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

PACKAGE_NAME=symfony_vardumper
PACKAGE_VERSION=${1:-v4.4.7}
PACKAGE_URL=https://github.com/symfony/symfony

yum module enable php:7.3 -y

yum install git php php-devel php-zip zip php-pdo php-xml php-mbstring php-json -y

php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && php composer-setup.php --install-dir=/bin --filename=composer

git clone $PACKAGE_URL $PACKAGE_NAME
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

composer require symfony/contracts:v4.4.0

composer update

cd src/Symfony/Component/

cd VarDumper/

composer install

../../../.././phpunit --exclude-group tty,benchmark,intl-data
