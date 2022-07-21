#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: redis
# Version	: 3.2.9
# Source repo	: https://github.com/antirez/redis.git
# Tested on	: rhel_7.4
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

# Install dependencies.

PACKAGE_VERSION=${1:-3.2.9}
yum install -y sudo
sudo yum update -y
sudo yum install -y git tcl
sudo yum install -y gcc-c++ make

# Clone and build source.
git clone https://github.com/antirez/redis.git --branch $PACKAGE_VERSION
cd redis
make V=1 MALLOC=libc
./runtest
sudo make install
