# ----------------------------------------------------------------------------
#
# Package       : wazuh
# Version       : 3.9.1
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

# Note: Some packages require epel and rhel-7-for-power-le-optional-rpms to be enabled
# You can enable it using following command - $ yum-config-manager --enable rhel-7-for-power-le-optional-rpms


# install dependencies
yum update -y && yum install -y make gcc-c++ git openssh-clients gnupg policycoreutils-python automake autoconf libtool hostname yum-utils zlib-devel valgrind valgrind-devel tix tix-devel bluez-libs bluez-libs-devel openssl openssl-devel python34
yum-builddep python34 -y

# instal wazuh
curl -Ls https://github.com/wazuh/wazuh/archive/v3.9.1.tar.gz | tar zx
cd wazuh-*
sed -i 's|--index-url=file://${ROUTE_PATH}/${EXTERNAL_CPYTHON}/Dependencies/simple||g' src/Makefile
./install.sh

