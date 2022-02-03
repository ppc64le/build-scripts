#! /bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	      : request-promise-native
# Version	      : 1.0.7
# Source repo     : https://github.com/request/request-promise-native
# Tested on    	  : Ubuntu 18.04 (Docker)
# Language        : Node
# Travis-Check    : True
# Script License  : Apache License, Version 2 or later
# Maintainer	  : Sumit Dubey <sumit.dubey2@ibm.com> 
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
# ----------------------------------------------------------------------------

set -ex

WORK_DIR=`pwd`

PACKAGE_NAME=request-promise-native
PACKAGE_VERSION=v1.0.7                 
PACKAGE_URL=https://github.com/request/request-promise-native.git

# install dependencies
apt-get update -y
apt-get install git curl -y

# install nodejs
curl https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
nvm install 10.24.1
node -v

# clone package
cd $WORK_DIR
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

# to install 
npm install yarn -g
yarn --ignore-engines

# to execute tests
npm run test-publish