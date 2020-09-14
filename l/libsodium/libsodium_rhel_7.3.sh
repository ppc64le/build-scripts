# ----------------------------------------------------------------------------
#
# Package	: libsodium
# Version	: 1.0.12
# Source repo	: https://github.com/jedisct1/libsodium.git
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
sudo yum -y update
sudo yum -y install git gcc make git libtoolize pkg-config autoconf \
    automake gettext libtool which

# Clone and build source.
git clone https://github.com/jedisct1/libsodium.git
cd libsodium && ./autogen.sh && ./configure && make && make check && \
    sudo make install
