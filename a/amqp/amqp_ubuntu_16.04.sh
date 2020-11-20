# ----------------------------------------------------------------------------
#
# Package	: amqp
# Version	: 0.9.1
# Source repo	: http://github.com/streadway/amqp
# Tested on	: ubuntu_16.04
# Script License: Apache License, Version 2 or later
# Maintainer	: Atul Sowani <sowania@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

apt-get update -y
apt-get install -y git wget rabbitmq-server

WDIR=`pwd`

# Install latest "go" required by the client build.
wget https://storage.googleapis.com/golang/go1.9.1.linux-ppc64le.tar.gz
tar -C /usr/ -zxvf go1.9.1.linux-ppc64le.tar.gz
export PATH=$PATH:/usr/go/bin
export GOROOT=/usr/go
go version

mkdir $WDIR/AMQP
export GOPATH="$WDIR/AMQP"
export AMQP_URL="amqp://localhost/"

service rabbitmq-server start

cd $WDIR/AMQP
go get github.com/streadway/amqp
cd src/github.com/streadway/amqp
go test -tags integration
