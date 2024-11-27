#!/bin/bash -ex
# ----------------------------------------------------------------------------
#
# Package       : Rocket.Chat
# Version       : 6.11.1
# Source repo   : https://github.com/RocketChat/Rocket.Chat
# Tested on     : ubi:9.3
# Language      : TypeScript,JavaScript
# Travis-Check  : false
# Script License: MIT
# Maintainer    : Pratik Tonage <Pratik.Tonage@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#Run the container with below command:
#docker run --network host --privileged -t -d --name <container_name> -v /var/run/docker.sock:/var/run/docker.sock registry.access.redhat.com/ubi9/ubi:9.3
#docker exec -it <container_id> bash

PACKAGE_NAME=rocketchat
PACKAGE_VERSION=${1:-6.11.1}
PACKAGE_URL=https://github.com/RocketChat/Docker.Official.Image
RC_MAJOR=6.11
BUILD_HOME=$(pwd)
SCRIPT_PATH=$(dirname $(realpath $0))

SHARP_PACKAGE_NAME=sharp
SHARP_PACKAGE_VERSION=${1:-v0.33.5}
SHARP_PACKAGE_URL=https://github.com/lovell/${SHARP_PACKAGE_NAME}.git
LIBVIPS_VERSION=8.15.3

# Install dependencies
yum install git wget gcc-c++ make python3.11 jq -y

# Install docker if not found
if ! [ $(command -v docker) ]; then
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
fi
# docker run hello-world

# Install node
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
source $HOME/.bash_profile
nvm install 20

# Install node-addon-api and node-gyp
npm install -g node-gyp node-addon-api

# Install sharp-libvips
cd $BUILD_HOME
mkdir libvips-tar && cd libvips-tar
wget https://github.com/lovell/sharp-libvips/releases/download/v$LIBVIPS_VERSION/libvips-$LIBVIPS_VERSION-linux-ppc64le.tar.gz
tar xzf libvips-$LIBVIPS_VERSION-linux-ppc64le.tar.gz
rm -rf libvips-$LIBVIPS_VERSION-linux-ppc64le.tar.gz
cp lib/libvips-cpp.so.42 /usr/lib
cp -r lib/glib-2.0/include/glibconfig.h /usr/include
ldconfig

# clone sharp
cd $BUILD_HOME
git clone $SHARP_PACKAGE_URL
cd $SHARP_PACKAGE_NAME
git checkout $SHARP_PACKAGE_VERSION

# Apply patch
git apply $SCRIPT_PATH/${SHARP_PACKAGE_NAME}_${SHARP_PACKAGE_VERSION}.patch

# Build sharp
npm install --build-from-source || ret=$?
rm -rf npm package-lock.json docs coverage test

# Clone and build the Rocket.Chat image
cd $BUILD_HOME
git clone $PACKAGE_URL
cd Docker.Official.Image/$RC_MAJOR
git apply $SCRIPT_DIR/${PACKAGE_NAME}_${PACKAGE_VERSION}.patch
cp -r $BUILD_HOME/sharp $BUILD_HOME/Docker.Official.Image/$RC_MAJOR/

docker build -t rocket.chat:$PACKAGE_VERSION .
