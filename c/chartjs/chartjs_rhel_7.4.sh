# ----------------------------------------------------------------------------
#
# Package       : Chartjs
# Version       : 2.7.1
# Source repo   : https://github.com/chartjs/Chart.js.git
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
sudo yum -y install wget git
get -qO- https://raw.githubusercontent.com/creationix/nvm/v0.31.1/install.sh | sh
source $HOME/.nvm/nvm.sh
nvm install stable
nvm use stable

git clone https://github.com/chartjs/Chart.js.git
cd Chart.js
npm install
npm install -g gulp
gulp build

# NOTE: It needs browser while testing. Also For ppc64le, in configuration
# files (karma.conf.js), browser must be changed from Chrome to Firefox.

#gulp test
