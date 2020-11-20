# ----------------------------------------------------------------------------
#
# Package	: cyrus-sasl
# Version	: 2.1.26
# Source repo	: git://git.cyrusimap.org/cyrus-sasl/
# Tested on	: ubuntu_16.04
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
sudo apt-get update -y
sudo apt-get -y install build-essential automake libtool \
    libdb5.3-dev libsasl2-dev zlib1g-dev libssl-dev libpcre3-dev \
    uuid-dev comerr-dev libcunit1-dev valgrind libsnmp-dev \
    bison flex libjansson-dev shtool pkg-config wget nroff

# Build and test cyrus-sasl.
#wget ftp://ftp.cyrusimap.org/cyrus-sasl/cyrus-sasl-2.1.26.tar.gz
#tar -xzvf cyrus-sasl-2.1.26.tar.gz
#cd cyrus-sasl-2.1.26

git clone https://github.com/cyrusimap/cyrus-sasl
cd cyrus-sasl
./autogen.sh
./configure --build ppc64le && make && \
   make check && sudo make install
