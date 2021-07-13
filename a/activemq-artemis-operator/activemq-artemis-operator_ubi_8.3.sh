#----------------------------------------------------------------------------
#
# Package         : artemiscloud/activemq-artemis-operator
# Version         : v0.19.2
# Source repo     : https://github.com/artemiscloud/activemq-artemis-operator
# Tested on       : ubi:8
# Script License  : Apache License, Version 2.0
# Maintainer      : srividya chittiboina <Srividya.Chittiboina@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash
# ----------------------------------------------------------------------------
# Prerequisites:
#
# docker must be installed and running for building operator image.
#
# Go version 1.13.1 or later must be installed.
# Git must be installed
# python must be installed
# ----------------------------------------------------------------------------
#git installation
dnf install git

#golang installation (as a part of installing go we need wget need to be installed)
dnf install wget

wget -c https://golang.org/dl/go1.16.4.linux-ppc64le.tar.gz

rm -rf /usr/local/go && tar -C /usr/local -xzf go1.16.4.linux-ppc64le.tar.gz

export GOROOT=/usr/local/go
export GOPATH=$HOME/go
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin

#GCC installation
dnf install gcc


#Python installation 
yum install python3

tagName=v0.19.2
#cloning repository to your local file system
git clone https://github.com/artemiscloud/activemq-artemis-operator.git


#swtiching to our repository
cd activemq-artemis-operator
git checkout tags/$tagName


#building operator
go build -v -o operator ./cmd/manager


#for building operator image
#docker build -f ./build/Dockerfile -t activemq-artemis-operator:latest .
#Executing tests
#cd /activemq-artemis-operator/test/integration
#go test
#cd /activemq-artemis-operator/test/integration/v2alpha2_test
#go test
#cd /activemq-artemis-operator/test/integration
#/activemq-artemis-operator/test/utils/config
#go test







