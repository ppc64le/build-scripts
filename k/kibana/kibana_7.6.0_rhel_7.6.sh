# ----------------------------------------------------------------------------
#
# Package       : kibana
# Version       : 7.6.0
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

cd $WORKDIR

# install dependencies
yum update -y  && yum install -y curl gnupg ca-certificates python gcc-c++ make git

# install nvm
curl -sL https://raw.githubusercontent.com/creationix/nvm/v0.34.0/install.sh -o install_nvm.sh
sh install_nvm.sh
source /root/.nvm/nvm.sh
nvm install 10.18.0
nvm use 10.18.0

# install yarn
npm install -g yarn


# install kibana
git clone https://github.com/elastic/kibana.git
cd kibana && git checkout v7.6.0
nvm use

# remove chromedriver dependency
sed -i '385d' package.json   
sed -i '40s/git-common-dir/git-dir/' /root/kibana/src/dev/register_git_hook/register_git_hook.js 
sed -i '7s/#server.host: "localhost"/server.host: "0.0.0.0"/' /root/kibana/config/kibana.yml 
sed -i '28s/localhost:9200/elasticsearch:9200/' /root/kibana/config/kibana.yml 


# setup environment
groupadd kibana && useradd kibana -g kibana
chown kibana:kibana -R /root
su kibana -c 'yarn kbn bootstrap'


# command to start kibana
# yarn start
