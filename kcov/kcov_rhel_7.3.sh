# ----------------------------------------------------------------------------
#
# Package	: kcov
# Version	: 33
# Source repo	: https://github.com/SimonKagstrom/kcov
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
sudo yum install -y elfutils-libelf-devel libcurl-devel binutils-devel \
  elfutils-devel git cmake make gcc gcc-c++

# Clone and build source code.
git clone https://github.com/SimonKagstrom/kcov
cd kcov
cmake .
make
sudo make install
