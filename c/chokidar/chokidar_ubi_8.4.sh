# ----------------------------------------------------------------------------
#
# Package               : chokidar
# Version               : 1.7.0, 1.5.2
# Source repo           : https://github.com/paulmillr/chokidar
# Tested on             : UBI 8.4
# Script License        : MIT License
# Maintainer            : Swati Singhal <swati.singhal@ibm.com>, Priya Seth <sethp@us.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash
PACKAGE_VERSION=1.7.0

echo "Usage: $0 [-v <PACKAGE_VERSION>]"
echo "       PACKAGE_VERSION is an optional paramater whose default value is 1.7.0"

PACKAGE_VERSION="${1:-$PACKAGE_VERSION}"

# install tools and dependent packages
yum -y update
yum -y install git wget gcc-c++ make python2 curl

NODE_VERSION=v12.22.4
#installing nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash
source ~/.bashrc
nvm install $NODE_VERSION

# clone, build and test specified version

git clone https://github.com/paulmillr/chokidar
cd chokidar
git checkout v$PACKAGE_VERSION
npm install
npm test
