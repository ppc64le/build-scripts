#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: tokenizer
# Version	: v1.2.1
# Source repo	: https://github.com/theseer/tokenizer
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

PACKAGE_NAME=tokenizer
PACKAGE_VERSION=${1:-1.2.1}
PACKAGE_URL=https://github.com/theseer/tokenizer

yum module enable php:7.3 -y
yum install php php-json php-devel php-dom php-mbstring zip unzip php-zip wget git java-11-openjdk-devel -y

php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && php composer-setup.php --install-dir=/bin --filename=composer
composer require --dev phpunit/phpunit --with-all-dependencies ^8

#Install ant
wget https://downloads.apache.org/ant/binaries/apache-ant-1.10.12-bin.tar.gz
tar -xf apache-ant-1.10.12-bin.tar.gz
# Set ANT_HOME variable 
export ANT_HOME=${pwd}/apache-ant-1.10.12
# update the path env. variable 
export PATH=${PATH}:${ANT_HOME}/bin

HOME_DIR=`pwd`

wget "https://phar.io/releases/phive.phar"
chmod +x phive.phar && ./phive.phar install
mv phive.phar /usr/local/bin/phive

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

if ! ant install-tools && ant generate-autoloader ; then
	echo "$PACKAGE_NAME  |  $PACKAGE_VERSION ------------------Build_fails---------------------"
	exit 1
else
	echo "$PACKAGE_NAME  |  $PACKAGE_VERSION ------------------Build_success-------------------------"
	
fi


if ! ant test ; then
	echo "$PACKAGE_NAME  |  $PACKAGE_VERSION ------------------Test_fails---------------------"
	exit 1
else
	echo "$PACKAGE_NAME  |  $PACKAGE_VERSION------------------Test_success-------------------------"
	
fi
