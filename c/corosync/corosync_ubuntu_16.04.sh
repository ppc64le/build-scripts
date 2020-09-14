# ----------------------------------------------------------------------------
#
# Package	: corosync
# Version	: 2.99.1
# Source repo	: https://github.com/corosync/corosync.git
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
sudo apt-get install -y git make gcc automake autoconf libnss3-dev libtool \
    libsctp-dev check pkg-config groff libpam0g-dev liblz4-dev doxygen \
    zlib1g zlib1g-dev libssl-dev liblzo2-dev liblzma-dev libbz2-dev \
    libxml2-dev
WDIR=`pwd`

# Install libqb.
cd /tmp
git clone git://github.com/asalkeld/libqb.git
cd libqb && ./autogen.sh && ./configure && \
  make && make check && \
  sudo make install

# build libknet.
cd /tmp
git clone https://github.com/fabbione/kronosnet && \
  cd kronosnet && ./autogen.sh && ./configure && \
  sed -i -e 's/-Werror//' libknet/tests/Makefile && \
  sed -i -e 's/LIBS = /LIBS = -lpthread /' libknet/tests/Makefile && \
  make && sudo make install

cd $WDIR
git clone https://github.com/corosync/corosync.git
cd corosync
./autogen.sh && ./configure && \
  make && make check && \
  sudo make install
