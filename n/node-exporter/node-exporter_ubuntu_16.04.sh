# ----------------------------------------------------------------------------
#
# Package       : Prometheus/node-exporter
# Version       : 0.15.0
# Source repo   : https://github.com/prometheus/node_exporter
# Tested on     : ubuntu_16.04
# Script License: Apache License, Version 2 or later
# Maintainer    : Yugandha Deshpande <yugandha@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

sudo apt-get update -y
sudo apt-get install -y wget git gcc make tar

#installing Go
wget https://storage.googleapis.com/golang/go1.9.1.linux-ppc64le.tar.gz
sudo tar -C /usr/ -zxvf go1.9.1.linux-ppc64le.tar.gz
export PATH=$PATH:/usr/go/bin
export GOROOT=/usr/go
go version
export GOPATH=`pwd`/go

#Build Node_Exporter

go get github.com/prometheus/node_exporter
cd $GOPATH/src/github.com/prometheus/node_exporter
make build
make test
