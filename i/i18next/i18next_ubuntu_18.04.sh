# ----------------------------------------------------------------------------
#
# Package       : i18next
# Version       : 11.5.0
# Source repo   : https://github.com/i18next/i18next
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
sudo apt-get install -y git nodejs npm phantomjs
export QT_QPA_PLATFORM=offscreen 

# Clone and build source.
git clone https://github.com/i18next/i18next
cd i18next
npm install
npm test
