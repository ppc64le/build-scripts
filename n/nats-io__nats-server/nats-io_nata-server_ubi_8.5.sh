#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: nats-server
# Version	: v2.9.8
# Source repo	: https://github.com/nats-io/nats-server
# Tested on	: UBI: 8.5
# Language      : Go 
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Muskaan Sheik <Muskaan.Sheik@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=nats-server
PACKAGE_VERSION=${1:-v2.9.8}
PACKAGE_URL=https://github.com/nats-io/nats-server

yum -y update && yum install -y nodejs nodejs-devel nodejs-packaging npm python38 python38-devel ncurses git jq wget gcc-c++

#install go
wget https://go.dev/dl/go1.19.3.linux-ppc64le.tar.gz
rm -rf /usr/local/go
tar -C /usr/local -xzf  go1.19.3.linux-ppc64le.tar.gz
export PATH=$PATH:/usr/local/go/bin

git clone https://github.com/nats-io/nats-server.git
cd nats-server/

#build and test
go build ./...
go test -race -v -run=TestJetStreamCluster ./server -tags=skip_js_cluster_tests_2,skip_js_cluster_tests_3 -count=1 -vet=off -timeout=30m -failfast
go test -race -v -run=TestJetStreamCluster ./server -tags=skip_js_cluster_tests,skip_js_cluster_tests_2 -count=1 -vet=off -timeout=30m -failfast
go test -race -v -run=TestJetStreamSuperCluster ./server -count=1 -vet=off -timeout=30m -failfast
go test -race -v -run=TestMQTT ./server -count=1 -vet=off -timeout=30m -failfast
#go test ./... 

#Tests in parity with Intel
#Failing test: github.com/nats-io/nats-server/v2/logger 
#Due to the above mentioned test failure tests run in a loop trying to connect