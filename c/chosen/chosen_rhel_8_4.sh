# -----------------------------------------------------------------------------
#
# Package       : chosen
# Version       : 1.0.0
# Source repo   : https://github.com/harvesthq/chosen
# Tested on     : UBI 8
# Language      : HTML
# Script License: Apache License, Version 2 or later
# Maintainer    : sachin.kakatkar@ibm.com
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#To Run: ./chosen_rhel_8_4.sh
dnf install git make gcc-c++ ruby -y
NODE_VERSION=v12.22.4
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash
source ~/.bashrc
nvm install $NODE_VERSION
PACKAGE_NAME=chosen
PACKAGE_VERSION=$1
PACKAGE_URL=https://github.com/harvesthq/chosen.git
if [ -z "$1" ]
  then
    PACKAGE_VERSION=1.0.0
fi
git clone $PACKAGE_URL
cd chosen
git checkout $PACKAGE_VERSION
npm install && gem install bundler && bundle install
npm audit fix
npm audit fix --force
npm install -g grunt-cli
npm install -g grunt
npm install --dev coffeescript
grunt build
grunt build --force
