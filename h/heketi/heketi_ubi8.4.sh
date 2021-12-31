# ----------------------------------------------------------------------------
#
# Package        : heketi
# Version        : v10.0.0
# Source repo    : https://github.com/heketi/heketi.git
# Tested on      : UBI 8.4
# Script License : Apache License, Version 2 or later
# Maintainer     : Sapana Khemkar <spana.khemkar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash
set -e

PACKAGE_URL=https://github.com/heketi/heketi.git
PACKAGE_NAME=heketi
PACKAGE_VERSION=v10.0.0
GO_VERSION=go1.11

yum install -y git wget tar make gcc-c++ python36 python3-pip python36-devel python27 

#install go
rm -rf /bin/go
wget https://golang.org/dl/$GO_VERSION.linux-ppc64le.tar.gz 
tar -C /bin -xzf $GO_VERSION.linux-ppc64le.tar.gz  
rm -f $GO_VERSION.linux-ppc64le.tar.gz 

#set go path
export PATH=$PATH:/bin/go/bin
export GOPATH=/home/tester/go
mkdir -p /home/tester/go
cd $GOPATH

#install glide
go get  -u github.com/Masterminds/glide

cd src/github.com/Masterminds/glide/
make build
export PATH=$PATH:/home/tester/go/src/github.com/Masterminds/glide

#verify glide installation
glide -v

#install Mercurial/hg
pip3 install Mercurial

#install other dependencies
pip3 install tox nose

#clone heketi
mkdir -p $GOPATH/src/github.com/heketi
cd $GOPATH/src/github.com/heketi
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#2 test cases failed. Same issue observed on x86
make all test


exit 0
