#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: php-code-coverage
# Version	: 6.1.4,9.2.6
# Source repo	: https://github.com/sebastianbergmann/php-code-coverage/
# Tested on	: UBI 8.5
# Language      : PHP
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Ambuj Kumar <Ambuj.Kumar3@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=php-code-coverage
PACKAGE_VERSION=${1:-9.2.6}
PACKAGE_URL=https://github.com/sebastianbergmann/php-code-coverage/

DEFAULT_COMPOSER_FLAGS="--no-interaction --no-ansi --no-progress --no-suggest"

yum update -y

yum module enable php:7.3 -y

yum install php php-json php-dom php-xml php-mbstring php-dbg php-cli php-xdebug zip git -y

php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && php composer-setup.php --install-dir=/bin --filename=composer

if [ -d $PACKAGE_NAME ] ; then
   rm -rf $PACKAGE_NAME
  echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Removed existing package if any"

fi
if ! git clone $PACKAGE_URL $PACKAGE_NAME; then
        echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails"
        exit 0
fi
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

composer require theseer/tokenizer

composer update $DEFAULT_COMPOSER_FLAGS

phpdbg -qrr vendor/bin/phpunit --coverage-clover=coverage.xml
