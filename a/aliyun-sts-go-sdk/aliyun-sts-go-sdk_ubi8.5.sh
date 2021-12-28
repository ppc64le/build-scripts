# -----------------------------------------------------------------------------
#
# Package	: github.com/baiyubin/aliyun-sts-go-sdk
# Version	: v0.0.0-20180326062324-cfa1a18b161f
# Source repo	: https://github.com/baiyubin/aliyun-sts-go-sdk
# Tested on	: ubi8.5
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
# The test-status is in pairity with x86 <for requested as well as latest version>
# Error:
# github.com/baiyubin/aliyun-sts-go-sdk/sts [github.com/baiyubin/aliyun-sts-go-sdk/sts.test]
# sts/sts.go:109:12: assignment mismatch: 2 variables but uuid.NewV4 returns 1 value
# sts/sts.go:127:19: cannot assign error to err in multiple assignment
# FAIL    github.com/baiyubin/aliyun-sts-go-sdk/sts [build failed]
# ----------------------------------------------------------------------------

PACKAGE_NAME=github.com/baiyubin/aliyun-sts-go-sdk
PACKAGE_VERSION=${1:-v0.0.0-20180326062324-cfa1a18b161f}
PACKAGE_URL=https://github.com/baiyubin/aliyun-sts-go-sdk

yum install -y wget git tar gcc

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

if ! go get -d -t $PACKAGE_NAME@$PACKAGE_VERSION; then
	echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_NAME  |  $PACKAGE_VERSION |  $OS_NAME | GitHub | Fail |  Install_Fails"
	exit 1
fi

cd $(ls -d $GOPATH/pkg/mod/$PACKAGE_NAME*)

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
