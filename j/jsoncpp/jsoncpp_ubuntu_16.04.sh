# ----------------------------------------------------------------------------
#
# Package	: jsoncpp
# Version	: 1.8.4
# Source repo	: https://github.com/open-source-parsers/jsoncpp.git
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
sudo apt-get install -y git gcc cmake python g++ make

git clone https://github.com/open-source-parsers/jsoncpp.git
cd jsoncpp
python amalgamate.py
mkdir -p build/debug
cd build/debug

cmake -DCMAKE_BUILD_TYPE=debug -DBUILD_STATIC_LIBS=ON \
  -DBUILD_SHARED_LIBS=OFF -DARCHIVE_INSTALL_DIR=. -G "Unix Makefiles" ../..
make
sudo make install
