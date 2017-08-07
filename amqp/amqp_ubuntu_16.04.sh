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

sudo apt-get update -y
sudo apt-get install -y git golang-go rabbitmq-server
mkdir /tmp/AMQP
export GOPATH="/tmp/AMQP"

cd /tmp/AMQP
go get github.com/streadway/amqp
sudo service rabbitmq-server start

cd /tmp/AMQP/src/github.com/streadway/amqp && \
    touch test.sh && \
    echo "invoke-rc.d rabbitmq-server start" >> test.sh && \
    echo "go test -tags integration" >> test.sh && \
    chmod +x test.sh && \
    ./test.sh
