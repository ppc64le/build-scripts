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

# instal wazuh
curl -Ls https://github.com/wazuh/wazuh/archive/v3.8.2.tar.gz | tar zx
cd wazuh-*
./install.sh


