#!/bin/bash
# ----------------------------------------------------------------------------
#
# Package       : kibana
# Version       : v8.1.1
# Source repo   : https://github.com/elastic/kibana.git
# Tested on     : UBI: 8.5
# Travis-Check  : True
# Language      : Node
# Script License: Apache License Version 2.0
# Maintainer    : Muskaan Sheik <Muskaan.Sheik@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

yum install -y gcc gcc-c++ git golang java-11-openjdk-devel make python38 wget unzip zip sudo

# Create Symlink for python3, used by bazel
ln -s /usr/bin/python3 /usr/bin/python

# Install Node
wget https://nodejs.org/dist/v16.13.2/node-v16.13.2-linux-ppc64le.tar.gz 
tar -xf node-v16.13.2-linux-ppc64le.tar.gz 
cp -r node-v16.13.2-linux-ppc64le/{bin,include,lib,share} /usr/ 
rm -rf node-v16.13.2-linux-ppc64le* 
npm install -g yarn node-gyp @bazel/bazelisk@1.10.1 
# Add ppc64le support in bazelisk.js
sed -i "/'x64': 'amd64',/a\    'ppc64': 'ppc64'," /usr/lib/node_modules/@bazel/bazelisk/bazelisk.js

# Install Bazel
cd .. && mkdir bazel/ && cd bazel 
wget https://github.com/bazelbuild/bazel/releases/download/4.2.1/bazel-4.2.1-dist.zip 
unzip bazel-4.2.1-dist.zip 
bash compile.sh

export USE_BAZEL_VERSION=/bazel/output/bazel

# Install Bazelisk
cd ..
wget https://github.com/bazelbuild/bazelisk/archive/refs/tags/v1.10.1.zip 
unzip v1.10.1.zip
cd /bazelisk-1.10.1 
wget https://raw.githubusercontent.com/ppc64le/build-scripts/master/k/kibana/Dockerfiles/8.1.0_ubi_8/bazelisk_v1.10.1_ppc64le.patch
git apply --ignore-whitespace ./bazelisk_v1.10.1_ppc64le.patch 
go build && ./bazelisk build --config=release //:bazelisk-linux-ppc64 
cp -r bazel-out/ppc-opt-*/bin/bazelisk-linux_ppc64 /usr/lib/node_modules/@bazel/bazelisk/

# Clone Kibana
cd ..
git clone -b v8.1.1 https://github.com/elastic/kibana.git
cd /kibana 
wget https://raw.githubusercontent.com/ppc64le/build-scripts/master/k/kibana/kibana_v8.1.1_ppc64le.patch
git apply --ignore-whitespace kibana_v8.1.1_ppc64le.patch 
yarn install 2>/dev/null || true # this is expected to fail, we just need it to rebuild lmdb-store before bootstrapping

# Install re2
cd ..
git clone -b 1.17.4 https://github.com/uhop/node-re2.git && cd node-re2 
git submodule update --init --recursive 
npm install 
mkdir -p /kibana/.native_modules/re2/ 
gzip -c build/Release/re2.node > /kibana/.native_modules/re2/linux-ppc64-93.gz

cd /kibana 
sed -i "/case 'x64': return '64-bit';/a case 'ppc64': return '64-bit';" node_modules/node-sass/lib/extensions.js  
npm rebuild node-sass 
yarn kbn bootstrap 2>/dev/null || true

cd /kibana/node_modules/lmdb-store/ && npm i 

# Build Kibana
cd /kibana  && yarn kbn bootstrap && yarn build