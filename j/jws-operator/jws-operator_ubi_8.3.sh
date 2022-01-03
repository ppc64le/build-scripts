#----------------------------------------------------------------------------
#
# Package         : web-servers/jws-operator
# Version         : 1.0.0
# Source repo     : https://github.com/web-servers/jws-operator
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


yum update -y
yum install -y gcc
yum install -y make
yum install -y wget git

#install Go
wget -c https://golang.org/dl/go1.13.linux-ppc64le.tar.gz

rm -rf /usr/local/go && tar -C /usr/local -xzf go1.13.linux-ppc64le.tar.gz

export GOROOT=/usr/local/go
export GOPATH=$HOME/go
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin

#cloning repository 
tagName=1.0.0
git clone https://github.com/web-servers/jws-operator.git
cd jws-operator
git checkout tags/$tagName
#building operator
make build
#Need to setup cluster environment to execute tests
#make test
