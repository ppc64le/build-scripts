 ----------------------------------------------------------------------------
#
# Package       : Apollo-cache-inmemory
# Version       : main
# Source repo   : https://github.com/apollographql/apollo-client
# Tested on     : UBI 8
# Script License: Apache License Version 2.0
# Maintainer    : Swati Singhal <swati.singhal@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash
PACKAGE_VERSION=main

echo "Usage: $0 [-<version-prefix><PACKAGE_VERSION>]"
echo "       PACKAGE_VERSION is an optional paramater whose default value is main"

PACKAGE_VERSION="${1:-$PACKAGE_VERSION}"

yum install -y git curl
yum install -y openssl-devel bzip2-devel libffi-devel zlib-devel make gcc
yum install -y python38-devel.ppc64le
yum install -y gcc-c++-8.4.1-1.el8.ppc64le

NODE_VERSION=v12.22.4
#installing nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash
source ~/.bashrc
nvm install $NODE_VERSION

git clone https://github.com/apollographql/apollo-client
cd apollo-client
git checkout $PACKAGE_VERSION
npm i
npm test

