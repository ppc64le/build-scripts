#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : drupal/droxy
# Version       : 2.0.1, 2.0.0
# Source repo   : https://git.drupalcode.org/project/droxy.git
# Tested on     : UBI: 8.5
# Language      : PHP
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Sachin Kakatkar<Sachin.Kakatkar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#Run the sript ./drupal_droxy_ubi_8.5.sh 2.0.1(version to test)
PACKAGE_NAME=droxy
PACKAGE_VERSION=${1:-2.0.1}
PACKAGE_URL=https://git.drupalcode.org/project/droxy.git

yum module enable php:7.3 -y
yum install php php-json php-devel zip unzip php-zip wget git php-pdo php-dom php-mbstring -y

php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && php composer-setup.php --install-dir=/bin --filename=composer

rm -rf drupal
git clone https://github.com/drupal/drupal.git
cd drupal
git checkout 8.9.0
cd core/modules

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
cd ../../..
composer config allow-plugins true

if ! composer update --ignore-platform-req=ext-gd ; then
        echo "$PACKAGE_NAME  |  $PACKAGE_VERSION ------------------Build_fails---------------------"
        exit 1
else
        echo "$PACKAGE_NAME  |  $PACKAGE_VERSION ------------------Build_success-------------------------"
fi
#cd core
#if ! ../vendor/bin/phpunit modules/droxy/tests/src/Unit ; then
#        echo "$PACKAGE_NAME  |  $PACKAGE_VERSION ------------------Test_fails---------------------"
#        exit 1
#else
        echo "$PACKAGE_NAME  |  $PACKAGE_VERSION------------------Test_NA-------------------------"
#fi

#Test not available


