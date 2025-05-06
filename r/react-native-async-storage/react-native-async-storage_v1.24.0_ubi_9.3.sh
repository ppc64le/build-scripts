#!/bin/bash -e
# ----------------------------------------------------------------------------- 
#
# Package       : async-storage
# Version       : @react-native-async-storage/async-storage@1.24.0
# Source repo   : https://github.com/react-native-async-storage/async-storage.git
# Tested on     : UBI 9.3 (ppc64le)
# Language      : JavaScript
# Travis-Check  : true
# Script License: Apache License, Version 2 or later
# Maintainer    : Amit Kumar <amit.kumar282@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------- 

PACKAGE_NAME=async-storage
PACKAGE_VERSION=${1:-@react-native-async-storage/async-storage@1.24.0}
PACKAGE_URL=https://github.com/react-native-async-storage/async-storage.git
BUILD_DIR=$(pwd)
export TURBO_VERSION=1.4.4

# Install Dependencies
yum install -y git tar gcc gcc-c++ make pkgconfig jq glib2-devel expat-devel diffutils gettext libjpeg-turbo-devel libpng-devel

# Install Node.js manually (compatible version)
export NODE_VERSION=20.11.1
cd /tmp
curl -O https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-ppc64le.tar.gz
tar -xzf node-v$NODE_VERSION-linux-ppc64le.tar.gz
export PATH=/tmp/node-v$NODE_VERSION-linux-ppc64le/bin:$PATH

# Install compatible yarn and turbo
npm install -g yarn
yarn global add turbo@$TURBO_VERSION

# Build and install libvips (from source)
cd /tmp
VIPS_VERSION=8.12.1
curl -LO https://github.com/libvips/libvips/releases/download/v${VIPS_VERSION}/vips-${VIPS_VERSION}.tar.gz
tar -xzf vips-${VIPS_VERSION}.tar.gz
rm -f vips-${VIPS_VERSION}.tar.gz
cd vips-${VIPS_VERSION}
./configure --prefix=/usr/local
make -j"$(nproc)"
make install
ldconfig

# Clone the async-storage repo
cd $BUILD_DIR
git clone $PACKAGE_URL
cd async-storage
git fetch --all --tags
git checkout "$PACKAGE_VERSION"

# Set Up Dependencies
sed -i 's/"turbo": *"[^"]*"/"turbo-linux-ppc64le": "1.4.4"/' package.json

# Install project dependencies
yarn install

# Link turbo manually if required
ln -sf /async-storage/node_modules/turbo-linux-ppc64le/bin/turbo \
 /usr/local/share/.config/yarn/global/node_modules/.bin/turbo
 
# Build the package
ret=0
yarn run build || ret=$?
if [ "$ret" -ne 0 ]; then
    exit 1
fi

# Run tests (if any)
yarn run test:ts || ret=$?
if [ "$ret" -ne 0 ]; then
    exit 2
fi

BUILD_VERSION=$(jq -r .version /${PACKAGE_NAME}/packages/default-storage/package.json)
echo "SUCCESS: ${PACKAGE_NAME}_$BUILD_VERSION built and tested successfully!"