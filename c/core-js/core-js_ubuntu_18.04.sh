# ----------------------------------------------------------------------------
#
# Package	: core-js
# Version	: 2.5.7
# Source repo	: https://github.com/zloirock/core-js
# Tested on	: ubuntu_18.04
# Script License: Apache License, Version 2 or later
# Maintainer	: Atul Sowani <sowania@us.ibm.com>
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
sudo apt-get install -y git nodejs npm grunt phantomjs
export QT_QPA_PLATFORM=offscreen

# Clone and build source.
git clone https://github.com/zloirock/core-js
cd core-js
npm test
npm install
