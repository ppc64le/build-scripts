#!/bin/bash -e

# ----------------------------------------------------------------------------
# Package          : page_manager
# Version          : 8.x-4.0-beta6
# Source repo      : https://git.drupalcode.org/project/page_manager
# Tested on        : UBI 8.5
# Language         : PHP
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Ankit Paraskar <Ankit.Paraskar@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

# Variables
PACKAGE_NAME=rules
CORE_PACKAGE_NAME=drupal
PACKAGE_URL=https://git.drupalcode.org/project/page_manager

#PACKAGE_VERSION is configurable can be passed as an argument.
PACKAGE_VERSION=8.x-4.0-beta6


yum module enable php:7.4 -y
yum install -y git php php-json php-dom php-mbstring zip unzip gd gd-devel php-gd php-pdo php-mysqlnd
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && php composer-setup.php --install-dir=/bin --filename=composer

OS_NAME=`cat /etc/os-release | grep PRETTY_NAME | cut -d '=' -f2 | tr -d '"'`

#Check if package exists
if [ -d "$CORE_PACKAGE_NAME" ] ; then
  rm -rf $CORE_PACKAGE_NAME
  echo "$CORE_PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Removed existing package if any"

fi

composer create-project drupal/recommended-project my_site_name_dir -n

cd my_site_name_dir

composer require 'drupal/ctools:^3.8'

composer require 'drupal/page_manager:^4.0@beta'

if ! composer install --no-interaction; then
        echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
        exit 1
fi


