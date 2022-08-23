# ----------------------------------------------------------------------------
#
# Package	: protobuf
# Version	: 3.4.1
# Source repo	: https://github.com/google/protobuf
# Tested on	: ubuntu_16.04
# Language      : Java,C++
# Travis-Check  : True
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

sudo apt-get update -y
sudo apt-get install -y git autoconf libtool automake g++ make curl unzip
git clone https://github.com/google/protobuf -b v3.4.1 --depth 1
cd protobuf
./autogen.sh
./configure --prefix=/usr
make && make check
sudo make install
