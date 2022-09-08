#!/bin/bash -e
# ----------------------------------------------------------------------------
# Package          : grafana
# Version          : v9.1.3
# Source repo      : https://github.com/grafana/grafana.git
# Tested on        : UBI 8.5
# Language         : Go
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Vinod K <Vinod.K1@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#   
# ----------------------------------------------------------------------------
yum -y update
yum -y install wget git gcc-c++

# Install GO
wget https://golang.org/dl/go1.18.1.linux-ppc64le.tar.gz
tar -C /usr/local -xzf go1.18.1.linux-ppc64le.tar.gz
export PATH=$PATH:/usr/local/go/bin

#Install Node
yum install -y openssl-devel.ppc64le curl
curl https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash
source ~/.nvm/nvm.sh
nvm install node

#Build Grafana
mkdir grafana
cd grafana
export GOPATH=`pwd`
git clone https://github.com/grafana/grafana.git
cd grafana
git checkout v9.1.3
go mod verify

go run build.go setup
go run build.go build

#Test Grafana
go test -v ./pkg/...
