# ----------------------------------------------------------------------------
#
# Package	: cloog
# Version	: 0.18.0
# Source repo	: https://github.com/Distrotech/cloog
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
sudo yum -y install git autoconf automake libtool gmp-devel make file

# Clone and build source code.
git clone https://github.com/Distrotech/cloog.git
cd cloog
./get_submodules.sh
./autogen.sh
./configure
make
sudo make install
make check
