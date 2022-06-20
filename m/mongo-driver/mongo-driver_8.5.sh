#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : mongo-go-driver
# Version       : v1.7.3
# Source repo   : https://github.com/mongodb/mongo-go-driver.git
# Tested on     : UBI 8.5
# Travis-Check  : True
# Language      : Go
# Script License: Apache License, Version 2 or later
# Maintainer    : saraswati patra <saraswati.patra@ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=mongo-go-driver
PACKAGE_VERSION=${1:-v1.7.3}
PACKAGE_URL=https://github.com/mongodb/mongo-go-driver.git

if [ -d "$PACKAGE_NAME" ] ; then
  rm -rf $PACKAGE_NAME
  echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Removed existing package if any"  
fi

# Dependency installation
yum module install -y go-toolset
dnf install -y git

# Download the repos

if ! git clone $PACKAGE_URL $PACKAGE_NAME; then
    echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails"
    exit 1
fi

# Build and Test mongo-go-driver
cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION

export GO111MODULE="auto"

if ! go get -v -t ./...; then
	echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_NAME  |  $PACKAGE_VERSION |  $OS_NAME | GitHub | Fail |  Install_Fails"
	exit 1
fi
#------------------------------
#Test are in parity with x86:
#=== RUN   TestMinPoolSize
#--- PASS: TestMinPoolSize (0.00s)
#=== RUN   TestTopology_String_Race
#--- PASS: TestTopology_String_Race (0.00s)
#=== RUN   TestTopologyConstruction
#=== RUN   TestTopologyConstruction/construct_with_URI
#=== RUN   TestTopologyConstruction/construct_with_URI/normal
#=== RUN   TestTopologyConstruction/construct_with_URI/srv
#--- PASS: TestTopologyConstruction (0.00s)
#    --- PASS: TestTopologyConstruction/construct_with_URI (0.00s)
#        --- PASS: TestTopologyConstruction/construct_with_URI/normal (0.00s)
#        --- PASS: TestTopologyConstruction/construct_with_URI/srv (0.00s)
#PASS
#ok      go.mongodb.org/mongo-driver/x/mongo/driver/topology     13.583s
#?       go.mongodb.org/mongo-driver/x/mongo/driver/uuid [no test files]
#?       go.mongodb.org/mongo-driver/x/mongo/driver/wiremessage  [no test files]
#FAIL
#------------------mongo-go-driver:install_success_but_test_fails---------------------
#------------------------------
if ! go test -v ./...; then
	echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
	echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails" 
	exit 1
else
	echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
	echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
	exit 0
fi
