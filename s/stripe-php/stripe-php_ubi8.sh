#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: stripe-php
# Version	: v7.67.0,v7.100.0 ,v7.78.0
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
PACKAGE_VERSION=${1:-v7.67.0}
PACKAGE_URL=https://github.com/stripe/stripe-php

# Set up the stripe-mock server

STRIPE_MOCK_VERSION=${2:-v0.101.0}

yum install wget gcc gcc-c++ make -y

wget https://golang.org/dl/go1.16.1.linux-ppc64le.tar.gz

tar -C /bin -xf go1.16.1.linux-ppc64le.tar.gz

export PATH=$PATH:/bin/go/bin

go install github.com/stripe/stripe-mock@$STRIPE_MOCK_VERSION

/root/go/bin/stripe-mock &>/dev/null &

# Build and test stripe-php

yum update -y

yum install php php-json php-dom php-xml php-mbstring php-dbg php-cli zip git -y

php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && php composer-setup.php --install-dir=/bin --filename=composer

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

./build.php 0

make fmtcheck

make phpstan

# To run script:- 
# 1 arg is the version of stripe-php and 2nd arg is version of stripe-mock server. 
#    ./stripe-php.sh v7.100.0 v0.123.0
#    ./stripe-php.sh v7.78.0 v0.123.0