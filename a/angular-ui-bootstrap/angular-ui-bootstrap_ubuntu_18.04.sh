# ----------------------------------------------------------------------------
#
# Package       : angular-ui-bootstrap
# Version       : 2.5.6
# Source repo   : https://github.com/angular-ui/bootstrap
# Tested on     : ubuntu_18.04
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
sudo apt-get update -y
sudo apt-get install -y git nodejs npm

# Clone and build source.
git clone https://github.com/angular-ui/bootstrap
cd bootstrap
npm install
#karma tests need chrome which is not available on ppc64le.
#This does not have any functional impact
#npm test
