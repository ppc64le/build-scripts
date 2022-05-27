#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package               : jszip
# Version               : 3.3.0 , 3.7.1
# Source repo           : https://github.com/Stuk/jszip
# Tested on             : UBI 8
# Language      	: Node
# Travis-Check  	: True
# Script License        : Apache License, Version 2 or later
# Maintainer            : Swati Singhal <swati.singhal@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_VERSION=3.3.0

echo "Usage: $0 [-v <PACKAGE_VERSION>]"
echo "       PACKAGE_VERSION is an optional paramater whose default value is 3.3.0"

PACKAGE_VERSION="${1:-$PACKAGE_VERSION}"

# install tools and dependent packages
yum -y install git wget gcc-c++ make python2 curl

NODE_VERSION=v12.22.4
#installing nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash
source ~/.bashrc
nvm install $NODE_VERSION

# clone, build and test specified version

git clone https://github.com/Stuk/jszip
cd jszip
git checkout v$PACKAGE_VERSION
npm install
# uncomment the below line to run tests
#npm test
