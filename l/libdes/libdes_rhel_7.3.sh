# ----------------------------------------------------------------------------
#
# Package	: libdes
# Version	: 4.04b
# Source repo	: https://github.com/tthurman/rgtpd.git
# Tested on	: rhel_7.3
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
sudo yum -y update
sudo yum install -y git gcc gcc-c++ make wget tar

# libdes code cloned from libdes repository does not get compiled on RHEL as
# some patches are required to be applied first. Hence the source and those
# patches are obtained from RHEL SRPMs and then it is built on RHEL.

mkdir libdes
cd libdes
wget ftp://ftp.ntua.gr/pub/crypt/mirrors/utopia.hacktic.nl/linux/redhat/SRPMS/libdes-4.04b-1.src.rpm
rpm2cpio libdes-4.04b-1.src.rpm | cpio -idmv --no-absolute-filenames
tar -xzvf libdes-4.04b.tar.gz
cd des
make
