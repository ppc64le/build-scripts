# ----------------------------------------------------------------------------
#
# Package	: Appsody/controller
# Version	: latest (0.3.4)
# Source repo	: https://github.com/appsody/controller
# Tested on	: rhel_7.6
# Script License: Apache License, Version 2
# Maintainer	: Vrushali Inamdar <vrushali.inamdar@ibm.com>
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
# Go version 1.12 or higher is installed and in the path
#    	Install ‘go’ using steps mentioned at https://tecadmin.net/install-go-on-centos
# Docker is installed and running
# wget is installed
# ----------------------------------------------------------------------------

export APPSODY_CONTROLLER_VERSION="0.3.4"

yum install -y wget 

# set GOPATH
export GOPATH=$HOME/go

mkdir -p $GOPATH/src/github.com/appsody
cd $GOPATH/src/github.com/appsody
git clone https://github.com/appsody/controller.git
cd controller

if [ "$APPSODY_CONTROLLER_VERSION" == "" ]
then
   echo "No specific version specified. Using latest ..."
else
   echo "Building the specified version $APPSODY_CONTROLLER_VERSION"
   git checkout ${APPSODY_CONTROLLER_VERSION}
fi

wrkdir=`pwd`

# Build appsody binary from source code on Power
cd $wrkdir
GOOS=linux CGO_ENABLED=0 GOARCH=ppc64le go build -o ./build/appsody-controller -ldflags "-X main.VERSION=$APPSODY_CONTROLLER_VERSION"

# Copy appsody binary to /usr/bin directory
cp build/appsody-controller /usr/bin/appsody-controller

APPSODY_CONTROLLER_BINARY=/usr/bin/appsody-controller
if [ -f "$APPSODY_CONTROLLER_BINARY" ]; then
    echo "Successfully built appsody controller !"
else 
    echo "Something went wrong while building appsody controller. Please check console log for more details."
fi
