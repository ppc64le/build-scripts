# ----------------------------------------------------------------------------
#
# Package       : angular-ui-router
# Version       : 1.0.19
# Source repo   : https://github.com/angular-ui/ui-router
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
sudo apt-get install -y git nodejs npm phantomjs

#Set environment variables
export QT_QPA_PLATFORM=offscreen

# Clone and build source.
git clone https://github.com/angular-ui/ui-router
cd ui-router
npm install
#Disabling test execution as karma:unit tests are failing due to un-availibilty
#of headless chrome in Power, these are not expected to have any functional impact
#npm test
