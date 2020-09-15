# ----------------------------------------------------------------------------
#
# Package       : Code-prettify
# Version       : 2013-03-04
# Source repo   : https://github.com/google/code-prettify
# Tested on     : ubuntu_18.04
# Script License: Apache License, Version 2 or later
# Maintainer    : Meghali Dhoble <dhoblem@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

# Install Dependencies
sudo apt-get update -y
sudo apt-get install -y git nodejs npm

# Download source
git clone https://github.com/google/code-prettify
cd code-prettify

# Build and Test
npm install 
# No Tests Specified 
