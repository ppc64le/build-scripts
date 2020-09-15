# ----------------------------------------------------------------------------
#
# Package       : angular-local-storage
# Version       : v0.7.1
# Source repo   : https://github.com/grevory/angular-local-storage.git
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
sudo npm install -g grunt-cli
sudo npm install -g bower

#Set environment variables
export QT_QPA_PLATFORM=offscreen

# Clone and build source.
git clone https://github.com/grevory/angular-local-storage.git
cd angular-local-storage
npm install
bower install
grunt test
