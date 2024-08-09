#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : kiegroup/kie-cloud-operator
# Version       : 7.13.2-2
# Source repo   : https://github.com/kiegroup/kie-cloud-operator.git
# Tested on     : UBI 9.3
# Language      : Go
# Travis-Check  : False
# Script License: Apache License, Version 2 or later
# Maintainer    : Shubham Gupta <Shubham.Gupta43@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=kie-cloud-operator
PACKAGE_VERSION=${1:-7.13.2-2}
PACKAGE_URL=https://github.com/kiegroup/kie-cloud-operator.git

yum install -y git wget make gcc

wget https://github.com/operator-framework/operator-sdk/releases/download/v0.19.1/operator-sdk-v0.19.1-ppc64le-linux-gnu
chmod +x operator-sdk-v0.19.1-ppc64le-linux-gnu
mv operator-sdk-v0.19.1-ppc64le-linux-gnu /usr/local/bin/operator-sdk


# Download Go
wget https://golang.org/dl/go1.20.5.linux-ppc64le.tar.gz

# Extract the Archive
sudo tar -C /usr/local -xzf go1.20.5.linux-ppc64le.tar.gz

# Remove the downloaded tar file
rm go1.20.5.linux-ppc64le.tar.gz

# Set Up Environment Variables
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.profile
echo 'export GOPATH=$HOME/go' >> ~/.profile
echo 'export PATH=$PATH:$GOPATH/bin' >> ~/.profile

# Apply the Changes
source ~/.profile

# Verify the Installation
go version

if ! git clone $PACKAGE_URL; then
    echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    exit 0
fi

cd $PACKAGE_NAME

git checkout $PACKAGE_VERSION

sed -i 's/'registry.redhat.io'/'registry.access.redhat.com'/g' build/Dockerfile

if ! BUILDER=docker make; then
    echo "------------------$PACKAGE_NAME:build_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    exit 1
fi

if ! make test; then
    echo "------------------$PACKAGE_NAME:test_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Both_build_and_test_pass---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    exit 0
fi

#script build and validated on host 

