# ----------------------------------------------------------------------------
#
# Package	: swig
# Version	: 4.0.0
# Source repo	: https://github.com/swig/swig.git
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
sudo apt-get install -y git libboost-all-dev libpcre3 libpcre3-dev \
    yodl ruby-dev ocaml automake bison byacc build-essential

git clone https://github.com/swig/swig.git
cd swig
./autogen.sh
./configure --without-ocaml
make
sudo make install
make check-perl5-test-suite
