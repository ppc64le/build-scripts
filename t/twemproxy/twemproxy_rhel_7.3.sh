# ----------------------------------------------------------------------------
#
# Package	: twemproxy
# Version	: 0.4.1
# Source repo	: https://github.com/twitter/twemproxy
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
sudo yum install -y git gcc libtool autoconf make

# Clone and build source code.
git clone https://github.com/twitter/twemproxy
cd twemproxy
autoreconf -fvi
./configure --build=ppc64le-redhat-linux --enable-debug=full
make
make check
sudo make install
