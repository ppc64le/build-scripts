#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : openbao
# Version       : v2.1.0
# Source repo   : https://github.com/openbao/openbao
# Tested on     : UBI:9.3
# Language      : GO
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Simran Sirsat <Simran.Sirsat@ibm.com>
#
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=openbao
PACKAGE_VERSION=${1:-"v2.1.0"}
PACKAGE_URL=https://github.com/openbao/openbao.git

HOME_DIR=${PWD}

OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

yum update -y && yum install make git wget vim -y
 
yum install nodejs -y
npm install -g yarn

CURRENT_DIR=`pwd`
SCRIPT=$(readlink -f $0)
SCRIPT_DIR=$(dirname $SCRIPT)

rm -rf /usr/local/go
wget https://golang.org/dl/go1.23.2.linux-ppc64le.tar.gz
tar -C /usr/local -xzf go1.23.2.linux-ppc64le.tar.gz
export PATH=$PATH:/usr/local/go/bin

yum install -y yum-utils
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum install docker-ce docker-ce-cli containerd.io -y
systemctl enable docker
systemctl start docker

git clone $PACKAGE_URL $PACKAGE_NAME
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
git apply  --reject --whitespace=fix --ignore-space-change --ignore-whitespace $SCRIPT_DIR/openbao_v2.1.0_patch.patch

# Download required build tools
echo "Installing build tools"
make bootstrap


if ! make; then
        echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
	exit 1
fi

if ! make test; then
        echo "------------------$PACKAGE_NAME:test_fails---------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Test_Fails"
	exit 2
else
        echo "------------------$PACKAGE_NAME:install_and_test_success-------------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Install_and_Test_Success"
	exit 0
fi
