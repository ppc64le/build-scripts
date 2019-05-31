# ----------------------------------------------------------------------------
#
# Package       : kibana
# Version       : 6.5.4
# Source repo   : https://github.com/elastic/kibana.git
# Tested on     : ubuntu_18.04
# Script License: Apache License Version 2.0
# Maintainer    : Shivani Junawane <shivanij@us.ibm.com>
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
cd $WORKDIR

# install dependencies
apt-get -y update && apt-get install -y curl gnupg ca-certificates python g++ make git

# install nvm
curl -sL https://raw.githubusercontent.com/creationix/nvm/v0.34.0/install.sh -o install_nvm.sh
sh install_nvm.sh
source /root/.profile
nvm install 8.14.0

# install yarn
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
apt-get -y update && apt-get install -y yarn

# install kibana
git clone https://github.com/elastic/kibana.git
cd kibana && git checkout v6.5.4
nvm use

# remove chromedriver dependency
sed -i '306d' package.json

# use these steps only if you facing issues due to organizational firewall settings
#sed -i '33 s/http/https/' ./packages/kbn-ui-framework/yarn.lock
#sed -i '12041 s/http/https/' ./x-pack/yarn.lock
#sed -i '15865 s/http/https/' ./yarn.lock
#sed -i '6123 s/http/https/' ./yarn.lock


# setup environment
yarn kbn bootstrap

# install wazuh app on kibana dashboard
./bin/kibana-plugin install https://packages.wazuh.com/wazuhapp/wazuhapp-3.8.2_6.5.4.zip

# command to start kibana
# yarn start
