# ----------------------------------------------------------------------------
#
# Package       : carbon-charts
# Version       : 0.41.67
# Tested on     : UBI 8.3 (Docker)
# Script License: Apache License, Version 2 or later
# Maintainer    : Sumit Dubey <Sumit.Dubey2@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash

set -ex

#Variables
REPO=https://github.com/carbon-design-system/carbon-charts.git
PACKAGE_VERSION=0.41.67

echo "Usage: $0 [-v <PACKAGE_VERSION>]"
echo "PACKAGE_VERSION is an optional paramater whose default value is 0.41.67, not all versions are supported."

PACKAGE_VERSION="${1:-$PACKAGE_VERSION}"

#install dependencies
yum install git make gcc-c++ python2 sed unzip libpng-devel -y
cp /usr/bin/python2.7 /usr/bin/python3

dnf module install -y nodejs:12
curl --silent --location https://dl.yarnpkg.com/rpm/yarn.repo | tee /etc/yum.repos.d/yarn.repo
rpm --import https://dl.yarnpkg.com/rpm/pubkey.gpg
dnf install -y yarn

#clone the repo
cd /opt && git clone $REPO
cd carbon-charts/
git checkout v$PACKAGE_VERSION

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

#build
yarn install
yarn build-all

#conclude
echo "Build Complete. Uncomment the following lines to run tests, they may take a while to complete."

#rm -f /usr/bin/python3
#dnf remove -y module nodejs
#yum install -y python3 libarchive
#dnf -y install \
#http://mirror.centos.org/centos/8/BaseOS/ppc64le/os/Packages/centos-linux-repos-8-3.el8.noarch.rpm \
#http://mirror.centos.org/centos/8/BaseOS/ppc64le/os/Packages/centos-gpg-keys-8-3.el8.noarch.rpm
#yum install -y firefox
#cd /opt
#git clone https://github.com/ppc64le/build-scripts.git
#cd build-scripts/c/chromium
#sed -i "s#./chromedriver --version#echo \$(pwd) > /opt/chrome.binary#g" Chromium_84.0.4118.0_UBI.sh
#./Chromium_84.0.4118.0_UBI.sh
#CHROME_DIR=$(cat /opt/chrome.binary)
#export CHROME_BIN=$CHROME_DIR/chrome
#chmod 777 $CHROME_BIN
#sed -i "s#'--headless'#'--headless', '--no-sandbox'#g" /opt/carbon-charts/node_modules/karma-chrome-launcher/index.js
#dnf module install -y nodejs:12
#curl --silent --location https://dl.yarnpkg.com/rpm/yarn.repo | tee /etc/yum.repos.d/yarn.repo
#rpm --import https://dl.yarnpkg.com/rpm/pubkey.gpg
#dnf install -y yarn
#cd /opt/carbon-charts
#sed -i "s#this.browserDisconnectTimeout = 2000#this.browserDisconnectTimeout = 210000#g" /opt/carbon-charts/node_modules/karma/lib/config.js
#sed -i "s#this.captureTimeout = 60000#this.captureTimeout = 210000#g" /opt/carbon-charts/node_modules/karma/lib/config.js
#sed -i "s#this.browserNoActivityTimeout = 30000#this.browserNoActivityTimeout = 210000#g" /opt/carbon-charts/node_modules/karma/lib/config.js
#sed -i "s#this.browserDisconnectTolerance = 0#this.browserDisconnectTolerance = 3#g" /opt/carbon-charts/node_modules/karma/lib/config.js
#yarn test
#echo "Tests Complete!"
