#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : carbon-charts
# Version       : 0.16.25, 0.29.1, 0.40.0, 0.40.14, 0.41.10, 0.41.15
# Source repo   : https://github.com/carbon-design-system/carbon-charts
# Tested on     : ubuntu_18.04 (Docker)
# Language      : Node
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Manik Fulpagar <manik.fulpagar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -ex

#Variables
PACKAGE_NAME="carbon-charts"
PACKAGE_URL=https://github.com/carbon-design-system/carbon-charts.git
PACKAGE_VERSION=v0.41.15
   
echo "Usage: $0 [-v <PACKAGE_VERSION>]"
echo "PACKAGE_VERSION is an optional paramater whose default value is v0.41.15, not all versions are supported."
PACKAGE_VERSION="${1:-$PACKAGE_VERSION}"

#install dependencies
apt-get update && apt-get install -y git curl build-essential make python sed unzip python3  libpng-dev

#Install nodejs
curl https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
nvm install 10.13.0
node -v

#Install yarn
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
apt-get update
apt-get install yarn -y
yarn --version
   
export HOME=/home/tester

mkdir -p /home/tester/output
cd /home/tester

ln -s /usr/bin/python3 /bin/python

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

function get_checkout_url(){
        url=$1
        CHECKOUT_URL=`python3 -c "url='$url';github_url=url.split('tree')[0];print(github_url);"`
        echo $CHECKOUT_URL
}

function get_working_path(){
        url=$1
        CHECKOUT_URL=`python3 -c "url='$url';github_url,uri=url.split('tree');uris=uri.split('/');print('/'.join(uris[2:]));"`
        echo $CHECKOUT_URL
}

CLONE_URL=$(get_checkout_url $PACKAGE_URL)

if [ "$PACKAGE_URL" = "$CLONE_URL" ]; then
        WORKING_PATH="./"
else
        WORKING_PATH=$(get_working_path $PACKAGE_URL)
fi

if ! git clone $CLONE_URL $PACKAGE_NAME; then
	echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/clone_fails
	echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails" > /home/tester/output/version_tracker
	exit 1
fi

cd /home/tester/$PACKAGE_NAME
git checkout $PACKAGE_VERSION

# run the test command from test.sh
# Build and test package

if ! yarn install; then
     	echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/install_fails
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails" > /home/tester/output/version_tracker
	exit 1
fi
  
if ! yarn build-all; then
     	echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/install_fails
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails" > /home/tester/output/version_tracker
	exit 1
fi

#---------------------------
 #apt-get install -y  phantomjs firefox libxss1
 #firefox --version
 #manually copy chromuim binary to root folder
 #export CHROME_BIN='/root/chromium_84_0_4118_0/chrome'
 #chmod 777 $CHROME_BIN
 #sed -i "s#'--headless'#'--headless', '--no-sandbox'#g" /opt/carbon-charts/node_modules/karma-chrome-launcher/index.js
  
 #sed -i "s#this.browserDisconnectTimeout = 2000#this.browserDisconnectTimeout = 210000#g" /opt/carbon-charts/node_modules/karma/lib/config.js
 #sed -i "s#this.captureTimeout = 60000#this.captureTimeout = 210000#g" /opt/carbon-charts/node_modules/karma/lib/config.js
 #sed -i "s#this.browserNoActivityTimeout = 30000#this.browserNoActivityTimeout = 210000#g" /opt/carbon-charts/node_modules/karma/lib/config.js
 #sed -i "s#this.browserDisconnectTolerance = 0#this.browserDisconnectTolerance = 3#g" /opt/carbon-charts/node_modules/karma/lib/config.js
 #yarn test

#echo "Tests Complete!"