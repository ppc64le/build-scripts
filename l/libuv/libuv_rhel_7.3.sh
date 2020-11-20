# ----------------------------------------------------------------------------
#
# Package	: libuv
# Version	: 1.12.0
# Source repo	: https://github.com/libuv/libuv.git
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
sudo yum install -y git wget automake libtool gcc make

# Clone and build source code.
git clone https://github.com/libuv/libuv.git libuv
cd libuv
sh autogen.sh
./configure
make
sudo make install
