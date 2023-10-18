#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : wazuh-api
# Version          : v3.13.6
# Source repo      : https://github.com/wazuh/wazuh-api
# Tested on        : UBI 8.7
# Language         : Javascript
# Travis-Check     : True
# Script License   : GNU General Public License v2.0
# Maintainer       : Vinod K <Vinod.K1@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=wazuh-api
PACKAGE_VERSION=${1:-v3.13.6}
PACKAGE_URL=https://github.com/wazuh/wazuh-api

HOME_DIR=${PWD}

OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

yum install -y git wget curl make sudo cmake gcc gcc-c++ autoconf procps diffutils libffi-devel sqlite-libs sqlite-devel python38 python38-devel python3-policycoreutils automake libtool openssl-devel yum-utils libstdc++-static  hostname

NODE_VERSION=v18.9.0
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash
source ~/.bashrc
nvm install $NODE_VERSION

#To build wazuh-api we require wazuh-server binaries to build 
git clone https://github.com/wazuh/wazuh
cd wazuh
git checkout v3.13.6

make deps -C src TARGET=server -j2
make -C src TARGET=server -j2

echo 'USER_LANGUAGE="en"' > ./etc/preloaded-vars.conf
echo "" >> ./etc/preloaded-vars.conf
echo 'USER_NO_STOP="y"' >> ./etc/preloaded-vars.conf
echo "" >> ./etc/preloaded-vars.conf
echo 'USER_INSTALL_TYPE="server"' >> ./etc/preloaded-vars.conf
echo "" >> ./etc/preloaded-vars.conf
echo "USER_DIR=/var/ossec" >> ./etc/preloaded-vars.conf
echo "" >> ./etc/preloaded-vars.conf
echo 'USER_ENABLE_EMAIL="n"' >> ./etc/preloaded-vars.conf
echo "" >> ./etc/preloaded-vars.conf
echo 'USER_ENABLE_SYSCHECK="y"' >> ./etc/preloaded-vars.conf
echo "" >> ./etc/preloaded-vars.conf
echo 'USER_ENABLE_ROOTCHECK="y"' >> ./etc/preloaded-vars.conf
echo "" >> ./etc/preloaded-vars.conf
echo 'USER_ENABLE_OPENSCAP="y"' >> ./etc/preloaded-vars.conf
echo "" >> ./etc/preloaded-vars.conf
echo 'USER_ENABLE_SYSCOLLECTOR="n"' >> ./etc/preloaded-vars.conf
echo "" >> ./etc/preloaded-vars.conf
echo 'USER_ENABLE_SCA="n"' >> ./etc/preloaded-vars.conf
echo "" >> ./etc/preloaded-vars.conf
echo 'USER_WHITE_LIST="n"' >> ./etc/preloaded-vars.conf
echo "" >> ./etc/preloaded-vars.conf
echo 'USER_ENABLE_SYSLOG="y"' >> ./etc/preloaded-vars.conf
echo "" >> ./etc/preloaded-vars.conf
echo 'USER_ENABLE_AUTHD="y"' >> ./etc/preloaded-vars.conf
echo "" >> ./etc/preloaded-vars.conf
echo 'USER_AUTO_START="y"' >> ./etc/preloaded-vars.conf
echo "" >> ./etc/preloaded-vars.conf
sudo sh install.sh
rm ./etc/preloaded-vars.conf
cd ..

cd $HOME_DIR
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

./install_api.sh

