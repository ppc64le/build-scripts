# ----------------------------------------------------------------------------
#
# Package	: libmemcached
# Version	: 1.0.18
# Source repo	: https://launchpad.net/libmemcached
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
sudo yum install --nogpgcheck -y make gcc gcc-c++ wget gzip libtool \
    automake libevent-devel

# Build and test source.
wget https://launchpad.net/libmemcached/1.0/1.0.18/+download/libmemcached-1.0.18.tar.gz
tar -xvzf libmemcached-1.0.18.tar.gz
cd libmemcached-1.0.18
./configure && make && make test && sudo make install
