# ----------------------------------------------------------------------------
#
# Package	: jemalloc
# Version	: 4.2.0
# Source repo	: https://github.com/jemalloc/jemalloc
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

# install dependent packages
sudo apt-get update -y
sudo apt-get install -y git libtool libtool-bin automake build-essential

# Compile, test and install
git clone https://github.com/jemalloc/jemalloc
cd jemalloc
./autogen.sh
./configure
sudo make install_bin install_include install_lib
