#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : php-htmldiff
# Version       : v0.1.12
# Source repo   : https://github.com/caxy/php-htmldiff.git
# Tested on     : UBI 8.5
# Language      : PHP
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Raju.Sah@ibm.com
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#   
# ----------------------------------------------------------------------------

PACKAGE_NAME=php-htmldiff
PACKAGE_VERSION=${1:-v0.1.12}
PACKAGE_URL=https://github.com/caxy/php-htmldiff.git

yum module enable php:7.4 -y
yum install php php-json php-devel zip git -y
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && php composer-setup.php --install-dir=/bin --filename=composer
php -v

#clone the package
git clone $PACKAGE_URL
cd $PACKAGE_NAME/
git checkout $PACKAGE_VERSION

#Build and test the package.
composer install
./vendor/bin/phpunit
