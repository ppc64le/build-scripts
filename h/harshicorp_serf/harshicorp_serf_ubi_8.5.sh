#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : hashicorp/serf
# Version       : v0.9.5
# Source repo   : https://github.com/hashicorp/serf.git
# Tested on     : UBI 8.5
# Language      : GO
# Travis-Check  : False
# Script License: Apache License, Version 2 or later
# Maintainer    : vathsala . <vaths367@in.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME="serf"
PACKAGE_VERSION=${1:-v0.9.5}
PACKAGE_URL="https://github.com/hashicorp/serf.git"

#need to start your container as

docker run -itd --name serf --privileged --network host registry.access.redhat.com/ubi8/ubi:8.5 /sbin/init

#Then run below commands

yum install -y git wget gcc make syslog
systemctl start rsyslog

GO_VERSION=1.14
wget https://golang.org/dl/go$GO_VERSION.linux-ppc64le.tar.gz
tar -C /bin -xf go$GO_VERSION.linux-ppc64le.tar.gz
rm -f go$GO_VERSION.linux-ppc64le.tar.gz
export PATH=$PATH:/bin/go/bin
export GOPATH=/home/tester/go
export PATH=$GOPATH/bin:$PATH
export GO111MODULE=on

mkdir -p /home/tester/go/src/github.com
cd /home/tester/go/src/github.com
git clone $PACKAGE_URL
cd serf/

git checkout $PACKAGE_VERSION
go get gotest.tools/gotestsum@latest
gotestsum --format=short-verbose --junitfile ../gotestsum-report.xml -- ./...

#Build and Test pass
#This should be the output of the test in case of success:
#EMPTY version
#DONE 255 tests in 43.843s
