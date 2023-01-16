#!/bin/bash -e
# ----------------------------------------------------------------------------
# Package          : symfony_config
# Version          : v3.4.37, v4.4.30
# Source repo      : https://github.com/symfony/config
# Tested on        : UBI 8.5
# Language         : PHP
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Bhagat Singh <Bhagat.singh1@ibm.com>, Bhimrao Patil <Bhimrao.Patil@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#   
# ----------------------------------------------------------------------------

# Variables
PACKAGE_NAME=config
PACKAGE_URL=https://github.com/symfony/config
#PACKAGE_VERSION is configurable can be passed as an argument.
PACKAGE_VERSION=${1:-v3.4.37}

yum module enable php:7.4 -y
yum install -y git curl php php-curl php-dom php-mbstring php-json php-gd php-pecl-zip
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && php composer-setup.php --install-dir=/bin --filename=composer

HOME_DIR=$(pwd)
#Check if package exists
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

cd "$HOME_DIR"/$PACKAGE_NAME || exit
git checkout "$PACKAGE_VERSION"

composer require symfony/phpunit-bridge

if [ $PACKAGE_VERSION == v3.4.37 ]; then
        composer require --dev phpunit/phpunit --with-all-dependencies ^7
else
        composer require --dev phpunit/phpunit --with-all-dependencies ^9
fi

if ! composer install; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
    exit 1
fi

cd "$HOME_DIR"/$PACKAGE_NAME || exit
if ! ./vendor/bin/phpunit --dont-report-useless-tests; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails"
    exit 1
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi

#Test case is in parity with intel for v4.4.30
#  Tests: 442, Assertions: 662, Failures: 1.
#   Symfony\Component\Config\Tests\Util\XmlUtilsTest::testLoadFile
#    Failed asserting that 'File "/root/config/Tests/Util/../Fixtures/Util/not_readable.xml" does not contain valid XML, it is empty.' contains "is not readable".

