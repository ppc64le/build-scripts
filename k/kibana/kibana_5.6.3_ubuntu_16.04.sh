# ----------------------------------------------------------------------------
#
# Package	: Kibana
# Version	: 5.6.3
# Source repo	: https://github.com/elastic/kibana.git
# Tested on	: ubuntu_16.04
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

sudo apt-get update -y
sudo apt-get install -y wget tar git curl zip hostname openjdk-8-jdk make python g++ 
export ES_JAVA_OPTS="-Xms40m"

git clone https://github.com/elastic/kibana.git 
cd kibana
git checkout v5.6.3
wget -qO- https://raw.githubusercontent.com/creationix/nvm/v0.31.1/install.sh | sh
source ~/.nvm/nvm.sh
npm install grunt babel-preset-react babel-plugin-add-module-exports babel-plugin-transform-async-generator-functions babel-plugin-transform-object-rest-spread babel-plugin-transform-class-properties babel-preset-env babel-register 
nvm install "$(cat .node-version)"
npm install 
npm run test:server
