# ----------------------------------------------------------------------------
#
# Package       : wazuh
# Version       : 3.8.2
# Source repo   : https://github.com/wazuh/wazuh.git
# Tested on     : rhel_7.6
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
yum update -y && yum install -y make gcc-c++ policycoreutils automake autoconf libtool hostname

# instal wazuh manager/agent.
# The script will ask which component you want to install
# What kind of installation do you want (manager, agent, local, hybrid or help)? 
curl -Ls https://github.com/wazuh/wazuh/archive/v3.8.2.tar.gz | tar zx
cd wazuh-*
./install.sh


