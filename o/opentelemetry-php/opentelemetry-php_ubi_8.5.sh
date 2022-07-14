#!/bin/bash -ex
# -----------------------------------------------------------------------------
#
# Package	: opentelemetry-php
# Version	: f3e9bdb
# Source repo	: https://github.com/open-telemetry/opentelemetry-php.git
# Tested on	: ubi 8.5
# Language      : php
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Adilhusain Shaikh <Adilhusain.Shaikh@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME="opentelemetry-php"
PACKAGE_VERSION=${1:-"f3e9bdb"}
PACKAGE_URL=https://github.com/open-telemetry/opentelemetry-php.git
HOME_DIR="$PWD"
export PHP_VERSION=${PHP_VERSION:-7.4.30}
dnf install -qy http://mirror.nodesdirect.com/centos/8-stream/BaseOS/ppc64le/os/Packages/centos-gpg-keys-8-6.el8.noarch.rpm
dnf install -qy http://mirror.nodesdirect.com/centos/8-stream/BaseOS/ppc64le/os/Packages/centos-stream-repos-8-6.el8.noarch.rpm
dnf config-manager --enable powertools
dnf install -qy epel-release
dnf install -qy libxml2-devel bzip2-devel gcc-c++ openssl-devel sqlite-devel curl-devel libpng-devel libjpeg-devel libicu-devel oniguruma-devel readline-devel libtidy-devel libxslt-devel libzip-devel diffutils autoconf bison-devel git bzip2 file make

curl -L https://raw.githubusercontent.com/phpenv/phpenv-installer/master/bin/phpenv-installer | bash

echo "
export PHPENV_ROOT=\"/root/.phpenv\"
if [ -d \"\${PHPENV_ROOT}\" ]; then
  export PATH=\"\${PHPENV_ROOT}/bin:\${PATH}\"
  eval \"\$(phpenv init -)\"
fi" >>~/.bashrc

export MAKEFLAGS=-j$(nproc)
source ~/.bashrc
phpenv install "$PHP_VERSION"
phpenv global "$PHP_VERSION"

export GRPC_VERSION="977ebbef09"
# installing phpiz script
curl https://raw.githubusercontent.com/php/php-src/master/scripts/phpize.in >/usr/bin/phpiz
chmod 755 /usr/bin/phpiz

# building grpc and installing grpc php extention
git clone -q https://github.com/grpc/grpc
cd grpc
git checkout $GRPC_VERSION
git submodule update --init
make
export grpc_root="$(pwd)"
cd src/php/ext/grpc
phpize
export GRPC_LIB_SUBDIR="libs/opt"
./configure --enable-grpc="${grpc_root}"
make
make install
echo "extension=grpc.so" >>/root/.phpenv/versions/"$PHP_VERSION"/etc/php.ini

cd $HOME_DIR
git clone -q $PACKAGE_URL $PACKAGE_NAME
cd $PACKAGE_NAME
git checkout "$PACKAGE_VERSION"
composer install && echo "installation successful for opentelemetry-php."
./vendor/bin/phpunit && echo "tests successful for opentelemetry-php."" "

