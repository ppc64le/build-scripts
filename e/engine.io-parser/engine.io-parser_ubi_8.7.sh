#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : engine.io-parser
# Version          : 5.0.6
# Source repo      : https://github.com/socketio/engine.io-parser
# Tested on        : UBI 8.7
# Language         : Typescript,Javascript
# Travis-Check     : True
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

PACKAGE_VERSION=${1:-5.0.6}
PACKAGE_NAME=engine.io-parser
PACKAGE_URL=https://github.com/socketio/engine.io-parser
HOME_DIR=${PWD}

yum install git wget curl tar -y

cd $HOME_DIR
curl https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
nvm install 14
nvm use 14

#1. Building ngrok version 3.4.0 from github
git clone https://github.com/bubenshchykov/ngrok.git && cd ngrok
git checkout v3.4.0
sed -i -e "47 a linuxppc64: cdn + cdnPath + 'linux-ppc64le.zip' ," download.js
npm install --unsafe-perm

#2. Building zulngrok version 4.1.0
cd ..
git clone https://github.com/rase-/zuul-ngrok.git && cd zuul-ngrok
npm install --unsafe-perm --save file:../ngrok
cd ..

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
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
      echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Build_and_Test_Success"
      exit 2
else
      echo "------------------$PACKAGE_NAME::Install_and_Test_success-------------------------"
      echo "$PACKAGE_URL $PACKAGE_NAME"
      echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Build_and_Test_Success"
      exit 0
fi


