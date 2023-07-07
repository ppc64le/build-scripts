#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: php-code-coverage
# Version	: 6.1.4,9.2.7
# Source repo	: https://github.com/sebastianbergmann/php-code-coverage/
# Tested on	: UBI 8.5
# Language      : PHP
# Travis-Check  : True
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

PACKAGE_NAME=php-code-coverage
PACKAGE_VERSION=${1:-6.1.4}
PACKAGE_URL=https://github.com/sebastianbergmann/php-code-coverage/

DEFAULT_COMPOSER_FLAGS="--no-interaction --no-ansi --no-progress --no-suggest"

yum update -y

yum module enable php:7.3 -y

yum install php php-json php-dom php-xml php-mbstring php-dbg php-cli php-xdebug zip git -y

php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && php composer-setup.php --install-dir=/bin --filename=composer

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

composer require theseer/tokenizer

composer update $DEFAULT_COMPOSER_FLAGS

phpdbg -qrr vendor/bin/phpunit --coverage-clover=coverage.xml
