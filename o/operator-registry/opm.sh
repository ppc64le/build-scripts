# ----------------------------------------------------------------------------
#
# Package       : opm
# Version       : 1.15.3
# Source repo   : https://github.com/operator-framework/operator-registry/
# Tested on     : ubuntu 18.04
# Script License: Apache License 2.0
# Maintainer's  : Hari Pithani <Hari.Pithani@ibm.com>
#
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

PACKAGE_VERSION=v1.15.3

echo "Usage: $0 [<PACKAGE_VERSION>]"
echo "       PACKAGE_VERSION is an optional paramater whose default value is v1.15.3"

PACKAGE_VERSION="${1:-$PACKAGE_VERSION}"
PACKAGE_NAME=operator-registry
PACKAGE_URL=https://github.com/operator-framework/operator-registry.git
#For rerunning build
if [ -d "operator-registry" ] ; then
  rm -rf operator-registry
fi

# Installation of required sotwares. 
apt update
apt install git wget make gcc -y
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-11.0.12.0.7-0.el8_4.ppc64le
cd && wget https://golang.org/dl/go1.15.6.linux-ppc64le.tar.gz && tar xf go1.15.6.linux-ppc64le.tar.gz
export PATH=$PWD/go/bin:$PATH 

# Cloning the repository from remote to local. 
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
ret=$?
if [ $ret -eq 0 ] ; then
  echo  "${PACKAGE_VERSION} found to checkout"
else
  echo  "${PACKAGE_VERSION} not found"
  exit
fi

# Building the code.
make build
cp bin/opm /usr/bin/
opm version
