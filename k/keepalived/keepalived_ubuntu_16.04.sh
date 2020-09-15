# ----------------------------------------------------------------------------
#
# Package	: keepalived
# Version	: 2.0.4
# Source repo	: https://github.com/acassen/keepalived.git
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
sudo apt-get install -y git build-essential openssl libssl-dev findutils \
    autoconf libnfnetlink-dev autoconf-archive xserver-xorg-dev pkg-config \
    libtool automake

# Clone and build source.
git clone https://github.com/acassen/keepalived.git
cd keepalived
autoreconf -W portability -visf
./configure
make all
