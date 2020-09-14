# ----------------------------------------------------------------------------
#
# Package       : Cookies
# Version       : 2.1.5
# Source repo   : https://github.com/reactivestack/cookies.git
# Tested on     : rhel_7.4
# Script License: Apache License, Version 2 or later
# Maintainer    : Yugandha Deshpande <yugandha@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

sudo yum -y update
sudo yum -y install git wget

# NOTE: If build fails while installing nvm, uncomment following line.
#export NVM_DIR=$HOME

wget -qO- https://raw.githubusercontent.com/creationix/nvm/v0.31.1/install.sh | sh
source ~/.nvm/nvm.sh
nvm install 9

npm install yarn -g

git clone https://github.com/reactivestack/cookies.git
cd cookies
yarn

### NOTE
# Tests starts browser thus commenting out, if need to run tests,
# uncomment following.
#sed -i 's|Chrome|Firefox|' karma.conf.js
#npm install karma-firefox-launcher
#yarn test
