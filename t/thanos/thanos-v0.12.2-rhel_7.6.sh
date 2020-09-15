# ----------------------------------------------------------------------------

#

# Package         : thanos

# Version         : v0.12.2 

# Source repo     : https://github.com/thanos-io/thanos.git

# Tested on       : rhel_7.6

# Script License  : Apache License, Version 2.0

# Maintainer      : Snehlata Mohite <smohite@us.ibm.com>

#

# Disclaimer: This script has been tested in root mode on given

# ==========  platform using the mentioned version of the package.

#             It may not work as expected with newer versions of the

#             package and/or distribution. In such case, please

#             contact "Maintainer" of this script.

#

# ----------------------------------------------------------------------------



#!/bin/bash



# ----------------------------------------------------------------------------

# Prerequisites:

#

# Docker must be installed and running

#

# Go version 1.13.6 or higher must be installed

#

# ----------------------------------------------------------------------------



set -e



yum update -y

yum install git -y


export GOPATH=${HOME}/go

export PATH=$GOPATH/bin:$GOROOT/bin:$PATH


mkdir -p ${GOPATH}/src/github.com/thanos-io && cd $_

git clone --branch v0.12.2 https://github.com/thanos-io/thanos.git

cd thanos

make build

# Below components are required for local tests (make test-local)
# mkdir -p $GOPATH/src/github.com/prometheus
# cd $GOPATH/src/github.com/prometheus
# git clone https://github.com/prometheus/prometheus.git
# cd prometheus
# make build
# ./prometheus --config.file=your_config.yml

#docker pull ibmcom/prometheus:v2.8.0-f1
#docker pull ibmcom/alertmanager-ppc64le:v0.15.0-f4

# point thanos/test/e2e/e2ethanos/services.go for required altermanager and prometheus containers.
#func DefaultPrometheusImage() string {
#        return "ibmcom/prometheus:v2.8.0-f1"
#}
#func DefaultAlertmanagerImage() string {
#        return "ibmcom/alertmanager-ppc64le:v0.15.0-f4"
#}

