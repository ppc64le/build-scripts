# ----------------------------------------------------------------------------
#
# Package       : read-package-json-fast
# Version       : v1.2.1, v2.0.2
# Source repo   : https://github.com/npm/read-package-json-fast.git 
# Tested on     : UBI: 8.3
# Script License: Apache License 2.0
# Maintainer's  : Balavva Mirji <Balavva.Mirji@ibm.com>
#
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

# Default tag for read-package-json-fast
if [ -z "$1" ]; then
  export VERSION="v1.2.1"
else
  export VERSION="$1"
fi

# Variables
REPO=https://github.com/npm/read-package-json-fast.git

# install tools and dependent packages
yum update -y
yum install -y git 

# install node
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash
source ~/.bashrc
nvm install v14.17.6

#Cloning Repo
git clone $REPO
cd read-package-json-fast/
git checkout ${VERSION}

npm install yarn -g
yarn install
yarn test
#Observed two test failures on ppc64le, which are in parity with Intel

