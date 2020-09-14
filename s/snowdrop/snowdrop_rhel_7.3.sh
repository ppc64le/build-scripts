# ----------------------------------------------------------------------------
#
# Package       : snowdrop
# Version       : v0.15.0
# Source repo   : https://github.com/snowdrop/snowdrop-cloud-devex/releases
# Tested on     : Red Hat Enterprise Linux release 8.0 via registry.access.redhat.com/ubi8/ubi:latest container
# Script License: Apache License, Version 2 or later
# Maintainer    : Amit Ghatwal <ghatwala@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

WDIR=`pwd`
export GOPATH=/go
export PATH=$GOPATH/bin:$PATH

#Install the required dependencies
sudo yum update && yum install -y git vim wget curl gcc gcc-c++ golang.ppc64le

# download src
mkdir -p /go/src/github.com/snowdrop && cd /go/src/github.com/snowdrop
git clone https://github.com/snowdrop/snowdrop-cloud-devex.git && cd snowdrop-cloud-devex
go get "github.com/snowdrop/spring-boot-cloud-devex/cmd" && go get "github.com/snowdrop/spring-boot-cloud-devex/pkg/common/logger"
go build && go test

