#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : engine.io-client
# Version          : 6.5.3
# Source repo      : https://github.com/socketio/engine.io-client
# Tested on        : UBI:9.3
# Language         : Typescript,Javascript
# Ci-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Vinod K <Vinod.K1@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=engine.io-client
PACKAGE_URL=https://github.com/socketio/engine.io-client
PACKAGE_VERSION=${1:-6.5.3}
export NODE_VERSION=${NODE_VERSION:-20}

yum install git wget libcurl-devel tar patch -y

OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source "$HOME"/.bashrc
echo "installing nodejs $NODE_VERSION"
nvm install "$NODE_VERSION" >/dev/null
nvm use $NODE_VERSION


#1. Building ngrok version 3.4.0 from github
git clone https://github.com/bubenshchykov/ngrok.git && cd ngrok
git checkout v3.4.0
sed -i -e "47 a linuxppc64: cdn + cdnPath + 'linux-ppc64le.zip' ," download.js
npm install

#2. Building zulngrok version 4.1.0
cd ..
git clone https://github.com/rase-/zuul-ngrok.git && cd zuul-ngrok
npm install --save file:../ngrok

#3. Building engine.io-client
cd ..
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
wget https://raw.githubusercontent.com/vinodk99/build-scripts/engine.io-client6.5.3/e/engine.io-client/engine.io-client_6.5.3.patch
git apply engine.io-client_6.5.3.patch

npm install --save file:../zuul-ngrok

npm -y install --save-dev mocha

if ! npm install ; then
       echo "------------------$PACKAGE_NAME:Install_fails---------------------"
       echo "$PACKAGE_VERSION $PACKAGE_NAME"
       echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
       exit 1
fi


if ! npm test ; then
      echo "------------------$PACKAGE_NAME::Install_and_Test_fails-------------------------"
      echo "$PACKAGE_URL $PACKAGE_NAME"
      echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Fails"
      exit 2
else
      echo "------------------$PACKAGE_NAME::Install_and_Test_success-------------------------"
      echo "$PACKAGE_URL $PACKAGE_NAME"
      echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
      exit 0
fi
