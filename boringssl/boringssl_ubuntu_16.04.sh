# ----------------------------------------------------------------------------
#
# Package	: boringssl
# Version	: n/a
# Source repo	: https://boringssl.googlesource.com/boringssl/
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
sudo apt-get install -y cmake build-essential g++ wget git

# Install go.
wget https://storage.googleapis.com/golang/go1.8.1.linux-ppc64le.tar.gz
sudo tar -C /usr/local -xzf go1.8.1.linux-ppc64le.tar.gz
export PATH=$PATH:/usr/local/go/bin
rm go1.8.1.linux-ppc64le.tar.gz

# Clone and build source code.
git clone https://boringssl.googlesource.com/boringssl/
cd boringssl
mkdir build
cd build
cmake ..
make
make all_tests
make run_tests
