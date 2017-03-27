# ----------------------------------------------------------------------------
#
# Package	: axon
# Version	: 2.0.3
# Source repo	: https://github.com/tj/axon
# Tested on	: rhel_7.2
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
sudo yum install -y git gcc gcc-c++ openssl make python curl npm

WORKDIR=$HOME

# Clone, build and install nodejs.
cd $WORKDIR
git clone https://github.com/andrewlow/node.git --branch v0.12.4-release-ppc
cd node && ./configure && make && sudo make install

# Build and install axon.
cd $WORKDIR
git clone https://github.com/tj/axon
cd axon
npm install
npm test
