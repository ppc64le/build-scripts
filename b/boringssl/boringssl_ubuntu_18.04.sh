#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : boringssl
# Version       : Commit(36a41bf0bf2dd3176f8780e09c03585351f29963)
# Source repo   : https://boringssl.googlesource.com/boringssl/
# Tested on     : ubuntu_18.04
# Script License: Apache License, Version 2 or later
# Maintainer    : Nishikant Thorat <Nishikant.Thorat@ibm.com>
# Travis-Check  : True
# Language	: go
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#
# Install dependencies
#
apt-get update -y
apt-get install -y sudo
sudo apt-get install -y cmake build-essential g++ wget git pkg-config libunwind-dev
#
# Install go
#
wget https://storage.googleapis.com/golang/go1.15.11.linux-ppc64le.tar.gz
sudo tar -C /usr/local -xzf go1.15.11.linux-ppc64le.tar.gz
export PATH=$PATH:/usr/local/go/bin
rm go1.15.11.linux-ppc64le.tar.gz
#
# Clone and build source code
#
PACKAGE_VERSION=${1:-36a41bf0bf2dd3176f8780e09c03585351f29963}
git clone https://boringssl.googlesource.com/boringssl/
cd boringssl
git checkout $PACKAGE_VERSION
mkdir build
cd build
cmake ..
make
make all_tests
make run_tests
