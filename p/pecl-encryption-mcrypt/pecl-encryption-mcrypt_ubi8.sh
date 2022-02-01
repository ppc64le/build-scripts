#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: pecl-encryption-mcrypt
# Version	: 1.0.3
# Source repo	: https://github.com/php/pecl-encryption-mcrypt
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

PACKAGE_NAME=pecl-encryption-mcrypt
#PACKAGE_VERSION is configurable can be passed as an argument.
PACKAGE_VERSION=${1:-1.0.3}
PACKAGE_URL=https://github.com/php/pecl-encryption-mcrypt

yum update -y

yum install php php-devel php-json php-devel zip unzip php-zip wget git make -y

yum install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm -y

yum install libmcrypt libmcrypt-devel -y

php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && php composer-setup.php --install-dir=/bin --filename=composer

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

phpize && ./configure && make

make test REPORT_EXIT_STATUS=1 NO_INTERACTION=1 TESTS="--show-all"
