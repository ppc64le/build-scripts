# ----------------------------------------------------------------------------
#
# Package	: telegraf
# Version	: 1.5.0
# Source repo	: https://github.com/influxdata/telegraf
# Tested on	: rhel_7.3
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

sudo yum update


#Install dependencies
sudo yum install -y make git wget tar

cd /tmp && \
	wget https://storage.googleapis.com/golang/go1.8.1.linux-ppc64le.tar.gz && \
	sudo tar -C /usr/local -xzf go1.8.1.linux-ppc64le.tar.gz && \
	export PATH=$PATH:/usr/local/go/bin

#Build and test
export GOPATH=$HOME/go
go get -d github.com/influxdata/telegraf

cd $GOPATH/src/github.com/influxdata/telegraf
make
make test

