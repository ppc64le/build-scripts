# ----------------------------------------------------------------------------
#
# Package         : tektoncd/operator
# Version         : master
# Source repo     : https://github.com/tektoncd/operator.git
# Tested on       : rhel_7.6
# Script License  : Apache License, Version 2.0
# Maintainer      : Siddhesh Ghadi <Siddhesh.Ghadi@ibm.com>
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
# Docker 17.05 or later must be installed and running.
#
# Go version 1.13.0 or later must be installed.
#
# For deployment
# Kubectl version 1.15.0 or later must be installed.
# Note: For kubectl version below 1.15.0, the “tkn” plugin may not be identified by kubectl. 
# Hence, it is recommended to use 1.15.0 or later versions of kubectl.
#
# ----------------------------------------------------------------------------

set -e

yum update -y
yum install git wget -y

export GOPATH=${HOME}/go
export PATH=$GOPATH/bin:$GOROOT/bin:$PATH
export GO111MODULE=auto
export GOARCH=ppc64le 

#Install operator-sdk
wget -O ${GOPATH}/bin/operator-sdk https://github.com/operator-framework/operator-sdk/releases/download/v0.16.0/operator-sdk-v0.16.0-ppc64le-linux-gnu
chmod +x ${GOPATH}/bin/operator-sdk

#Build tektoncd/triggers
mkdir -p ${GOPATH}/src/github.com/tektoncd && cd $_
git clone https://github.com/tektoncd/operator.git
cd operator
operator-sdk build openshift-pipelines-operator
