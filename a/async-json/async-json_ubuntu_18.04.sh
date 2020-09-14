# ----------------------------------------------------------------------------
#
# Package	: async-json
# Version	: 0.0.2
# Source repo	: https://github.com/ckknight/async-json
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
git clone https://github.com/ckknight/async-json
cd async-json
npm install

# There are no tests provided with this package.
#npm test
