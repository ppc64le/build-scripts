# ----------------------------------------------------------------------------
#
# Package	: cyrus-sasl
# Version	: 2.1.26
# Source repo	: git://git.cyrusimap.org/cyrus-sasl/
# Tested on	: rhel_7.3
# Script License: Apache License, Version 2 or later
# Maintainer	: Atul Sowani <sowania@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash

# Install dependencies.
sudo yum update -y
sudo yum install -y openssl openssl-devel openssl-libs \
    which make wget gcc libtool gzip

# Build and test cyrus-sasl.
#wget ftp://ftp.cyrusimap.org/cyrus-sasl/cyrus-sasl-2.1.26.tar.gz
#tar -xzvf cyrus-sasl-2.1.26.tar.gz
#cd cyrus-sasl-2.1.26

git clone https://github.com/cyrusimap/cyrus-sasl
cd cyrus-sasl
./autogen.sh
./configure --build ppc64le && \
  mv libtool libtool.org && ln -s /usr/bin/libtool ./libtool && \
  make && make check && sudo make install
