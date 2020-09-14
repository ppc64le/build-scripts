# ----------------------------------------------------------------------------
#
# Package	: rocksdb
# Version	: 5.10.4
# Source repo	: https://github.com/facebook/rocksdb.git
# Tested on	: ubuntu_16.04
# Script License: Apache License, Version 2 or later
# Maintainer	: Sandip Giri <sgiri@us.ibm.com>
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
sudo apt-get install -y curl build-essential git

git clone https://github.com/facebook/rocksdb.git
cd rocksdb
git checkout v5.10.4

# Will compile librocksdb.a, RocksDB static library. Compiles static library in release mode.
sudo make static_lib

# Will compile librocksdb.so, RocksDB shared library. Compiles shared library in release mode.
sudo make shared_lib

# The "make check" command requires high end VM.
# If users have a high end vm and want to run tests, they can uncomment "make check" and run tests.
# "make check" will compile and run all the unit tests. It will compile RocksDB in debug mode.

# sudo make check
