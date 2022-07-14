#!/bin/bash -e

# -----------------------------------------------------------------------------
#
# Package          : grpc-websocket-proxy
# Version          : e5319fda7802
# Source repo      : https://github.com/tmc/grpc-websocket-proxy/
# Tested on        : RHEL 8.5,UBI 8.5
# Language         : GO
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Bhagat Singh <Bhagat.singh1@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#   
# ----------------------------------------------------------------------------

PACKAGE_NAME=grpc-websocket-proxy
#PACKAGE_VERSION is configurable can be passed as an argument.
PACKAGE_VERSION=${1:-e5319fda7802}
PACKAGE_URL=https://github.com/tmc/grpc-websocket-proxy

# Dependency installation
dnf install -y git wget patch diffutils unzip gcc-c++

#Install go package and update go path if not installed 
if ! command -v go &> /dev/null
then
curl -O https://dl.google.com/go/go1.16.1.linux-ppc64le.tar.gz
tar -C /usr/local -xzf go1.16.1.linux-ppc64le.tar.gz
export GOROOT=/usr/local/go
export GOPATH=$HOME/go
export PATH=$GOROOT/bin:$GOPATH/bin:$PATH
export GO111MODULE=auto
fi
 
#Check if package exists
if [ -d $PACKAGE_NAME ] ; then
  rm -rf $PACKAGE_NAME
  echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Removed existing package if any"  
 
fi
 
# Download the repos
if ! git clone $PACKAGE_URL ; then
        echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails"
        exit 1
fi

# Build and Test
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
ret=$?
if [ $ret -eq 0 ] ; then
 echo "---------------------------$PACKAGE_VERSION found to checkout--------------------- "
else
 echo "---------------------------$PACKAGE_VERSION not found-----------------------------"
 exit
fi 

     go mod init github.com/tmc/grpc-websocket-proxy
     go mod tidy
    
if ! go build -v ./...; then

    echo "------------------$PACKAGE_NAME:build failed---------------------"
    echo "$PACKAGE_VERSION $PACKAGE_NAME"
    echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  build_Fails"
    exit 1
else

   if ! go test ./...; then
   
             echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
             echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Test_Fails"    
    exit 1
  else
       echo "------------------$PACKAGE_NAME:install_build_and_test_success-------------------------"
       echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Pass |  Install_Build_and_Test_Success"
    exit 0 
fi
fi
 