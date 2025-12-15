#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : moment-timezone
# Version       : 0.5.45
# Source repo   : https://github.com/moment/moment-timezone
# Tested on     : UBI: 8.7
# Language      : JavaScript
# Ci-Check  : True
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

# Variables
PACKAGE_NAME="moment-timezone"
PACKAGE_VERSION=${1:-"0.5.45"}
PACKAGE_URL=https://github.com/moment/moment-timezone
NODE_VERSION=${NODE_VERSION:-18.19.0}
HOME_DIR=`pwd`


#Install dependencies
yum install -y yum-utils git fontconfig-devel wget curl libXcomposite libXcursor procps-ng python38 python38-devel git gcc gcc-c++ libffi libffi-devel ncurses jq make cmake
cd $HOME_DIR 

yum-config-manager --add-repo https://vault.centos.org/8.5.2111/AppStream/ppc64le/os/
yum-config-manager --add-repo https://vault.centos.org/8.5.2111/Devel/ppc64le/os/
yum-config-manager --add-repo https://vault.centos.org/8.5.2111/PowerTools/ppc64le/os/
yum-config-manager --add-repo https://vault.centos.org/8.5.2111/BaseOS/ppc64le/os/

wget http://mirror.centos.org/centos/RPM-GPG-KEY-CentOS-Official
mv RPM-GPG-KEY-CentOS-Official /etc/pki/rpm-gpg/.
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-Official

yum install -y firefox liberation-fonts xdg-utils


#Install node
wget https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-ppc64le.tar.gz
tar -xzf node-v${NODE_VERSION}-linux-ppc64le.tar.gz
export PATH=$HOME_DIR/node-v${NODE_VERSION}-linux-ppc64le/bin:$PATH
node -v
npm -v
export NODE_OPTIONS=--dns-result-order=ipv4first



# Clone the repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION


# Build package
if !(npm install --force); then
    echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_Fails"
    exit 1
else
    echo "------------------$PACKAGE_NAME:build_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Build_and_Test_Success"
    exit 0
fi

# Run test cases
if ! npm test; then
    echo "------------------$PACKAGE_NAME:build_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:build_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Build_and_Test_Success"
    exit 0
fi