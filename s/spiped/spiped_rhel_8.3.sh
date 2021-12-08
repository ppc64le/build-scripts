# ----------------------------------------------------------------------------
#
# Package       : spiped
# Version       : 1.6.1
# Source repo   : https://github.com/Tarsnap/spiped/
# Tested on     : rhel_8.3
# Script License: Apache License, Version 2 or later
# Maintainer    : Priya Seth <sethp@us.ibm.com>
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
sudo yum install -y git gcc-c++ make openssl-devel procps

export PKG_VERSION=1.6.1

git clone https://github.com/Tarsnap/spiped/
cd spiped
git checkout ${PKG_VERSION}
make
make test
