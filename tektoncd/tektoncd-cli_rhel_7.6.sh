# ----------------------------------------------------------------------------
#
# Package	: tektoncd/cli
# Version	: latest (0.7.1)
# Source repo	: https://github.com/tektoncd/cli
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
# kubectl (optional): version 1.15.0 or later - For interacting with your kube cluster
# ----------------------------------------------------------------------------

export TEKTONCD_CLI_VERSION=""

yum install -y git wget 

# set GOPATH
export GOPATH=$HOME/go

mkdir -p ${GOPATH}/src/github.com/tektoncd
cd ${GOPATH}/src/github.com/tektoncd
git clone https://github.com/tektoncd/cli.git 
cd cli

if [ "$TEKTONCD_CLI_VERSION" == "" ]
then
   echo "No specific version specified. Using latest ..."
else
   echo "Building the specified version $TEKTONCD_CLI_VERSION"
   git checkout ${TEKTONCD_CLI_VERSION}
fi

wrkdir=`pwd`

# Build tektoncd/cli binary from source code on Power
cd $wrkdir
GO111MODULE=on go build ./cmd/tkn

# check if binary is generated. If yes, then proceed with further steps
TEKTONCD_CLI_BINARY=./tkn
if [ -f "$TEKTONCD_CLI_BINARY" ]; then
    echo "* * * Successfully built tektoncd-cli !"
	./tkn
	echo "\n"
	
	echo "* * * Executing tests ... "
	go test ./...
	
	echo "Adding tkn as a kubectl plugin ... "
	# Please note that kubectl will find any binary named kubectl-* on your PATH and consider it as a plugin. After building tkn, create a link as kubectl-tkn
	ln -s ./tkn /usr/local/bin/kubectl-tkn
	
	# Check if tkn is listed as a plugin
	kubectl plugin list
	
	# Validate
	kubectl tkn help
	kubectl tkn version
else 
    echo "Something went wrong while building tektoncd-cli. Please check console log for more details."
fi

# Reference :: https://github.com/tektoncd/cli/blob/master/DEVELOPMENT.md