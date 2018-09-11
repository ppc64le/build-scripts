# ----------------------------------------------------------------------------
#
# Package       : Theia
# Version       : v0.3.12
# Source repo   : https://github.com/theia-ide/theia.git
# Tested on     : ubuntu_16.04
# Script License: Apache License, Version 2 or later
# Maintainer    : Amit Ghatwal <ghatwala@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash
CMD=`pwd`
USER=`whoami`
# Install dependencies
sudo apt-get update
sudo apt-get install -y make curl tar wget git unzip phantomjs build-essential libexpat-dev libcurl4-openssl-dev zlib1g-dev python cargo

cd /tmp && \
wget https://storage.googleapis.com/golang/go1.10.2.linux-ppc64le.tar.gz && \
sudo tar -C /usr/local -xzf go1.10.2.linux-ppc64le.tar.gz

#Set the required env. variables
export GOROOT=/usr/local/go
export PATH=$GOROOT/bin:$PATH
export GOPATH=$HOME/gopath
export PATH=$GOPATH/bin:$PATH
export QT_QPA_PLATFORM=offscreen

cd $HOME
wget https://nodejs.org/dist/v9.9.0/node-v9.9.0-linux-ppc64le.tar.gz && sudo tar -xzf node-v9.9.0-linux-ppc64le.tar.gz
export NODE_PATH=$HOME/node-v9.9.0-linux-ppc64le
export PATH=$NODE_PATH/bin:$PATH
sudo env PATH=$PATH npm install -g yarn

#Installing vscode-ripgrep
cd $HOME && wget https://static.rust-lang.org/dist/rust-1.28.0-powerpc64le-unknown-linux-gnu.tar.gz
tar -xzf rust-1.28.0-powerpc64le-unknown-linux-gnu.tar.gz
cd rust-1.28.0-powerpc64le-unknown-linux-gnu
sudo ./install.sh
cargo install ripgrep
export PATH=$HOME/.cargo/bin:$PATH

#Build and test

mkdir -p $GOPATH  && cd $HOME
sudo chown $USER.users -R /home/$USER/.config
git clone https://github.com/theia-ide/theia && cd theia
yarn --skip-integrity-check
cp -a $HOME/.cargo/bin $HOME/theia/node_modules/vscode-ripgrep/
yarn run build

#Install dugite-native
cd $HOME
git clone https://github.com/desktop/dugite-native.git
cd dugite-native/
git checkout v2.17.0
cp ./script/build-arm64.sh ./script/build-ppc64le.sh
git submodule update --init --recursive

#Make changes to $HOME/dugite-native/script/build-ppc64le.sh
cd script
patch build-ppc64le.sh < $CMD/build-ppc64le.patch
#Make changes to /<source_root>/dugite-native/script/build.sh
sed -i -e '/exit 1/ c\  bash "$DIR/build-ppc64le.sh" $SOURCE $DESTINATION $BASEDIR' build.sh
#Make changes to /<source_root>/dugite-native/script/package.sh
sed -i -e '/exit 1/ c\  GZIP_FILE="dugite-native-$VERSION-ppc64le.tar.gz"\n\  LZMA_FILE="dugite-native-$VERSION-ppc64le.lzma"' package.sh

#Building dugite-native
cd $HOME/dugite-native
bash ./script/build.sh
bash ./script/package.sh

#Replace the dugite-native library
rm -rf $HOME/theia/node_modules/dugite/git/*
cp $HOME/dugite-native/output/dugite-native-v2.17.0-ppc64le.tar.gz $HOME/theia/node_modules/dugite/git
cd $HOME/theia/node_modules/dugite/git
tar -xzf dugite-native-v2.17.0-ppc64le.tar.gz

#Run the tests
cd $HOME/theia
npx run test @theia/application-manager
npx run test @theia/application-package
npx run test @theia/callhierarchy
npx run test @theia/core
npx run test @theia/editor
npx run test @theia/file-search
npx run test @theia/filesystem
npx run test @theia/git
npx run test @theia/java
npx run test @theia/languages
npx run test @theia/markers
npx run test @theia/messages
npx run test @theia/monaco
npx run test @theia/navigator
npx run test @theia/outline-view
npx run test @theia/output
npx run test @theia/preferences
npx run test @theia/process
npx run test @theia/terminal
npx run test @theia/typescript
npx run test @theia/userstorage
npx run test @theia/variable-resolver
npx run test @theia/workspace

#Run the Theia browser example
#cd $HOME/theia/examples/browser
#yarn run start --hostname 0.0.0.0 &
