#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : pecl-file_formats-yaml
# Version       : 2.2.2
# Source repo   : https://github.com/php/pecl-file_formats-yaml.git
# Tested on     : UBI 8.5
# Language      : PHP
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Raju.Sah@ibm.com
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ------------------------------------------------------------------------------

PACKAGE_NAME=pecl-file_formats-yaml
PACKAGE_VERSION=${1:-2.2.2}
PACKAGE_URL=https://github.com/php/pecl-file_formats-yaml.git

#install dependencies
yum install -y git curl php php-devel php-curl php-dom php-mbstring php-json php-gd php-pdo libyaml-devel.ppc64le make

#clone the repo
cd /opt && git clone $PACKAGE_URL
cd $PACKAGE_NAME/
git checkout $PACKAGE_VERSION

#build and install the repo.
phpize
./configure --with-yaml
make 
make install
make test
