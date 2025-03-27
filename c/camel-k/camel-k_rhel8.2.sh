#!/bin/bash -e  
# -----------------------------------------------------------------------------  
#  
# Package        : camel-k  
# Version        : 1.3.0  
# Source repo    : https://github.com/apache/camel-k  
# Tested on      : RHEL 8.2, UBI:9  
# Language       : Go, Java 
# Travis-Check   : True
# Script License : Apache License, Version 2 or later  
# Maintainer     : Anushka Juli<anushka_juli1@ibm.com>  
#  
# Disclaimer:  
# This script has been tested in root mode on the given platform  
# using the mentioned version of the package. It may not work as expected  
# with newer versions of the package and/or distribution.  
# In such a case, please contact the "Maintainer" of this script.  
# -----------------------------------------------------------------------------  
 
PACKAGE_NAME=camel-k  
PACKAGE_VERSION=${1:-v1.3.0}  
PACKAGE_URL=https://github.com/apache/camel-k  
OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)  
 
# Install dependencies  
yum install -y make git wget java-11-openjdk gcc  
 
# Set up Java environment  
JDK_PATHS=$(compgen -G '/usr/lib/jvm/java-11-openjdk-*')  
export JAVA_HOME=${JDK_PATHS%$'\n'*}  
export PATH=$JAVA_HOME/bin:$PATH  
 
# Install Go  
wget https://golang.org/dl/go1.15.2.linux-ppc64le.tar.gz  
tar -xzf go1.15.2.linux-ppc64le.tar.gz  
rm -rf go1.15.2.linux-ppc64le.tar.gz  
export GOPATH=$(pwd)/gopath  
export GOROOT=$(pwd)/go  
export PATH=$GOROOT/bin:$GOPATH/bin:$PATH  
 
# Clone the repository  
mkdir -p $GOPATH/src/github.com/apache  
cd $GOPATH/src/github.com/apache  
git clone $PACKAGE_URL  
cd $PACKAGE_NAME  
git checkout $PACKAGE_VERSION  
 
# Modify Dockerfile and config files  
sed -i 's/openjdk11:slim/openjdk11:ubi/g' build/Dockerfile  
sed -i 's/BaseImage = "adoptopenjdk\/openjdk11:slim"/BaseImage = "adoptopenjdk\/openjdk11:ubi"/g' pkg/util/defaults/defaults.go  
sed -i '/replaces: camel-k-operator.v1.2.0/d' config/manifests/bases/camel-k.clusterserviceversion.yaml  
sed -i 's/image: docker.io\/apache\/camel-k:1.3.0-SNAPSHOT/image: docker.io\/apache\/camel-k:1.3.0/g' config/manager/operator-deployment.yaml  

#Currently we are not making image
#make images

# Build and test  
if ! (make controller-gen && make kustomize && make build && make test && make package-artifacts); then  
    echo "------------------$PACKAGE_NAME: build fails------------------"  
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Build_fails"  
    exit 1  
else  
    echo "------------------$PACKAGE_NAME: build success------------------"  
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Pass | Build_success"  
    exit 0  
fi
