# ----------------------------------------------------------------------------
#
# Package	: node-normalize
# Version	: 0.3.1
# Source repo	: https://github.com/nulltask/normalize.styl
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
sudo apt-get install -y git nodejs npm

# Clone and build source.
git clone https://github.com/nulltask/normalize.styl
cd normalize.styl
npm install

# There are no tests provided with this package.
#npm test
