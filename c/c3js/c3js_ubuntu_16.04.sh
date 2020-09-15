# ----------------------------------------------------------------------------
#
# Package	: c3js/c3
# Version	: 0.4.21
# Source repo	: https://github.com/c3js/c3.git"
# Tested on	: ubuntu_16.04
# Script License: Apache License, Version 2 or later
# Maintainer	: Amit Ghatwal <ghatwala@us.ibm.com>
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
sudo apt-get update
sudo apt-get install git npm nodejs-legacy -y

# Installing dependencies using npm
npm install -f grunt-cli

# Build c3js/c3
git clone https://github.com/c3js/c3.git
cd c3

# Commenting out the browser related tests ( karma ) 
sed -i 's|"test": "npm run build \&\& npm run lint \&\& karma start karma.conf.js",|"test": "npm run build \&\& npm run lint ",|' package.json 
npm install 
npm run build 
npm run dist 
npm run test
