# ----------------------------------------------------------------------------
#
# Package	: backbone
# Version	: 1.3.3
# Source repo	: https://github.com/jashkenas/backbone
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
sudo apt-get install -y wget git nodejs npm
# PhantomJS 1.9.0 is required, but it is not compatible with ppc64le.
# phantomjs

# Clone and build source.
git clone https://github.com/jashkenas/backbone
cd backbone
patch -p1 < ../patchfile
npm install
# Tests are disabled due to dependency on phantomjs.
# npm test
