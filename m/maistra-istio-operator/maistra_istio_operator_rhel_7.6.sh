# ----------------------------------------------------------------------------
#
# Package        : istio-operator
# Version        : maistra-1.1
# Source repo    : https://github.com/Maistra/istio-operator
# Tested on      : RHEL 7.6
# Script License : Apache License, Version 2 or later
# Maintainer     : Rashmi Sakhalkar <srashmi@us.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash

WORKDIR=`pwd`
BUILD_VERSION=maistra-1.1

#Install libraries
yum update -y
yum install -y gcc
yum install -y make wget git unzip which
yum install -y python36

#Install Go
curl -O https://dl.google.com/go/go1.13.1.linux-ppc64le.tar.gz
tar -C /usr/local -xzf go1.13.1.linux-ppc64le.tar.gz
export PATH=$PATH:/usr/local/go/bin
export GOPATH=/root/go
rm -rf go1.13.1.linux-ppc64le.tar.gz

#Clone the source code
cd $WORKDIR
git clone https://github.com/Maistra/istio-operator
cd istio-operator && git checkout $BUILD_VERSION
   
#Run the build
OFFLINE_BUILD="true" GIT_UPSTREAM_REMOTE="remotes/origin" make

#Run the tests
OFFLINE_BUILD="true" GIT_UPSTREAM_REMOTE="remotes/origin" GOARCH="ppc64le" make test
