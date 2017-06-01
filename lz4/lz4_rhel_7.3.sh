# ----------------------------------------------------------------------------
#
# Package	: lz4
# Version	: 1.8.0
# Source repo	: https://github.com/Cyan4973/lz4.git
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
sudo yum -y install git make gcc valgrind

# Clone source code and build.
git clone https://github.com/Cyan4973/lz4.git
cd lz4
make
make test
