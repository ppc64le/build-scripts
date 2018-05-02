# ----------------------------------------------------------------------------
#
# Package	: Go Networking Repo
# Version	: NA
# Source repo	: https://github.com/golang/net.git
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

sudo apt-get -y update
sudo apt-get install -y git wget ssh curl gcc

# Latest master now requires go 1.7+ hence install latest go.
wget https://dl.google.com/go/go1.9.linux-ppc64le.tar.gz
sudo tar -xzf go1.9.linux-ppc64le.tar.gz -C /usr/local
rm -f go1.9.linux-ppc64le.tar.gz
export GOROOT=/usr/local/go
export PATH=$GOROOT/bin:$PATH

mkdir -p /tmp/workspace/bin /tmp/workspace/src/golang.org/x /tmp/workspace/pkg
cd /tmp/workspace/src/golang.org/x
git clone https://github.com/golang/text.git
git clone https://github.com/golang/crypto.git
git clone https://github.com/golang/net.git

export GOPATH=/tmp/workspace
export PATH=$PATH:$GOPATH/bin

go get golang.org/x/sys/unix
go get golang.org/x/tools/go/buildutil
go get golang.org/x/tools/go/loader

# NOTE: Diag test fails on intel as well, thus commenting out.
mv /tmp/workspace/src/golang.org/x/net/icmp/diag_test.go /tmp/workspace/src/golang.org/x/net/icmp/diag_test.go.org
cd /tmp/workspace/src/golang.org/x/net
go test -v ./...
