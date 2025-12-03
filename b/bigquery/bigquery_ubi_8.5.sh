# -----------------------------------------------------------------------------
#
# Package	: cloud.google.com/go/bigquery
# Version	: bigquery/v1.0.1, bigquery/v1.8.0,
# Source repo	: https://github.com/googleapis/google-cloud-go
# Tested on	: ubi8.5
# Language      : GO
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Sapna Shukla <Sapna.Shukla@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
# NOTE: to run the same script for v1.8.0 run the script as: ./bigquery_ubi8.5.sh -e v1.8.0 
# ----------------------------------------------------------------------------

PACKAGE_NAME=google-cloud-go/bigquery/
PACKAGE_VERSION=${1:-v1.0.1}
PACKAGE_URL=https://github.com/googleapis/google-cloud-go.git

yum install git gcc wget tar -y


GO_VERSION=1.17

# Install Go and setup working directory
wget https://golang.org/dl/go$GO_VERSION.linux-ppc64le.tar.gz
tar -C /bin -xf go$GO_VERSION.linux-ppc64le.tar.gz
mkdir -p /home/tester/go/src 
rm -f go$GO_VERSION.linux-ppc64le.tar.gz

export PATH=$PATH:/bin/go/bin
export GOPATH=/home/tester/go

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

export PATH=$GOPATH/bin:$PATH
export GO111MODULE=on

#running the go commands
cd /home/tester/go/src
git clone --recurse $PACKAGE_URL
cd $PACKAGE_NAME
git checkout bigquery/$PACKAGE_VERSION


if ! go build ./...; then
	echo "------------------$PACKAGE_NAME:Build_Fails-------------------------------------"
	echo "$PACKAGE_NAME  |  $PACKAGE_VERSION |  $OS_NAME | GitHub | Fail |  Build_Fails"
	exit 1
fi

go mod init
go mod tidy 

if ! go test ./... -v; then
	echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
	echo "$PACKAGE_NAME  |  $PACKAGE_VERSION |  $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails"
	exit 1
else		
	echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
	echo "$PACKAGE_NAME  |  $PACKAGE_VERSION |  $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
