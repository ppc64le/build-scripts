# ----------------------------------------------------------------------------
#
# Package	: cpython
# Version	: 3.8
# Source repo	: https://github.com/python/cpython
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

sudo apt-get update -y
sudo apt-get install -y build-essential git zlib1g-dev

git clone https://github.com/python/cpython
cd cpython
./configure
make
make test
sudo make install
