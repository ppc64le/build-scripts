# ----------------------------------------------------------------------------
#
# Package       : caniuse-db
# Version       : 1.0.30000997
# Source repo   : https://github.com/Fyrd/caniuse.git
# Tested on     : UBI 8.3
# Script License: Apache License, Version 2 or later
# Maintainer    : Balavva Mirji <Balavva.Mirji@ibm.com>
#
# Disclaimer: This script has beentested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash

# Variables
REPO=https://github.com/Fyrd/caniuse.git
PACKAGE_VERSION=60390c9

NODE_VERSION=v14.17.6

echo "Usage: $0 [-v <PACKAGE_VERSION>]"
echo "PACKAGE_VERSION is an optional paramater whose default value is 1.0.30000997"

PACKAGE_VERSION="${1:-$PACKAGE_VERSION}"

# Install required dependent packages
yum update -y
yum install -y git 

# Install nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash
source ~/.bashrc
nvm install $NODE_VERSION

# Clonning repo
git clone $REPO
cd caniuse
git checkout $PACKAGE_VERSION

node validator/validate-jsons.js
npm install
# No test cases found