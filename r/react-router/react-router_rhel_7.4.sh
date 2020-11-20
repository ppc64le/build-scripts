# ----------------------------------------------------------------------------
#
# Package       : react-router
# Version       : 4.2.2
# Source repo   : https://github.com/ReactTraining/react-router
# Tested on     : rhel_7.4
# Script License: Apache License, Version 2 or later
# Maintainer    : Priya Seth<sethp@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

sudo yum update -y && sudo yum install -y curl wget

export NVM_DIR=$HOME/.nvm
curl https://raw.githubusercontent.com/creationix/nvm/v0.33.0/install.sh| bash
source ~/.nvm/nvm.sh
nvm install 9.11.1
nvm use 9.11.1

wget https://github.com/ReactTraining/react-router/archive/v4.2.2.tar.gz
tar -zxvf v4.2.2.tar.gz
cd react-router-4.2.2
npm install
npm run build
npm test
