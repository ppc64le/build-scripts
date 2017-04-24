# ----------------------------------------------------------------------------
#
# Package       : xxHash
# Version       : v0.6.2
# Source repo   : https://github.com/Cyan4973/xxHash
# Tested on     : RHEL_7.3
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

#Install dependencies
sudo yum update
sudo yum install -y gcc-c++ make git python curl valgrind git

#Build and test xxHash
git clone  https://github.com/Cyan4973/xxHash
cd xxHash
make
make test
