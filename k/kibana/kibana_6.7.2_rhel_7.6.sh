# ----------------------------------------------------------------------------
#
# Package       : kibana
# Version       : 6.7.2
# Source repo   : https://github.com/elastic/kibana.git
# Tested on     : rhel_7.6
# Script License: Apache License Version 2.0
# Maintainer    : Priya Seth <sethp@us.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

WORKDIR=$1

# The prebuilt node binaries for v10 and greater do not work on rhel ppc64le because of lower gcc version
# default gcc version : 4.8.5
# required gcc version : 4.9.1 and greater
# We have working script in http://ppc64le/build-scripts/node folder to build node using devtoolset8 on rhel 7.6
# Use above script to build node and then pass the generated node binary(./out/Release/node) as a second parameter
PATH_TO_NODE_BINARY=$2  # eg: /root/node/out/Release/node

cd $WORKDIR

# install dependencies
yum update -y  && yum install -y curl gnupg ca-certificates python gcc-c++ make git

# install nvm
curl -sL https://raw.githubusercontent.com/creationix/nvm/v0.34.0/install.sh -o install_nvm.sh
sh install_nvm.sh
source /root/.nvm/nvm.sh
nvm install 10.15.3

# replace node binary with binary built from source
mv /root/.nvm/versions/node/v10.15.3/bin/node  /root/.nvm/versions/node/v10.15.3/bin/node.old
cp $PATH_TO_NODE_BINARY  /root/.nvm/versions/node/v10.15.3/bin/
nvm use 10.15.3

# install yarn
npm install -g yarn

# install kibana
git clone https://github.com/elastic/kibana.git
cd kibana && git checkout v6.7.2
sed -i 's|10.15.2|10.15.3|g' .nvmrc
sed -i 's|10.15.2|10.15.3|g' .node-version
sed -i 's|10.15.2|10.15.3|g' package.json
nvm use

# remove chromedriver dependency
sed -i '341d' package.json

# use these steps only if you facing issues due to organizational firewall settings
#sed -i '33 s/http/https/' ./packages/kbn-ui-framework/yarn.lock
#sed -i '12041 s/http/https/' ./x-pack/yarn.lock
#sed -i '15865 s/http/https/' ./yarn.lock
#sed -i '6123 s/http/https/' ./yarn.lock


# setup environment
yarn kbn bootstrap

# install wazuh app on kibana dashboard
./bin/kibana-plugin install https://packages.wazuh.com/wazuhapp/wazuhapp-3.9.1_6.7.2.zip

# command to start kibana
# yarn start
