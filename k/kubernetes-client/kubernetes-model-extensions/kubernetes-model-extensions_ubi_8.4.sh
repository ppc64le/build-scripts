# -----------------------------------------------------------------------------
#
# Package       : kubernetes-model-extensions
# Version       : v5.0.2
# Source repo   : https://github.com/fabric8io/kubernetes-client.git
# Tested on     : ubi 8.4
# Script License: Apache License, Version 2 or later
# Maintainer    : Siddhesh Ghadi <Siddhesh.Ghadi@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash

set -e

PACKAGE_NAME=kubernetes-model-generator/kubernetes-model-extensions
PACKAGE_VERSION=${1:-v5.0.2}
PACKAGE_URL=https://github.com/fabric8io/kubernetes-client.git

yum -y update
yum install -y make git curl wget java-1.8.0-openjdk-devel

# install maven
wget https://downloads.apache.org/maven/maven-3/3.8.3/binaries/apache-maven-3.8.3-bin.tar.gz -P /tmp 
tar -xzf /tmp/apache-maven-3.8.3-bin.tar.gz -C /opt/
export M2_HOME=/opt/apache-maven-3.8.3
export PATH=$M2_HOME/bin/:$PATH
mvn --version

# install go
wget https://golang.org/dl/go1.16.linux-ppc64le.tar.gz -P /tmp
tar -xf /tmp/go1.16.linux-ppc64le.tar.gz -C /opt/
export GOROOT=/opt/go
export GOPATH=$HOME/go
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin
go version

# clone source & checkout version
git clone $PACKAGE_URL $GOPATH/src/github.com/fabric8io/kubernetes-client
cd $GOPATH/src/github.com/fabric8io/kubernetes-client/
git checkout $PACKAGE_VERSION

# build package
cd $PACKAGE_NAME
make all

# generated jars 
find -name *.jar
