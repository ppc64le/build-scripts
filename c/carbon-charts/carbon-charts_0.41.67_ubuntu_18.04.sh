#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : carbon-charts
# Version       : 0.41.67
# Source repo   : https://github.com/carbon-design-system/carbon-charts
# Tested on     : ubuntu_18.04 (Docker)
# Language      : Node
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Manik Fulpagar <Manik.Fulpagar@ibm.com>
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
PACKAGE_VERSION=v0.41.67
   
echo "Usage: $0 [-v <PACKAGE_VERSION>]"
echo "PACKAGE_VERSION is an optional paramater whose default value is 0.41.67, not all versions are supported."
PACKAGE_VERSION="${1:-$PACKAGE_VERSION}"

#Install dependencies
apt-get update && apt-get install -y git curl build-essential make python sed unzip python3 libpng-dev

#install nodejs
curl https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
nvm install 12.0.0
node -v

#Install yarn
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
apt-get update
apt-get install yarn -y
yarn -v

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

#patch
sed -i 's#"node-sass": "4.10.0"#"node-sass": "4.12.0"#g' packages/react/package.json
sed -i 's#"node-sass": "4.10.0"#"node-sass": "4.12.0"#g' packages/vue/package.json
sed -i 's#"node-sass": "4.10.0"#"node-sass": "4.12.0"#g' packages/angular/package.json
sed -i 's#"node-sass": "4.10.0"#"node-sass": "4.12.0"#g' packages/core/package.json
sed -i 's#"svelte": "^3.31.x"#"svelte": "^3.43.1"#g' packages/svelte/package.json
sed -i 's#"rollup-plugin-svelte": "^5.2.1"#"rollup-plugin-svelte": "^7.1.0"#g' packages/svelte/package.json
sed -i 's#"rollup-plugin-terser": "5.1.2"#"rollup-plugin-terser": "7.0.2"#g' packages/svelte/package.json
sed -i 's#"svelte": "3.31.x"#"svelte": "3.43.1"#g' packages/svelte/package.json
sed -i 's#"svelte-check": "^1.1.26"#"svelte-check": "^2.2.6"#g' packages/svelte/package.json
sed -i 's#"svelte-loader": "2.13.6"#"svelte-loader": "3.1.2"#g' packages/svelte/package.json

sed -i 's#formatTick(tick, i, timeInterval, timeScaleOptions)#formatTick(tick, i, ticks, timeInterval, timeScaleOptions)#g' packages/core/src/services/time-series.spec.ts

#Build 
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

#conclude
echo "Build Complete. Uncomment the following lines to run tests, they may take a while to complete."

#apt-get install -y  phantomjs firefox libxss1
#firefox --version

##manually copy chromuim binary to root folder
#export CHROME_BIN='/root/chromium_84_0_4118_0/chrome'
#chmod 777 $CHROME_BIN
#sed -i "s#'--headless'#'--headless', '--no-sandbox'#g" /opt/carbon-charts/node_modules/karma-chrome-launcher/index.js
  
#sed -i "s#this.browserDisconnectTimeout = 2000#this.browserDisconnectTimeout = 210000#g" /opt/carbon-charts/node_modules/karma/lib/config.js
#sed -i "s#this.captureTimeout = 60000#this.captureTimeout = 210000#g" /opt/carbon-charts/node_modules/karma/lib/config.js
#sed -i "s#this.browserNoActivityTimeout = 30000#this.browserNoActivityTimeout = 210000#g" /opt/carbon-charts/node_modules/karma/lib/config.js
#sed -i "s#this.browserDisconnectTolerance = 0#this.browserDisconnectTolerance = 3#g" /opt/carbon-charts/node_modules/karma/lib/config.js
#yarn test

#echo "Tests Complete!"