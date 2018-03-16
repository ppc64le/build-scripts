# ----------------------------------------------------------------------------
#
# Package	: zmq
# Version	: 4.1.6
# Source repo	: https://github.com/zeromq/zeromq4-1
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
sudo apt-get install -y git libtool pkg-config build-essential \
     autoconf automake gettext cpulimit libsodium-dev

git clone https://github.com/zeromq/libzmq.git
cd libzmq
./autogen.sh
./configure
make
sudo make install
sudo ldconfig
cd ..

export LD_LIBRARY_PATH=/usr/lib:/usr/local/lib:${LD_LIBRARY_PATH}

git clone https://github.com/zeromq/zeromq4-1.git
cd zeromq4-1
./autogen.sh
./configure
make
ulimit -n 64000
make check
sudo make install
