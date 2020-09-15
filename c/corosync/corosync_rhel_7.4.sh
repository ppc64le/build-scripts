# ----------------------------------------------------------------------------
#
# Package	: corosync
# Version	: 2.99.1
# Source repo	: https://github.com/corosync/corosync.git
# Tested on	: rhel_7.4
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
sudo yum install -y yum-cron
sudo yum makecache fast
sudo yum install -y git make gcc automake autoconf libtool \
  zlib check nss-devel.ppc64le pkgconfig nss pam-devel wget \
  file libnet lksctp-tools-devel openssl-devel xz-devel \
  bzip2-devel doxygen libxml2-devel
WDIR=`pwd`

# build libqb.
cd /tmp
git clone git://github.com/asalkeld/libqb.git
cd libqb && ./autogen.sh && ./configure && \
  make && sudo make install && make check

# build lz4.
cd /tmp
git clone https://github.com/lz4/lz4
cd lz4 && make && sudo make install
export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH

# build lzo
cd /tmp
wget http://www.oberhumer.com/opensource/lzo/download/lzo-2.10.tar.gz
tar -xzf lzo-2.10.tar.gz
cd lzo-2.10 && ./configure && make && make check && sudo make install

# install sctp
cd /tmp
git clone https://github.com/sctp/lksctp-tools
cd lksctp-tools
./bootstrap && ./configure && make && sudo make install

# build libknet
cd /tmp
git clone https://github.com/fabbione/kronosnet
cd kronosnet && ./autogen.sh && ./configure && \
  make && sudo make install

# build corosync
cd $WDIR
git clone https://github.com/corosync/corosync.git
cd corosync
./autogen.sh && ./configure && \
make && make check && sudo make install
