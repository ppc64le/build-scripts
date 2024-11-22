# -----------------------------------------------------------------------------
#
# Package       : htmlpurifier
# Version       : v4.14.0 v4.7.0
# Source repo   : https://github.com/ezyang/htmlpurifier.git
# Tested on     : UBI 8.3 UBI 8.5
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
# ------------------------------------------------------------------------------

#!/bin/bash

set -e

PACKAGE_NAME=htmlpurifier
PACKAGE_VERSION=${1:-4.14.0}
PACKAGE_URL=https://github.com/ezyang/htmlpurifier.git

#install dependencies
yum install -y git unzip php php-gd php-pdo php-dom php-json php-xml php-mbstring
curl -sS http://getcomposer.org/installer | php
php composer.phar
mv composer.phar /usr/bin/

ln -s /usr/bin/composer.phar /usr/bin/composer
export PATH=/usr/bin/composer:$PATH
composer require ezyang/htmlpurifier

#clone the repo
git clone $PACKAGE_URL
cd $PACKAGE_NAME/
git checkout v$PACKAGE_VERSION

#build and install the repo.

composer require lfarm/sftools dev-master
composer require --dev phpunit/phpunit
composer install

#test
#Note: test cases are failing on both VMs power and intel.
./vendor/bin/phpunit tests
