# ----------------------------------------------------------------------------
#
# Package       : mocha
# Version       : 5.2.0 
# Source repo   : https://github.com/mochajs/mocha.git
# Tested on     : ubuntu_18.04
# Script License: Apache License, Version 2 or later
# Maintainer    : Sandip Giri <sgiri@us.ibm.com>
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
sudo apt-get install -y git curl python-dev pkg-config  libvips-dev libcairo2-dev libjpeg-dev libgif-dev 
curl https://raw.githubusercontent.com/creationix/nvm/v0.33.0/install.sh| bash
source ~/.nvm/nvm.sh
nvm install v10.8.0

# Clone and build source.
# CI for mocha - https://travis-ci.org/mochajs/mocha/jobs/413242512
git clone https://github.com/mochajs/mocha.git
cd mocha
npm install --production
./bin/mocha --opts /dev/null --reporter spec test/sanity/sanity.spec.js
