#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : paho.mqtt.golang
# Version       : v1.2.0
# Source repo   : https://github.com/eclipse/paho.mqtt.golang.git
# Tested on     : UBI 8.5
# Language      : go
# Travis-Check  : true
# Script License: Apache License, Version 2 or later
# Maintainer    : Ankit Paraskar <Ankit.Paraskar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
# Note :- Script test case will fail due to unavailablity for dependent package to be installed on VM.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=paho.mqtt.golang
PACKAGE_VERSION=v1.2.0
PACKAGE_URL=https://github.com/eclipse/paho.mqtt.golang.git

yum -y update && yum install -y npm ncurses git jq wget gcc-c++

# Install Go and setup working directory
wget https://golang.org/dl/go1.16.1.linux-ppc64le.tar.gz && \
    tar -C /bin -xf go1.16.1.linux-ppc64le.tar.gz && \
    mkdir -p /home/tester/go/src /home/tester/go/bin /home/tester/go/pkg

export PATH=$PATH:/bin/go/bin
export GOPATH=/home/tester/go

mkdir -p /home/tester/output
cd /home/tester

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

export PATH=$GOPATH/bin:$PATH

rm -rf $PACKAGE_NAME

git clone $PACKAGE_URL

cd $PACKAGE_NAME

git checkout $PACKAGE_VERSION


go mod init example.com/m
go mod tidy


if ! go test -v ./...; then
   echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
   echo "$PACKAGE_VERSION $PACKAGE_NAME" > /home/tester/output/test_fails
   echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | master  | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails" > /home/tester/output/version_tracker
   exit 1
else
   echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
   echo "$PACKAGE_VERSION $PACKAGE_NAME" > /home/tester/output/test_success
   echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | master | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success" > /home/tester/output/version_tracker
   exit 0
fi

