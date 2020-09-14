# ----------------------------------------------------------------------------
#
# Package	: boringssl
# Version	: n/a
# Source repo	: https://boringssl.googlesource.com/boringssl/
# Tested on	: rhel_7.3
# Script License: Apache License, Version 2 or later
# Maintainer	: Priya Seth <sethp@us.ibm.com>
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
sudo yum install -y cmake make wget git gcc-c++

# Install go.
wget https://storage.googleapis.com/golang/go1.8.1.linux-ppc64le.tar.gz
sudo tar -C /usr/local -xzf go1.8.1.linux-ppc64le.tar.gz
export PATH=$PATH:/usr/local/go/bin

# Clone and build source code.
git clone https://boringssl.googlesource.com/boringssl/
cd boringssl
mkdir build
cd build
cmake -DCMAKE_BUILD_TYPE=Release ..
make
make all_tests
make run_tests
