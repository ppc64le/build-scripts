# ----------------------------------------------------------------------------
#
# Package       : qunit
# Version       : v1.14.0
# Source repo   : https://github.com/qunitjs/qunit
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
sudo apt-get install -y git nodejs npm wget libfontconfig1-dev

# Install PhantomJs
wget https://github.com/ibmsoe/phantomjs/releases/download/2.1.1/phantomjs-2.1.1-linux-ppc64.tar.bz2
tar -xvf phantomjs-2.1.1-linux-ppc64.tar.bz2
rm -rf phantomjs-2.1.1-linux-ppc64.tar.bz2
sudo mv phantomjs-2.1.1-linux-ppc64/bin/phantomjs /usr/bin/

# Clone and build source.
git clone https://github.com/qunitjs/qunit
cd qunit
npm install
npm test
