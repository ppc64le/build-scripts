#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: svg-sanitizer
# Version	: v0.14.1
# Source repo	: https://github.com/darylldoyle/svg-sanitizer
# Tested on	: UBI: 8.5
# Language      : PHP
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Sunidhi Gaonkar<Sunidhi.Gaonkar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=svg-sanitizer
PACKAGE_VERSION=${1:-0.14.1}
PACKAGE_URL=https://github.com/darylldoyle/svg-sanitizer

yum update -y

yum module enable php:7.4 -y

yum install php php-json php-devel zip unzip php-zip wget git -y

php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && php composer-setup.php --install-dir=/bin --filename=composer

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION


if ! composer install --prefer-dist --no-progress; then
	echo "------------------Build_fails---------------------"
	exit 1
else
	echo "------------------Build_success-------------------------"
	
fi


if ! composer run-script test; then
	echo "------------------Test_fails---------------------"
	exit 1
else
	echo "------------------Test_success-------------------------"
	
fi


