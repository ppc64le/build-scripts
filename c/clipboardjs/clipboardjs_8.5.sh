#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package		: clipboardjs
# Version		: 2.0.1
# Source repo	: https://git.drupalcode.org/project/clipboardjs.git
# Tested on		: RHEL 8.5 
#Language       : PHP
# Script License: Apache License, Version 2 or later
# Maintainer	: Saraswati Patra <saraswati.patra@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
PACKAGE_NAME="clipboardjs"
PACKAGE_VERSION=${1:-2.0.1}
PACKAGE_URL="https://git.drupalcode.org/project/clipboardjs.git"
yum install -y git php php-json php-dom php-mbstring php-devel php-pear make zip unzip
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && php composer-setup.php --install-dir=/bin --filename=composer
composer require --dev phpunit/phpunit --with-all-dependencies ^7
phpenv global 7.1 2>/dev/null
pecl install mongodb
echo extension=mongodb.so >> /etc/php.ini
OS_NAME=`cat /etc/os-release | grep PRETTY_NAME | cut -d '=' -f2 | tr -d '"'`
HOME_DIR=`pwd`
if [ -d "$PACKAGE_NAME" ] ; then
  rm -rf $PACKAGE_NAME
  echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Removed existing package if any"
fi
if ! git clone $PACKAGE_URL $PACKAGE_NAME; then
    	echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
		echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails"
    	exit 1
fi
cd $HOME_DIR/$PACKAGE_NAME
git checkout $PACKAGE_VERSION
if ! composer install --ignore-platform-req=ext-zip; then
     	echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
	exit 1
fi

#Build success ,No Test cases available.
