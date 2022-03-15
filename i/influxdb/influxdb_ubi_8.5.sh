#!/bin/bash -e

# ----------------------------------------------------------------------------
#
# Package               : influxdb
# Version               : v1.7.7
# Source repo           : https://github.com/influxdata/influxdb
# Tested on             : RHEL 8.5,UBI 8.5
# Language              : GO
# Script License        : Apache License, Version 2 or later
# Travis-Check          : True
# Maintainer            : Bhagat Singh <Bhagat.singh1@ibm.com>
#
# Disclaimer            : This script has been tested in root mode on given
# ==========              platform using the mentioned version of the package.
#                         It may not work as expected with newer versions of the
#                         package and/or distribution. In such case, please
#                         contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

# Dependency installation
dnf install -y git wget patch diffutils unzip gcc-c++


#Set variables
PACKAGE_URL=https://github.com/influxdata/influxdb
#PACKAGE_VERSION is configurable can be passed as an argument.
PACKAGE_VERSION=${1:-v1.7.7}
PACKAGE_NAME=influxdb
OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2) 

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
git clone $PACKAGE_URL

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
  
# Ensure go.mod file exists
[ ! -f go.mod ] && go mod init
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

# Its in parity with intel for test case failure.

#  FAIL: TestClient_Timeout (0.50s)
# influxdb_test.go:751: unexpected error. expected 'request canceled' error, got Post "http://127.0.0.1:39975/query?db=&q=": context deadline exceeded (Client.Timeout exceeded while awaiting headers)
#2022/02/24 09:06:02 http: TLS handshake error from 127.0.0.1:46890: remote error: tls: bad certificate