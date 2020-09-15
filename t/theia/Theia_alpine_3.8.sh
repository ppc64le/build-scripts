# ----------------------------------------------------------------------------
#
# Package       : Theia
# Version       : v0.3.15
# Source repo   : https://github.com/theia-ide/theia.git
# Tested on     : alpine3.8
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
cmd=`pwd`
user1=`whoami`
# Install dependencies
sudo apk --update add --no-cache git zlib-dev curl curl-dev expat expat-dev file go go-tools xz perl-utils nodejs nodejs-npm

#Set the required env. variables
export GOROOT=/usr/lib/go
export PATH=$GOROOT/bin:$PATH

#install yarn
sudo npm install -g yarn

#install cargo and vscode-ripgrep
sudo -s <<EOF
cd /root
mkdir test262 && cd test262
git clone https://github.com/mksully22/ppc64le_alpine_rust_1.26.2.git
cp -a  ppc64le_alpine_rust_1.26.2/* .
sed -i '/apk add alpine-sdk/c\apk add alpine-sdk gcc llvm-libunwind-dev cmake file libffi-dev llvm5-dev llvm5-test-utils python2 tar zlib-dev gcc llvm-libunwind-dev musl-dev util-linux bash' build_rust262.sh
./build_rust262.sh
cargo install ripgrep
chown -R $user1:$user1 /root/.cargo/bin
su $user1
EOF

#Build and test
cd $HOME
git clone https://github.com/theia-ide/theia && cd theia
git checkout v0.3.15
#sudo chown -R $user1:$user1 $HOME/theia
yarn --skip-integrity-check
sudo cp -a /root/.cargo/bin $HOME/theia/node_modules/vscode-ripgrep/
cd $HOME/theia
yarn run build

#Build dugite-native
cd $HOME
git clone https://github.com/desktop/dugite-native.git
cd dugite-native/
git checkout v2.17.0
cp ./script/build-arm64.sh ./script/build-ppc64le.sh
git submodule update --init --recursive

#Make changes to $HOME/dugite-native/script/build-ppc64le.sh
cd script
patch build-ppc64le.sh < $cmd/build-ppc64le.patch
#Make changes to /<source_root>/dugite-native/script/build.sh
sed -i -e '/exit 1/ c\  bash "$DIR/build-ppc64le.sh" $SOURCE $DESTINATION $BASEDIR' build.sh
#Make changes to /<source_root>/dugite-native/script/package.sh
sed -i -e '/exit 1/ c\  GZIP_FILE="dugite-native-$VERSION-ppc64le.tar.gz"\n\  LZMA_FILE="dugite-native-$VERSION-ppc64le.lzma"' package.sh
#Add the REG_STARTEND flag
sudo sed -i '/#define REG_ENOSYS      -1/ i #define REG_STARTEND    00004' /usr/include/regex.h

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
