#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: xmlsec
# Version	: xmlsec-1_2_37
# Source repo	: https://github.com/lsh123/xmlsec.git
# Tested on	: UBI: 8.5
# Language      : C
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Pooja Shah <Pooja.Shah4@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=xmlsec
PACKAGE_VERSION=${1:-xmlsec-1_2_37}
PACKAGE_URL=https://github.com/lsh123/xmlsec.git
HOME_DIR=${PWD}

yum update -y
yum install -y autoconf libtool make openssl-devel libxml2-devel pkgconfig git libxslt-devel diffutils nss-tools wget tar gnutls libgcrypt-devel
yum install -y http://rpmfind.net/linux/centos/8-stream/AppStream/ppc64le/os/Packages/libtool-ltdl-devel-2.4.6-25.el8.ppc64le.rpm

#Cloning xmlsec repo
cd $HOME_DIR
git clone $PACKAGE_URL
cd $PACKAGE_NAME/
git checkout $PACKAGE_VERSION

#Generate and then run the configuration
./autogen.sh

if ! make; then
        echo "Build Fails"
	exit 1
elif ! OPENSSL_ENABLE_MD5_VERIFY=1 make check; then
        echo "Test Fails"
        exit 2
elif ! make install; then
        echo "Install Fails"
	exit 1
else
        xmlsec1 --version
        echo "Build, Install and Test Success"
        exit 0
fi

# By default, OPENSSL_ENABLE_MD5_VERIFY is set to 0. However, to enable the disabled ciphers in OpenSSL on UBI, it should be set to 1.
# Reference: https://github.com/lsh123/xmlsec/issues/619