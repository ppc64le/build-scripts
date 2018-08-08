# ----------------------------------------------------------------------------
#
# Package       : jline
# Version       : NA
# Source repo   : https://github.com/bitdivine/jline.git
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
sudo npm install -g jshint

# Clone and build source.
git clone https://github.com/bitdivine/jline.git
cd jline
npm install
sed -i 's/}/, "esversion": 6}/g' .jshintrc
sed -i '28s/$/;/' bin/csv.js
sed -i '31s/$/;/' bin/csv.js
sed -i '32s/$/;/' bin/csv.js
sed -i '28s/$/;/' bin/join_left.js
sed -i '29s/nay(e)/nay(e);/' bin/join_left.js
sed -i '48s/nay(e)/nay(e);/' bin/join_left.js
sed -i '36i\\tpath.reduce(function(s,n){return (s[n]=(--c?(s[n]||{}):value));},subject);' bin/foreach.js
sed -i '37d' bin/foreach.js
npm test
