#!/bin/bash -ex
# -----------------------------------------------------------------------------
#
# Package       : github.com/uber/jaeger-client-go
# Version       : v2.29.1+incompatible
# Source repo   : https://github.com/uber/jaeger-client-go
# Tested on     : UBI 8.5
# Language      : GO
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Raju Sah <Raju.Sah@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=github.com/uber/jaeger-client-go
PACKAGE_VERSION=v2.29.1+incompatible
PACKAGE_URL=https://github.com/uber/jaeger-client-go
export GO_VERSION=${GO_VERSION:-1.15}

yum -y update && yum install -y nodejs nodejs-devel nodejs-packaging npm python38 python38-devel ncurses git jq wget gcc-c++

wget https://golang.org/dl/go$GO_VERSION.linux-ppc64le.tar.gz && tar -C /bin -xf go$GO_VERSION.linux-ppc64le.tar.gz && mkdir -p /home/tester/go/src /home/tester/go/bin /home/tester/go/pkg
export PATH=$PATH:/bin/go/bin
export GOPATH=/home/tester/go

OS_NAME=`python3 -c "os_file_data=open('/etc/os-release').readlines();os_info = [i.replace('PRETTY_NAME=','').strip() for i in os_file_data if i.startswith('PRETTY_NAME')];print(os_info[0])"`

export PATH=$GOPATH/bin:$PATH
export GO111MODULE=on

#export GO111MODULE=auto
if ! go get -d -t $PACKAGE_NAME@$PACKAGE_VERSION; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_VERSION $PACKAGE_NAME" > /home/tester/output/install_fails
    exit 0
else
        cd $(ls -d $GOPATH/pkg/mod/$PACKAGE_NAME@$PACKAGE_VERSION)
        go mod init $PACKAGE_NAME/$PACKAGE_VERSION
        if ! go test ./...; then
                echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
                echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | master  | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails"
                exit 0
        else
                echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
                exit 0
        fi
fi
