# ----------------------------------------------------------------------------
#
# Package	: classnames
# Version	: 2.2.6
# Source repo	: https://github.com/JedWatson/classnames
# Tested on	: ubuntu_18.04
# Language      : Node
# Ci-Check  : False
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
sudo apt-get install -y git nodejs npm

# Clone and build source.
git clone https://github.com/JedWatson/classnames
cd classnames
npm install
npm test
