#!/bin/bash -ex
# --------------------------------------------------------------------------------------------
#
# Package       : react-native-blob-util
# Version       : 0.19.9
# Source repo   : https://github.com/RonRadtke/react-native-blob-util.git
# Tested on     : UBI 9.3
# Language      : Java, Others
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Prachi Gaonkar <Prachi.Gaonkar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# --------------------------------------------------------------------------------------------

# Install RHEL dependencies
yum install -y git

# Set variables
WDIR=$(pwd)
PACKAGE_NAME=react-native-blob-util
PACKAGE_URL=https://github.com/RonRadtke/${PACKAGE_NAME}.git
PACKAGE_VERSION=${1:-0.19.9}

export NODE_VERSION=${NODE_VERSION:-16}

#Installing nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source "$HOME"/.bashrc
echo "installing nodejs $NODE_VERSION"
nvm install "$NODE_VERSION" >/dev/null
nvm use $NODE_VERSION

# Clone react-native-blob-util repository
cd $WDIR
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#install react-native-blob-util
if ! npm ci ; then
        echo "------------------$PACKAGE_NAME:Install_fails---------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME"
        echo "$PACKAGE_NAME | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_Fails"
        exit 1
fi

#npm test --> "Error: no test specified"
