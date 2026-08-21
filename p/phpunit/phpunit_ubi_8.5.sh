#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: phpunit
# Version	: 9.0.0,9.5.4,6.5.14
# Source repo	: https://github.com/sebastianbergmann/phpunit
# Tested on	: UBI 8.5
# Language	: PHP
# Travis-Check	: True
# Script License: Apache License, Version 2 or later
# Maintainer	: Ambuj Kumar <Ambuj.Kumar3@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=phpunit
PACKAGE_VERSION=${1:-9.5.4}
PACKAGE_URL=https://github.com/sebastianbergmann/phpunit

yum update -y

yum module enable php:7.4 -y

yum install php php-json php-devel zip unzip php-zip wget git -y

yum install  php-soap -y

php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && php composer-setup.php --install-dir=/bin --filename=composer

if [ -d $PACKAGE_NAME ] ; then
       	rm -rf $PACKAGE_NAME
  	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Removed existing package if any"

fi
if ! git clone $PACKAGE_URL $PACKAGE_NAME; then
        echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails"
        exit 0
fi

cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

composer install

sed -i '1474d' /etc/php.ini && sed -i '1474izend.assertions = 1' /etc/php.ini

sed -i '1482d' /etc/php.ini && sed -i '1482iassert.exception = 1' /etc/php.ini

./phpunit
