# ----------------------------------------------------------------------------
#
# Package       : Quagga
# Version       : 1.2.3
# Source repo   : https://github.com/Quagga/quagga
# Tested on     : ubuntu_16.04
# Script License: Apache License, Version 2 or later
# Maintainer    : Meghali Dhoble <dhoblem@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

# Install Dependencies
sudo apt-get update -y
sudo apt-get install -y git wget tar make gcc g++ automake autoconf \
    build-essential gawk texinfo libtool libreadline-dev libc-ares-dev \
    pkg-config curl zip bzip2 apt-utils

# Set Environment variables
export LD_LIBRARY_PATH=/usr/local/lib
export PKG_CONFIG_PATH=/usr/local/include
export protobuf_CFLAGS=/usr/local/include
export protobuf_LIBS=/usr/local/lib
export home=$PWD

# protobuf and protobuf-c needs to be installed manually, due to specific
# version requirement
git clone https://github.com/google/protobuf.git
cd protobuf && git checkout v2.6.1
./autogen.sh
./configure
make && sudo make install
cd $home
wget http://archive.ubuntu.com/ubuntu/pool/universe/p/protobuf-c/protobuf-c_1.2.1.orig.tar.gz
tar -xvzf protobuf-c_1.2.1.orig.tar.gz && cd protobuf-c-1.2.1
autoconf
./configure
make && sudo make install
cd $home

# Download and build the source for Quagga
git clone https://github.com/Quagga/quagga && cd quagga/
./bootstrap.sh
./configure
make 
make check
sudo make install
