# ----------------------------------------------------------------------------
#
# Package	: libsodium
# Version	: 1.0.12
# Source repo	: https://github.com/jedisct1/libsodium.git
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
sudo apt-get install -y git libtool pkg-config build-essential \
    autoconf automake gettext

# Clone and build source.
git clone https://github.com/jedisct1/libsodium.git
cd libsodium && ./autogen.sh && ./configure && sudo make && \
    sudo make check && sudo make install
