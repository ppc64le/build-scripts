#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: consul
# Version	: v1.4.4
# Source repo	: https://github.com/hashicorp/consul
# Tested on	: RHEL 7.6
# Language      : Go
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Amit Ghatwal <ghatwala@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME="go"
[ -z "$GO_VERSION" ] && GO_VERSION="1.12.4"

PACKAGE_VERSION=${1:-v1.4.4}

# Install depdencies
yum install -y sudo
sudo yum update -y && sudo yum install -y make wget git gcc

# Install Go
printf -- 'Downloading go binaries \n'
wget -q https://dl.google.com/go/go"${GO_VERSION}".linux-ppc64le.tar.gz
chmod ugo+r go"${GO_VERSION}".linux-ppc64le.tar.gz

sudo rm -rf /usr/local/go /usr/bin/go
sudo tar -C /usr/local -xzf go"${GO_VERSION}".linux-ppc64le.tar.gz

sudo ln -sf /usr/local/go/bin/go /usr/bin/
sudo ln -sf /usr/local/go/bin/godoc /usr/bin/
sudo ln -sf /usr/local/go/bin/gofmt /usr/bin/

printf -- 'Extracted the tar in /usr/local and created symlink\n'

#Clean up the downloaded zip
rm -rf go"${GO_VERSION}".linux-ppc64le.tar.gz*
printf -- 'Cleaned up the artifacts\n'

#Verify if go is configured correctly
if go version | grep -q "$GO_VERSION"
 then
   printf -- "Installed %s %s successfully \n" "$PACKAGE_NAME" "$PACKAGE_VERSION"
 else
   printf -- "Error while installing Go"
fi

#Get the source code and build Consul
export CWD=`pwd`
export GOPATH=$CWD/gopath
export PATH=$GOPATH/bin:$PATH
export CONSULPATH=$GOPATH/src/github.com/hashicorp
export PACKAGE_NAME=consul

[ ! -d "$GOPATH" ] && mkdir -p $GOPATH
[ ! -d "$CONSULPATH" ] && mkdir -p $CONSULPATH
cd $CONSULPATH
#Check if consul directory exists
if [ -d "$PACKAGE_NAME" ]; then
    rm -rf "$PACKAGE_NAME"
fi
git clone https://github.com/hashicorp/consul.git --branch $PACKAGE_VERSION
cd consul
export GOTEST_PKGS="./api"
make test-ci
printf -- "TC ran successfully \n"
