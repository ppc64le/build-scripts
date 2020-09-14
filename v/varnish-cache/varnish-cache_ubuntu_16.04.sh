# ----------------------------------------------------------------------------
#
# Package	: varnish-cache
# Version	: 6.0.0
# Source repo	: https://github.com/varnishcache/varnish-cache
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
sudo apt-get install -y build-essential gcc g++ git python curl make \
    autoconf automake libpcre3-dev autotools-dev libedit-dev libtool \
    python-docutils libncursesw5-dev graphviz pkg-config

# Clone and build source.
git clone https://github.com/varnishcache/varnish-cache
cd varnish-cache
./autogen.sh
./configure
make
make test
sudo make install
