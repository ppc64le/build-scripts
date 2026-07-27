#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: openresty-pcre
# Version	: 8.43
# Source repo	: https://sourceforge.net/projects/pcre/files/pcre/8.43/pcre-8.43.zip
# Tested on	: ubi 8.5
# Language      : c
# Travis-Check  : True
# Script License: Apache License 2.0
# Maintainer	: Amit Mukati <amit.mukati3@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

yum install -y wget make unzip gcc gcc-c++
dnf -qy upgrade
wget https://sourceforge.net/projects/pcre/files/pcre/8.43/pcre-8.43.zip
unzip pcre-8.43.zip
cd pcre-8.43
# Install
./configure --prefix=/usr                     \
            --docdir=/usr/share/doc/pcre-8.43 \
            --enable-jit                      \
            --enable-unicode-properties       \
            --enable-pcre16                   \
            --enable-pcre32                   \
            --disable-static                  \
            --disable-pcregrep-jit            \
            --enable-utf                      
make
make install
echo "INSTALL PASS"
# teste
make test
echo "TEST PASS"