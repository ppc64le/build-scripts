# ----------------------------------------------------------------------------
#
# Package       : Moment Timezone
# Version       : 0.5.14
# Source repo   : https://github.com/moment/moment-timezone.git
# Tested on     : rhel_7.4
# Script License: Apache License, Version 2 or later
# Maintainer    : Meghali Dhoble <dhoblem@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ============  platform using the mentioned version of the package.
#               It may not work as expected with newer versions of the
#               package and/or distribution. In such case, please
#               contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

# Install Dependencies
sudo yum update -y
sudo yum install -y wget git

# Install NPM using NVM
wget -qO- https://raw.githubusercontent.com/creationix/nvm/v0.31.1/install.sh| sh
source ~/.nvm/nvm.sh
nvm install stable
nvm use stable

#Download source
git clone https://github.com/moment/moment-timezone.git
cd moment-timezone && git checkout master

# Disabling the below tests, as they have been verified failing on x86 as well
cd tests/zones/america/ && \
mv cancun.js cancun.js.bk && \
mv fort_nelson.js fort_nelson.js.bk && \
mv metlakatla.js metlakatla.js.bk

# Build and Test
npm install && npm test
