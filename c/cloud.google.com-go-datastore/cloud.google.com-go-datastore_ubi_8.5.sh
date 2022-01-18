# -----------------------------------------------------------------------------
#
# Package	: cloud.google.com/go/datastore
# Version	: datastore/v1.0.0, datastore/v1.1.0
# Source repo	: https://github.com/googleapis/google-cloud-go
# Language	: GO
# Travis-Check	: True
# Tested on	: UBI 8.5
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
# NOTE: to run the same script for v1.1.0 run the script as: ./cloud.google.com-go-datastore_ubi_8.5.sh -e v1.1.0 
# ----------------------------------------------------------------------------

PACKAGE_NAME=cloud.google.com/go/datastore
PACKAGE_VERSION=${1:-v1.0.0}
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

export PATH=$GOPATH/bin:$PATH
export GO111MODULE=on

if ! go get -d -t $PACKAGE_NAME@$PACKAGE_VERSION; then
	echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_NAME  |  $PACKAGE_VERSION |  $OS_NAME | GitHub | Fail |  Install_Fails"
	exit 1
fi

cd $(ls -d $GOPATH/pkg/mod/cloud.google.com/go/datastore\@$PACKAGE_VERSION/)


go mod init $PACKAGE_NAME
go mod tidy

if ! go test ./...; then
	echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
	echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails" 
	exit 1
else
	echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
	echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
	exit 0
fi
