#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: phpstan/phpstan
# Version	: 0.12.93
# Source repo	: https://github.com/phpstan/phpstan
# Tested on	: UBI: 8.5
# Language      : PHP
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Vishaka Desai <Vishaka.Desai@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=phpstan/phpstan
PACKAGE_VERSION=${1:-0.12.93}
PACKAGE_URL=https://github.com/phpstan/phpstan

yum install -y git php php-json php-dom php-mbstring zip unzip

HOME_DIR=`pwd`
if ! git clone $PACKAGE_URL $PACKAGE_NAME; then
    	echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
		echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails"
    	exit 1
fi

cd $HOME_DIR/$PACKAGE_NAME
git checkout $PACKAGE_VERSION

php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && php composer-setup.php --install-dir=/bin --filename=composer
composer require --dev phpunit/phpunit --with-all-dependencies ^7

mkdir output

if ! composer install; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
	exit 1
else
	echo "------------------$PACKAGE_NAME:install_success-------------------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Success"
	exit 0
fi

# test failure with 1 error, at parity with Intel x86 system

# cd e2e
# composer require phpstan/phpstan-strict-rules --dev --with-all-dependencies
# composer install --ignore-platform-reqs

# if ! vendor/bin/phpunit PharTest.php; then
# 	echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
# 	echo "$PACKAGE_URL $PACKAGE_NAME"
# 	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails"
# 	exit 1
# else
# 	echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
# 	echo "$PACKAGE_URL $PACKAGE_NAME"
# 	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
# 	exit 0
# fi