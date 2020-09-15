# ----------------------------------------------------------------------------
#
# Package	: ng2d3
# Version	: 7.0.1 
# Source repo	: https://github.com/swimlane/ng2d3.git
# Tested on	: RHEL_7.4
# Script License: Apache License, Version 2 or later
# Maintainer	: Yugandha Deshpande <yugandha@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash
sudo yum install -y make wget git gcc-c++.ppc64le firefox 
wget -qO- https://raw.githubusercontent.com/creationix/nvm/v0.31.1/install.sh | sh
source ~/.nvm/nvm.sh
nvm install 6
git clone https://github.com/swimlane/ng2d3.git
cd ng2d3
npm install
npm install karma-firefox-launcher

## By default tests use Chrome, but Chrome browser is not supported on ppc64le, hence modifying the configuration file to use Firefox instead.

sed -i "s|'Chrome'|'Firefox'|g" config/karma.conf.js


## Tests launches Firefox browser hence need UI.
npm run test

