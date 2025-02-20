#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: github.com/prometheus/client_golang
# Version	: v1.8.0
# Source repo	: https://github.com/prometheus/client_golang
# Tested on	: UBI 8.5
# Language      : GO
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Atharv Phadnis <Atharv.Phadnis@ibm.com>, Vaishnavi Patil <Vaishnavi.Patil3@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=client_golang
PACKAGE_VERSION=${1:-e7e903064f5e9eb5da98208bae10b475d4db0f8c}
PACKAGE_URL=https://github.com/prometheus/client_golang


yum install -y git wget gcc
wget https://golang.org/dl/go1.17.linux-ppc64le.tar.gz
tar -C /bin -xf go1.17.linux-ppc64le.tar.gz
export PATH=$PATH:/bin/go/bin
export GOPATH=/home/tester/go

mkdir -p /home/tester/output
cd /home/tester

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

export PATH=$GOPATH/bin:$PATH
export GO111MODULE=on

if ! git clone $PACKAGE_URL $PACKAGE_NAME; then
        echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
                echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/clone_fails
        echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails" > /home/tester/output/version_tracker
        exit 0
fi

cd $PACKAGE_NAME

echo " --------------------------------- checkout version  $PACKAGE_VERSION ------------------------------------"
git checkout $PACKAGE_VERSION

if [ ! -f go.mod ]
then
if ! (go mod init $PACKAGE_NAME && go mod tidy); then
       echo "------------------$PACKAGE_NAME:build failed---------------------"
       echo "$PACKAGE_VERSION $PACKAGE_NAME"
       echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  build_Fails"
       exit 1
fi
fi

if ! go build -v ./...; then
    echo "------------------$PACKAGE_NAME: build failed-------------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME" > /home/tester/output/install_fails
    echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | master | $OS_NAME | GitHub | Fail |  Build_Fails" > /home/tester/output/version_tracker
    exit 1
fi

if ! go test -v ./...; then
    echo "------------------$PACKAGE_NAME:build_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/test_fails
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_success_but_test_Fails" > /home/tester/output/version_tracker
    exit 1
else
    echo "------------------$PACKAGE_NAME:build_&_test_both_success---------------------"
    echo "$PACKAGE_VERSION $PACKAGE_NAME" > /home/tester/output/test_success
	echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Build_and_Test_Success" > /home/tester/output/version_tracker
	exit 0
fi

#The following failing tests are in parity with x86:
# client_golang/prometheus
#prometheus/gauge_test.go:142:26: conversion from int to string yields a string of one rune, not a string of digits (did you mean fmt.Sprint(x)?)
#prometheus/gauge_test.go:150:79: conversion from int to string yields a string of one rune, not a string of digits (did you mean fmt.Sprint(x)?)
#prometheus/histogram_test.go:275:26: conversion from int to string yields a string of one rune, not a string of digits (did you mean fmt.Sprint(x)?)
#prometheus/histogram_test.go:288:29: conversion from int to string yields a string of one rune, not a string of digits (did you mean fmt.Sprint(x)?)
#prometheus/summary_test.go:290:26: conversion from int to string yields a string of one rune, not a string of digits (did you mean fmt.Sprint(x)?)
#prometheus/summary_test.go:303:29: conversion from int to string yields a string of one rune, not a string of digits (did you mean fmt.Sprint(x)?)
#FAIL    client_golang/prometheus [build failed]
