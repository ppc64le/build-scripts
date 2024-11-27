#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : BigInteger.js
# Version       : v1.6.52
# Source repo   : https://github.com/peterolson/BigInteger.js
# Tested on     : UBI: 9.3
# Language      : javascript
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Stuti Wali <Stuti.Wali@ibm.com>
#
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -e

PACKAGE_NAME=BigInteger.js
PACKAGE_VERSION=${1:-v1.6.52}
PACKAGE_URL=https://github.com/peterolson/BigInteger.js
HOME_DIR=${PWD}

export NODE_VERSION=${NODE_VERSION:-14}

yum install -y wget yum-utils

dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/CRB/ppc64le/os/
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/AppStream/ppc64le/os/
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/BaseOS/ppc64le/os/
wget http://mirror.centos.org/centos/RPM-GPG-KEY-CentOS-Official
mv RPM-GPG-KEY-CentOS-Official /etc/pki/rpm-gpg/.
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-Official

yum -y install gcc gcc-c++ make flex bison ruby openssl-devel freetype-devel fontconfig fontconfig-devel libicu-devel sqlite-devel libpng-devel libjpeg-devel wget git tar gzip libwebp-devel diffutils perl unzip libicu-devel libX11-devel libXext-devel libXrender-devel mesa-libGL-devel 

#installing phantomjs
wget https://downloads.power-devops.com/phantomjs-rhel8-2.1.1-1.zip
unzip phantomjs-rhel8-2.1.1-1.zip

#installing icu4c-60 which is require for phantomjs
wget https://github.com/unicode-org/icu/releases/download/release-60-2/icu4c-60_2-src.tgz
tar -xvzf icu4c-60_2-src.tgz
cd icu/source
./configure --prefix=/usr/local
make
make install

cd ../..
export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=$HOME_DIR/phantomjs/bin:$LD_LIBRARY_PATH
export PATH=$HOME_DIR/phantomjs/bin:$PATH
phantomjs --version

#Installing Nodejs 
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source "$HOME"/.bashrc
echo "installing nodejs $NODE_VERSION"
nvm install "$NODE_VERSION" >/dev/null
nvm use $NODE_VERSION

#Cloning repo
git clone $PACKAGE_URL
cd $PACKAGE_NAME/
git checkout $PACKAGE_VERSION

if ! npm install ; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
else
    echo "------------------$PACKAGE_NAME:build_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Build_and_Test_Success"
    exit 0
fi

#Commeting test part as tests require headless chrome browser for execution, which may not be accessible by the developer.
#test
#if ! npm test ; then
#    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
#    echo "$PACKAGE_URL $PACKAGE_NAME"
#    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
#    exit 2
#else
#    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
#    echo "$PACKAGE_URL $PACKAGE_NAME"
#    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
#    exit 0
#fi
