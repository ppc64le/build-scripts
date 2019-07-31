# ----------------------------------------------------------------------------
#
# Package       : wazuh
# Version       : 3.8.2
# Source repo   : https://github.com/wazuh/wazuh.git
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


# install dependencies
apt-get update -y && apt-get install -y python gcc make libc6-dev curl policycoreutils automake autoconf libtool


# install nvm
curl -sL https://raw.githubusercontent.com/creationix/nvm/v0.34.0/install.sh -o install_nvm.sh
sh install_nvm.sh
source /root/.bashrc
nvm install 8.14.0
npm config set user 0

# instal wazuh-api
git clone  https://github.com/wazuh/wazuh-api.git
cd wazuh-api
git checkout v3.8.2

# uncomment below 5 lines only if you are facing error with wazuh-api service getting into failed
#UID_OSSEC=`id -u ossec`
#GID_OSSEC=`id -g ossec`
#sed -i '27d;28d;29d;30d;31d' ./helpers/logger.js
#sed -i "22s/0/$UID_OSSEC/g" ./helpers/logger.js
#sed -i "23s/0/$GID_OSSEC/g" ./helpers/logger.js


./install_api.sh


