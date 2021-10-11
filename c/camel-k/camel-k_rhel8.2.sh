# ----------------------------------------------------------------------------
#
# Package        : camel-k
# Version        : 1.3.0
# Source repo    : https://github.com/apache/camel-k
# Tested on      : RHEL 8.2
# Script License : Apache License, Version 2 or later
# Maintainer     : Amit Sadaphule <amits2@us.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash

set -eux

CWD=`pwd`

# Install dependencies
yum install -y make git wget java-11-openjdk gcc
JDK_PATHS=$(compgen -G '/usr/lib/jvm/java-11-openjdk-*')
export JAVA_HOME=${JDK_PATHS%$'\n'*}
export PATH=$JAVA_HOME/bin:$PATH

# Download and install go
wget https://golang.org/dl/go1.15.2.linux-ppc64le.tar.gz
tar -xzf go1.15.2.linux-ppc64le.tar.gz
rm -rf go1.15.2.linux-ppc64le.tar.gz
export GOPATH=`pwd`/gopath
export GOROOT=`pwd`/go
export PATH=`pwd`/go/bin:$GOPATH/bin:$PATH

# Clone the repo and build/test
mkdir -p $GOPATH/src/github.com/apache
cd $GOPATH/src/github.com/apache
git clone https://github.com/apache/camel-k.git
cd camel-k/
git checkout v1.3.0
sed -i 's/openjdk11:slim/openjdk11:ubi/g' build/Dockerfile
sed -i 's/BaseImage = "adoptopenjdk\/openjdk11:slim"/BaseImage = "adoptopenjdk\/openjdk11:ubi"/g' pkg/util/defaults/defaults.go
sed -i '/replaces: camel-k-operator.v1.2.0/d' config/manifests/bases/camel-k.clusterserviceversion.yaml
sed -i 's/image: docker.io\/apache\/camel-k:1.3.0-SNAPSHOT/image: docker.io\/apache\/camel-k:1.3.0/g' config/manager/operator-deployment.yaml
make controller-gen
make kustomize
make build
make test
make package-artifacts
make images
echo "Build, unit test execution and image creation successful!"
