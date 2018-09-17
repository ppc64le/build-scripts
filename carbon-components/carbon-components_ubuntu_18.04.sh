# ----------------------------------------------------------------------------
#
# Package       : carbon-components
# Version       : 8.16.8
# Source repo   : https://github.com/IBM/carbon-components
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
sudo apt-get install -y git nodejs npm phantomjs firefox
sudo npm install -g yarn

export QT_QPA_PLATFORM=offscreen 

# Build from source
git clone https://github.com/IBM/carbon-components
cd carbon-components
git checkout v8.16.8
yarn
# Disabling ChromeHeadless related tests, as its not supported on power platform.
sed -ie  s/"-b ChromeHeadless_Travis"//g  tools/ci-check.sh
# If you have configured the firefox with Display , then please enable the below test command.
# yarn ci-check 
