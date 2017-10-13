# ----------------------------------------------------------------------------
#
# Package	: collectd_exporter
# Version	: 0.3.1
# Source repo	: https://github.com/prometheus/collectd_exporter
# Tested on	: ubuntu_16.04
# Script License: Apache License, Version 2 or later
# Maintainer	: Yugandha Deshpande <yugandha@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

# Install dependencies.
sudo apt-get update
sudo apt-get install wget git gcc make tar -y

# installing Go
wget https://storage.googleapis.com/golang/go1.9.1.linux-ppc64le.tar.gz
sudo tar -C /usr/ -zxvf go1.9.1.linux-ppc64le.tar.gz
export PATH=$PATH:/usr/go/bin
export GOROOT=/usr/go
go version
export GOPATH=`pwd`/go

# Build Collectd_Exporter
go get github.com/prometheus/collectd_exporter
cd $GOPATH/src/github.com/prometheus/collectd_exporter
make promu
sudo ln -s $GOPATH/bin/promu /bin/promu
make
make test
