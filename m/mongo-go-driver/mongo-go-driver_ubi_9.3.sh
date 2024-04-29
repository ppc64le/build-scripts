#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : mongo-go-driver
# Version       : v1.15.0
# Source repo   : https://github.com/mongodb/mongo-go-driver
# Tested on     : UBI: 9.3
# Language      : Go
# Travis-Check  : False
# Script License: Apache License, Version 2 or later
# Maintainer    : Dipti Kumari <Shreya.Kajbaje@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#install mongodb
yum install https://repo.mongodb.com/yum/redhat/8/mongodb-enterprise/7.0/ppc64le/RPMS/mongodb-enterprise-server-7.0.8-1.el8.ppc64le.rpm

#install golang
yum install -y wget
yum install golang -y
wget https://golang.org/dl/go1.17.5.linux-ppc64le.tar.gz
tar -C /usr/local/ -xzf go1.17.5.linux-ppc64le.tar.gz
cd /usr/local/
vi ~/.bash_profile
export PATH=$PATH:/usr/local/go/bin
:wq
source ~/.bash_profile
#check version
go version
cd /usr/local/src

#clone repo
PACKAGE_PATH=github.com/mongodb/
PACKAGE_NAME=mongo-go-driver
PACKAGE_VERSION=v1.15.0
PACKAGE_URL=https://github.com/mongodb/mongo-go-driver

yum install -y make git wget gcc
yum install git -y
mkdir $PACKAGE_PATH
git clone $PACKAGE_URL
cd mongo-go-driver
git checkout v1.15.0
echo "Building github.com/mongodb/mongo-go-driver v1.15.0"
go get go.mongodb.org/mongo-driver/mongo
go mod init
go mod tidy
go mod vendor

#install python mongodb
yum install python3-devel -y
systemctl start mongod
systemctl status mongod
cd x/mongo/driver/topology/
go build -v ./...
if ! go test -v ./...; then
        echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
        exit 1
else
        echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    exit 0
fi


