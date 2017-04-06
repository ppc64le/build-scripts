# ----------------------------------------------------------------------------
#
# Package	: googletest
# Version	: 1.7.0
# Source repo	: https://github.com/google/googletest.git
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

virtual_root=`pwd`

# Install dependencies.
sudo yum install -y make gcc gcc-c++ git cmake
export GTEST_DIR=$virtual_root/googletest/

# build and install googletest.
git clone https://github.com/google/googletest.git
cd googletest && \
mkdir builddir && \
cd builddir && \
cmake -Dgtest_build_tests=ON ${GTEST_DIR} && \
make && \
make test
