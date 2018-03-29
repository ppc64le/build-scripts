# ----------------------------------------------------------------------------
#
# Package	: nats-streaming-server
# Version	: 0.9.1
# Source repo	: https://github.com/nats-io/nats-streaming-server
# Tested on	: ubuntu_16.04
# Script License: Apache License, Version 2 or later
# Maintainer	: Priya Seth <sethp@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

#Install the required dependencies
sudo apt-get update -y
sudo apt-get install -y  wget tar git rsync build-essential

cd /tmp && \
wget https://storage.googleapis.com/golang/go1.8.7.linux-ppc64le.tar.gz && \
sudo tar -C /usr/local -xzf go1.8.7.linux-ppc64le.tar.gz && \

#Set the required env. variables
export PATH=/usr/local/go/bin:$PATH
export GITHUB_TOKEN=[secure]
export GOPATH=$HOME/gopath
export PATH=$GOPATH/bin:$PATH

#Build and test

cd $HOME
git clone --depth=50 --branch=master \
  https://github.com/nats-io/nats-streaming-server.git nats-io/nats-streaming-server
mkdir -p $GOPATH/src/github.com/nats-io/nats-streaming-server
rsync -az $HOME/nats-io/nats-streaming-server/ \
  $GOPATH/src/github.com/nats-io/nats-streaming-server
cd $GOPATH/src/github.com/nats-io/nats-streaming-server

go get -t ./...

go get github.com/nats-io/gnatsd
go get github.com/mattn/goveralls
go get github.com/wadey/gocovmerge
go get -u honnef.co/go/tools/cmd/megacheck
go get -u github.com/client9/misspell/cmd/misspell
go get -u github.com/go-sql-driver/mysql

EXCLUDE_VENDOR=$(go list ./... | grep -v "/vendor/")
go build
$(exit $(go fmt $EXCLUDE_VENDOR | wc -l))
go vet $EXCLUDE_VENDOR
$(exit $(misspell -locale US . | grep -v "vendor/" | wc -l))
megacheck -ignore "$(cat staticcheck.ignore)" $EXCLUDE_VENDOR

go test -i $EXCLUDE_VENDOR
go test $EXCLUDE_VENDOR
