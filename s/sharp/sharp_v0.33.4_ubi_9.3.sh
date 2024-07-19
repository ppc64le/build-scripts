#!/bin/bash -ex
# -----------------------------------------------------------------------------
#
# Package	: sharp
# Version	: v0.33.4
# Source repo	: https://github.com/lovell/sharp
# Tested on	: UBI 9.3
# Language      : C++, js
# Travis-Check  : false
# Script License: Apache License, Version 2 or later
# Maintainer	: Sumit Dubey <sumit.dubey2@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

SCRIPT_PACKAGE_VERSION=v0.33.4
PACKAGE_NAME=sharp
PACKAGE_VERSION=${1:-${SCRIPT_PACKAGE_VERSION}}
PACKAGE_URL=https://github.com/lovell/${PACKAGE_NAME}.git
BUILD_HOME=$(pwd)
SCRIPT_PATH=$(dirname $(realpath $0))
LIBVIPS_CHECKOUT=6651f42d25659eb200ea75f9d63ad742bbafaf0a

#Install deps
yum install git wget gcc-c++ make python3.11 jq -y

#Install docker
yum install -y yum-utils
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
mkdir -p /etc/docker
touch /etc/docker/daemon.json
cat <<EOT > /etc/docker/daemon.json
{
"ipv6": true,
"fixed-cidr-v6": "2001:db8:1::/64",
"mtu": 1450
}
EOT
dockerd > /dev/null 2>&1 &
sleep 5
docker run hello-world

#Install node
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
source $HOME/.bash_profile
nvm install 20
node -v
npm -v

#install node-addon-api and node-gyp
npm install -g node-gyp node-addon-api

#Install sharp-libvips
cd $BUILD_HOME
git clone https://github.com/lovell/sharp-libvips
cd sharp-libvips
git checkout ${LIBVIPS_CHECKOUT}
export LIBVIPS_VERSION=$(cat ./LIBVIPS_VERSION)
git apply ../sharp-libvips_ppc64le.patch
./build.sh ${LIBVIPS_VERSION} linux-ppc64le
./npm/populate.sh
export LIBVIPS_SO=$(ls ${BUILD_HOME}/sharp-libvips/npm/linux-ppc64/lib/libvips-cpp.so.*)
cp npm/linux-ppc64/lib/glib-2.0/include/glibconfig.h npm/linux-ppc64/include/glib-2.0/
cp ${LIBVIPS_SO} /usr/lib
ldconfig

#Get repo
cd $BUILD_HOME
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#Apply patch
git apply $SCRIPT_PATH/${PACKAGE_NAME}_${SCRIPT_PACKAGE_VERSION}.patch

#Build
ret=0
npm install --build-from-source || ret=$?
if [ "$ret" -ne 0 ]
then
	exit 1
fi
export LIBVIPS_TAR=${BUILD_HOME}/sharp-libvips/libvips-${LIBVIPS_VERSION}-linux-ppc64le.tar.gz
export SHARP_NODE_BINARY=${BUILD_HOME}/${PACKAGE_NAME}/src/build/Release/sharp-linux-ppc64.node

#Test
npm test || ret=$?
if [ "$ret" -ne 0 ]
then
        exit 2
fi

#Conclude
set +ex
echo "SUCCESS: Build and test success!"
echo "libvips tarball located at [$LIBVIPS_TAR]"
echo "libvips so located at [$LIBVIPS_SO]"
echo "Sharp node binary located at [$SHARP_NODE_BINARY]"
echo "One test (Image metadata - transform to invalid ICC profile emits warning) was found to be flaky and hence skipped"

