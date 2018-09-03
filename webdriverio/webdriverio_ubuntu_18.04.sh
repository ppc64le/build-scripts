# ----------------------------------------------------------------------------
#
# Package       : webdriverio
# Version       : v5.0.0-beta.1
# Source repo   : https://github.com/webdriverio/webdriverio.git 
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
sudo apt-get install -y git nodejs npm


# Clone and build source.
git clone https://github.com/webdriverio/webdriverio.git
cd webdriverio
npm install
# Disabling tests, as it's trying to install the chromedriver dependency which is not supported on ppc64le.
# CI link - https://travis-ci.org/webdriverio/webdriverio
# npm run bootstrap
# npm run build
# npm test
