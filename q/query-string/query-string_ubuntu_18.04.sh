# ----------------------------------------------------------------------------
#
# Package       : query-string
# Version       : 6.1.0
# Source repo   : https://github.com/sindresorhus/query-string.git
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
sudo apt-get install -y git nodejs npm

# Clone and build source.
git clone https://github.com/sindresorhus/query-string.git
cd query-string
npm install
# While running the tests . we were getting error "test/properties.js:32:1 Expected indentation of 3 tabs but found 2."
# Adding one tab to pass the tests
sed -i 's/.*m.stringify/\t&/' test/properties.js
npm test
