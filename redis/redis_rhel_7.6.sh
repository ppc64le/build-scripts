# ----------------------------------------------------------------------------
#
# Package       : redis
# Version       : 5.0.4
# Source repo   : https://github.com/antirez/redis.git
# Tested on     : rhel 7.6
# Script License: Apache License, Version 2 or later
# Maintainer    : Amit Ghatwal <ghatwala@us.ibm.com>
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
sudo yum install -y git tcl make gcc

# Clone and build source.
git clone https://github.com/antirez/redis.git
cd redis
git checkout 5.0.4
sudo make install
redis-cli --version
