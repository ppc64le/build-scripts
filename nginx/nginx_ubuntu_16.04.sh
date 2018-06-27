# ----------------------------------------------------------------------------
#
# Package	: nginx
# Version	: 1.15.1
# Source repo	: https://github.com/nginx/nginx.git
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
sudo apt-get install -y build-essential libpcre3-dev libssl-dev \
    zlib1g-dev git-core

# Clone and build source.
git clone https://github.com/nginx/nginx.git
cd nginx
./auto/configure
make
sudo make install
