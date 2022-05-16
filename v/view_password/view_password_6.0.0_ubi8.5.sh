#!/bin/bash -ex
# -----------------------------------------------------------------------------
#
# Package       : drupal/view_password
# Version       : 6.0.0
# Source repo   : https://git.drupalcode.org/project/view_password.git
# Tested on     : UBI 8.5
# Language      : PHP
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Prashant Khoje <prashant.khoje@in.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=view_password
PACKAGE_URL=https://git.drupalcode.org/project/view_password.git
# PACKAGE_VERSION is configurable can be passed as an argument.
PACKAGE_VERSION=${1:-6.0.0}

dnf install -y zip git php php-json php-dom php-gd php-pdo
cd $HOME

php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && php composer-setup.php --install-dir=/bin --filename=composer
rm -f composer-setup.php
git clone --recursive $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

cat > composer.json << EOF
{
    "name": "drupal/view_password",
    "type": "drupal-module",
    "description": "Provides functionality for storing, validating and displaying international postal addresses.",
    "homepage": "http://drupal.org/project/view_password",
    "license": "Apache-2.0",
    "require": {
        "php": "^7.2",
        "drupal/core": "^8.0"
    }
}
EOF

composer install
