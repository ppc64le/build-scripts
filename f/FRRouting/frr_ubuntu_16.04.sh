# ----------------------------------------------------------------------------
#
# Package	: FRRouting/frr
# Version	: FRR 5.0 release
# Source repo	: https://github.com/FRRouting/frr
# Tested on	: ubuntu_16.04
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

#Install dependencies
sudo apt-get update -y 
sudo apt-get install -y git build-essential autoconf automake \
	libtool libjson-c-dev libpython-dev pkg-config \
	libreadline-dev libc-ares-dev flex python-sphinx texinfo \
	bison python-pytest

#Clone source and build
git clone https://github.com/FRRouting/frr
cd frr
sh bootstrap.sh
./configure
make

#Execute automated tests
make check

