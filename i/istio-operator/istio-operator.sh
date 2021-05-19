# ----------------------------------------------------------------------------
#
# Package        : istio-operator
# Version        : maistra-2.0.1 
# Source repo    : https://github.com/Maistra/istio-operator
# Tested on      : ubi:8.3
# Script License : Apache License 2.0
# Maintainer     : Anant Pednekar <Anant.Pednekar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash

#Update Repos
yum -y update

#Install Utilities
yum install -y gcc git make diffutils unzip curl tar 

#Install GoLang
curl -O https://dl.google.com/go/go1.13.1.linux-ppc64le.tar.gz
tar -C /usr/local -xzf go1.13.1.linux-ppc64le.tar.gz

#set Go Environment
export PATH=$PATH:/usr/local/go/bin
export GOPATH=/root/go
#Remove Tarfile
rm -rf go1.13.1.linux-ppc64le.tar.gz

#Clone repo
git clone https://github.com/maistra/istio-operator.git
cd istio-operator
git checkout tags/maistra-2.0.1 

#Build the Package
make

#Test the PAckage
#make test

