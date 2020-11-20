# ----------------------------------------------------------------------------
#
# Package	: jodid25519
# Version	: 0.7.1
# Source repo	: https://github.com/meganz/jodid25519
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
git clone https://github.com/meganz/jodid25519
cd jodid25519
patch < ../patchfile
npm install
# Testing is disabled because it requires phantomjs 1.9.0 which is not
# supported on ppc64le.
# npm test
