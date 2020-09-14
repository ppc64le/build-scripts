# ----------------------------------------------------------------------------
#
# Package	     : animate.css
# Version	     : 3.5.2
# Source repo	 : https://github.com/daneden/animate.css.git
# Tested on	     : rhel_7.4
# Script License : Apache License, Version 2 or later
# Maintainer	 : Spurti Chopra <spurti@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash

# Install dependencies
sudo yum -y update
sudo yum install -y curl git tar

# Install nodejs and npm
curl https://raw.githubusercontent.com/creationix/nvm/v0.33.0/install.sh| bash
source ~/.nvm/nvm.sh
nvm install stable
nvm use stable

# Clone required project
git clone https://github.com/daneden/animate.css.git
cd animate.css

# Build and test
# Commands picked up from .travis.yml
npm install -g gulp
npm install
gulp
