#!/bin/bash -ex
# ----------------------------------------------------------------------------
#
# Package	: odo
# Version	: v3.8.0
# Source repo	: https://github.com/redhat-developer/odo.git
# Tested on	: ubi 8.5
# Language      : Go
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Chandranana Naik <Naik.Chandranana@ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=odo
PACKAGE_VERSION=${1:-v3.8.0}
PACKAGE_URL=https://github.com/redhat-developer/odo.git

OS_NAME=`cat /etc/os-release | grep PRETTY_NAME | cut -d '=' -f2 | tr -d '"'`

yum install -y bash-completion podman postfix mailx git make gcc-c++ patch wget

#chrony dependency is not available in yum repository of ubi containers, however it can be installed on rhel hosts
#This build will be verified inside container
#Hence commenting below lines which are required for verification only. 

#Setting up Mail client Works only on Fyre
#sed -i "s/inet_interfaces\(.*\)/#inet_interfaces\1\ninet_interfaces = $(hostname -i | cut -d' ' -f 2), localhost, 127.0.0.1/g" /etc/postfix/main.cf
#sed -i "s/::1/#::1/g" /etc/hosts
#systemctl start postfix.service

#systemctl start chronyd
#timedatectl set-ntp yes

#Install Go
cd /tmp
wget https://golang.org/dl/go1.19.linux-ppc64le.tar.gz
tar xzf go1.19.linux-ppc64le.tar.gz
mv go /usr/local/go
ln -s /usr/local/go/bin/go /usr/local/bin/go
rm -rf go1.19.linux-ppc64le.tar.gz

export PATH=/usr/local/bin:${PATH}

#Clone repository for odo
cd $HOME
export GO_PATH=$HOME/go
mkdir -p go/src/github.com/redhat-developer
cd go/src/github.com/redhat-developer

##Cloning the repo
if ! git clone $PACKAGE_URL; then
    echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    exit 0
fi

#Build odo
export PATH=$HOME/go/src/github.com/redhat-developer/odo/:$PATH
cd odo
git checkout $PACKAGE_VERSION

if ! make bin; then
       echo "------------------$PACKAGE_NAME:Build_fails---------------------"
       echo "$PACKAGE_VERSION $PACKAGE_NAME"
       echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
       exit 1
fi

#Setting odo executable file in $PATH:
echo "export PATH=/root/go/src/github.com/redhat-developer/odo/:$PATH" >> ~/.bashrc

#Skipping test execution due to openshift power9 fyre cluster requirement
#make test-integration
#make test-e2e-all

odo version




