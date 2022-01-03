# ---------------------------------------------------------------------
# 
# Package       : ezyang/htmlpurifier
# Version       : latest tag
# Tested on     : UBI 8.3
# Script License: Apache License, Version 2 or later
# Maintainer    : Raju Sah <Raju.Sah@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------

#!/bin/bash

set -ex

#Variables
REPO=https://github.com/ezyang/htmlpurifier.git
PACKAGE_VERSION=4.12.0

PACKAGE_VERSION="${1:-$PACKAGE_VERSION}"
yum update -y

#install dependencies
yum install -y git php php-gd php-pdo php-dom php-json php-xml php-mbstring
curl -sS http://getcomposer.org/installer | php
php composer.phar 
mv composer.phar /usr/bin/

ln -s /usr/bin/composer.phar /usr/bin/composer
export PATH=/usr/bin/composer:$PATH
composer require ezyang/htmlpurifier

#clone the repo
git clone $REPO
cd htmlpurifier/
#git checkout v$PACKAGE_VERSION
#build and install the repo.

composer require lfarm/sftools dev-master
composer require pear/pear
composer require --dev phpunit/phpunit symfony/test-pack 
composer install

#test
#Note: test cases are failing on both vm power and intel.
./vendor/bin/phpunit tests
