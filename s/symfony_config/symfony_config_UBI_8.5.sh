#!/bin/bash -e
# ----------------------------------------------------------------------------
# Package          : symfony_config
# Version          : v3.4.47
# Source repo      : https://github.com/symfony/config
# Tested on        : UBI 8.5
# Language         : PHP
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Shalmon Titre <Shalmon.Titre@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#   
# ----------------------------------------------------------------------------

PACKAGE_NAME=config
PACKAGE_URL=https://github.com/symfony/config
PACKAGE_VERSION=${1:-v3.4.47}

yum module enable php:7.4 -y
yum install -y git curl php php-curl php-dom php-mbstring php-json php-gd php-pecl-zip
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && php composer-setup.php --install-dir=/bin --filename=composer

HOME_DIR=$(pwd)
if ! git clone $PACKAGE_URL $PACKAGE_NAME; then
    echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails"
    exit 1
fi

cd "$HOME_DIR"/$PACKAGE_NAME || exit
git checkout "$PACKAGE_VERSION"

composer require symfony/phpunit-bridge
composer require --dev phpunit/phpunit --with-all-dependencies ^9

if ! composer install; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
    exit 1
fi

sed -i '22s/.*/\    protected function setUp(): void/' Tests/ConfigCacheTest.php 
sed -i '27s/.*/\    protected function tearDown(): void/' Tests/ConfigCacheTest.php 

sed -i '21s/.*/\    protected function setUp(): void/' Tests/Resource/DirectoryResourceTest.php 
sed -i '30s/.*/\    protected function tearDown(): void/' Tests/Resource/DirectoryResourceTest.php
sed -i '38s/.*/\    protected function removeDirectory(string $directory): void/' Tests/Resource/DirectoryResourceTest.php

sed -i '23s/.*/\    protected function setUp(): void/' Tests/Resource/FileExistenceResourceTest.php 
sed -i '30s/.*/\    protected function tearDown(): void/' Tests/Resource/FileExistenceResourceTest.php

sed -i '23s/.*/\    protected function setUp(): void/' Tests/Resource/FileResourceTest.php 
sed -i '31s/.*/\    protected function tearDown(): void/' Tests/Resource/FileResourceTest.php

sed -i '19s/.*/\    protected function tearDown(): void/' Tests/Resource/GlobResourceTest.php

sed -i '23s/.*/\    protected function setUp(): void/' Tests/ResourceCheckerConfigCacheTest.php 
sed -i '28s/.*/\    protected function tearDown(): void/' Tests/ResourceCheckerConfigCacheTest.php

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

#Test case is in parity
#Symfony\Component\Config\Tests\Util\XmlUtilsTest::testLoadFile
#Failed asserting that 'File "/config/Tests/Util/../Fixtures/Util/not_readable.xml" does not contain valid XML, it is empty.' contains "is not readable".

#FAILURES!
#Tests: 402, Assertions: 563, Failures: 1.


