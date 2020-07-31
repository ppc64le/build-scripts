# ----------------------------------------------------------------------------
#
# Package       : LevelDB
# Version       : Commit #b91d5ce (master)
# Source repo   : https://github.com/basho/leveldb.git
# Tested on     : ubuntu_18.04
# Script License: Apache License, Version 2 or later
# Maintainer    : Priya Seth <sethp@us.ibm.com?
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the master of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

#Install dependencies
apt-get update -y
apt-get install -y gcc g++ git make

git clone https://github.com/basho/leveldb.git
cd leveldb

#Apply patch
patch port/atomic_pointer.h ../patches/atomic_pointer.patch

make all
make test
