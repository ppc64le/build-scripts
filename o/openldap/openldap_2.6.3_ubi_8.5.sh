#!/bin/bash
# ----------------------------------------------------------------------------
#
# Package       : openldap
# Version       : 2.6.3
# Source repo   : https://github.com/openldap/openldap
# Tested on     : UBI: 8.5
# Language      : C
# Travis-Check  : True
# Script License: Apache License Version 2.0
# Maintainer    : Vishaka Desai <Vishaka.Desai@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=openldap
PACKAGE_VERSION=${1:-OPENLDAP_REL_ENG_2_6_3}
PACKAGE_URL=https://github.com/openldap/openldap

# install tools and dependent packages
yum install -y git make autoconf automake libtool gcc-c++

# Cloning Repo
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout ${PACKAGE_VERSION}
cd libraries/liblmdb

# Build and test package
mkdir -p /usr/local/man/man1
make
make install
make test
