#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: librdkafka
# Version	: master(f7f527d8f2ff7f5bd86856ddc43115eb4dfbba97)
# Source repo	: https://github.com/edenhill/librdkafka.git
# Tested on	: UBI: 8.5
# Language      : C
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Sumit Dubey <Sumit.Dubey2@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=librdkafka
PACKAGE_VERSION=${1:-f7f527d8f2ff7f5bd86856ddc43115eb4dfbba97}
PACKAGE_URL=https://github.com/edenhill/librdkafka.git

# install required dependencies
yum install -y gcc gcc-c++ make git python3 openssl-devel lz4-devel zlib-devel cyrus-sasl-devel  libtool libcurl-devel

# cloning and installing librdkafka
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
./configure --prefix=/usr && make && make install && ldconfig