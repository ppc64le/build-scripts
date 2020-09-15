# ----------------------------------------------------------------------------
#
# Package       : whatwg-fetch
# Version       : 2.0.4
# Source repo   : https://github.com/github/fetch.git
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
git clone https://github.com/github/fetch.git
cd fetch
sudo npm install
# Disabling tests, as it's trying to launch the chrome browser which is not supported on power.
# sudo npm test
