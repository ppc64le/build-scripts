# ----------------------------------------------------------------------------
#
# Package       : postcss-reduce-initial
# Version       : 1.0.1, 4.0.3
# Source repo   : https://github.com/cssnano/cssnano
# Tested on     : UBI: 8.3
# Script License: Apache License 2.0
# Maintainer's  : Jotirling Swami <Jotirling.Swami1@ibm.com>
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

# Variables
REPO=https://github.com/cssnano/cssnano.git
DIR=cssnano

# Default tag for postcss-reduce-initial
if [ -z "$1" ]; then
  export VERSION="v1.0.1"
else
  export VERSION="$1"
fi
echo "Its support for the Version-v1.0.1 and Version-4.0.3"
echo "Building for Version-$VERSION"


# install tools and dependent packages
yum update -y
yum install -y git npm

# Cloning the repository from remote to local
cd /home
git clone $REPO
cd $DIR
git checkout $VERSION

# Build and test package
npm install postcss-reduce-initial --save