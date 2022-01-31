#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: stripe-php
# Version	: v7.25.0
# Source repo	: https://github.com/stripe/stripe-php
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

PACKAGE_NAME=stripe-php
PACKAGE_VERSION=${1:-v7.25.0}
PACKAGE_URL=https://github.com/stripe/stripe-php

yum update -y

yum module enable php:7.3 -y

yum install php php-json php-dom php-xml php-mbstring php-dbg php-cli php-xdebug zip git make -y

php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && php composer-setup.php --install-dir=/bin --filename=composer

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

./build.php 0

make fmtcheck
