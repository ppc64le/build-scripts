#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : github.com/dave/jennifer
# Version       : v1.2.0
# Source repo   : https://github.com/dave/jennifer.git
# Tested on     : UBI 8.5
# Language      : GO
# Travis-Check  : True
# Script License: MIT License
# Maintainer    : Vaishnavi Patil <Vaishnavi.Patil3@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=jennifer
PACKAGE_VERSION=${1:-v1.2.0}
PACKAGE_URL=https://github.com/dave/jennifer.git


yum install -y git make wget
wget https://golang.org/dl/go1.15.6.linux-ppc64le.tar.gz
tar -C /bin -xf go1.15.6.linux-ppc64le.tar.gz
export PATH=$PATH:/bin/go/bin
export GOPATH=/home/tester/go

mkdir -p /home/tester/output
export GO111MODULE=on
cd /home/tester
OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

if ! git clone $PACKAGE_URL; then
       echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
                echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/clone_fails
        echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails" > /home/tester/output/version_tracker
        exit 0
fi

cd $PACKAGE_NAME

echo " --------------------------------- checkout version  $PACKAGE_VERSION ------------------------------------"
git checkout $PACKAGE_VERSION

go mod init jennifer
go install

echo "------------------Test the package---------------------"
if ! go test -v ./...; then
        echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/test_fails
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails" > /home/tester/output/version_tracker
        exit 1
else
        echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME" > /home/tester/output/test_success
        echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success" > /home/tester/output/version_tracker
        exit 0
fi

