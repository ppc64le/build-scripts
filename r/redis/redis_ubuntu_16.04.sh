#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: redis
# Version	: 3.2.9
# Source repo	: https://github.com/antirez/redis.git
# Tested on	: ubuntu-16.04
# Language      : C
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Atharv Phadnis <Atharv.Phadnis@ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------


PACKAGE_VERSION=${1:-3.2.9}
# Install dependencies.
sudo apt-get update -y
sudo apt-get install -y git build-essential tcl

# Clone and build source.
git clone https://github.com/antirez/redis.git --branch $PACKAGE_VERSION
cd redis
make distclean
make V=1 MALLOC=libc
make test
sudo make install
