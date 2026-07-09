#!/bin/bash
# ----------------------------------------------------------------------------
#
# Package       : kibana
# Version       : v8.5.0
# Source repo   : https://github.com/elastic/kibana.git
# Tested on     : UBI: 8.5
# Travis-Check  : True
# Language      : Node
# Script License: Apache License Version 2.0
# Maintainer    : Vishaka Desai <Vishaka.Desai@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

yum install -y gcc gcc-c++ git golang java-11-openjdk-devel make python38 wget unzip zip expat* glib*

# Create Symlink for python3, used by bazel
ln -s /usr/bin/python3 /usr/bin/python

# Install Node
wget https://nodejs.org/dist/v16.17.1/node-v16.17.1-linux-ppc64le.tar.gz
tar -xf node-v16.17.1-linux-ppc64le.tar.gz
cp -r node-v16.17.1-linux-ppc64le/{bin,include,lib,share} /usr/
rm -rf node-v16.17.1-linux-ppc64le.*
npm i -g yarn node-gyp @bazel/bazelisk
# Add ppc64le support in bazelisk.js
sed -i "/'x64': 'amd64',/a\    'ppc64': 'ppc64'," /usr/lib/node_modules/@bazel/bazelisk/bazelisk.js

# Build Libvips
curl -OL https://github.com/libvips/libvips/releases/download/v8.13.3/vips-8.13.3.tar.gz 
tar xf vips-8.13.3.tar.gz
cd vips-8.13.3
./configure --prefix=/usr/local LDFLAGS="-L/usr/lib -lz"
make
make install
ldconfig
cd .. && rm -rf vips-8.13.3.tar.gz

# Build Bazel
mkdir bazel/ && cd bazel 
wget https://github.com/bazelbuild/bazel/releases/download/5.3.2/bazel-5.3.2-dist.zip
unzip bazel-5.3.2-dist.zip 
bash compile.sh

export USE_BAZEL_VERSION=/bazel/output/bazel

# Build Bazelisk
cd ..
git clone -b v1.15.0 https://github.com/bazelbuild/bazelisk.git
cd bazelisk
wget https://raw.githubusercontent.com/ppc64le/build-scripts/master/k/kibana/Dockerfiles/8.5.0_ubi_8/bazelisk_v1.15.0_ppc64le.patch
git apply --ignore-whitespace ./bazelisk_v1.15.0_ppc64le.patch 
go build && ./bazelisk build --config=release //:bazelisk-linux-ppc64
cp -r bazel-out/ppc-opt-*/bin/bazelisk-linux_ppc64 /usr/lib/node_modules/@bazel/bazelisk/

# Clone Kibana
cd ..
git clone -b v8.5.0 https://github.com/elastic/kibana.git
cd kibana 
wget https://raw.githubusercontent.com/ppc64le/build-scripts/master/k/kibana/Dockerfiles/8.5.0_ubi_8/kibana_v8.5.0_ppc64le.patch
git apply --ignore-whitespace ./kibana_v8.5.0_ppc64le.patch 
yarn install 2>/dev/null || true 

# Build re2
cd ..
git clone -b 1.17.7 https://github.com/uhop/node-re2.git && cd node-re2
git submodule update --init --recursive 
npm install 
mkdir -p /kibana/.native_modules/re2/ 
gzip -c build/Release/re2.node > /kibana/.native_modules/re2/linux-ppc64-93.gz

# Bootstrap Kibana
cd /kibana 
sed -i "/case 'x64': return '64-bit';/a case 'ppc64': return '64-bit';" node_modules/node-sass/lib/extensions.js
npm rebuild node-sass 

cd /kibana/node_modules/lmdb-store/ && npm i 

# Build Kibana
cd /kibana && yarn kbn bootstrap && yarn build