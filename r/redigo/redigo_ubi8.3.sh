# -----------------------------------------------------------------------------
#
# Package       : redigo
# Version       :v1.84, v1.83
# Source repo   : "https://github.com/gomodule/redigo"
# Tested on     : ubi 8.3
# Script License: Apache License, Version 2 or later
# Maintainer: Priya Seth<sethp@us.ibm.com> Adilhusain Shaikh <Adilhusain.Shaikh@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash
#set -ex

#steps to clean up the package installation
if [ $1 = "clean" ]; then
    rm -rf $GOROOT
    rm -rf $GOPATH
    \cd $HOME/redis-* && make uninstall
    \cd $HOME && rm -rf redis*
    rm -rf $HOME/$PACKAGE_NAME
    exit 0
fi

echo "installing dependencies from system repo..."
dnf install -y tcl gcc gcc-c++ wget curl-devel git make >/dev/null

PACKAGE_NAME="redigo"
PACKAGE_URL="https://github.com/gomodule/redigo"
PACKAGE_VERSION=${1:-"v1.8.4"}
export GO_VERSION=${GO_VERSION:-"1.16"}
export GOROOT=${GOROOT:-"/usr/local/go"}
export GOPATH=${GOPATH:-$HOME/go}
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin:/usr/local/bin
OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

#installing golang
wget "https://golang.org/dl/go$GO_VERSION.linux-ppc64le.tar.gz"
tar -C /usr/local/ -xzf go$GO_VERSION.linux-ppc64le.tar.gz
rm -f go$GO_VERSION.linux-ppc64le.tar.gz

# installing redis server
cd $HOME
wget "https://download.redis.io/releases/redis-6.2.6.tar.gz"
[[ $? -eq 0 ]] && {
    tar -xzf redis*.tar.gz
    rm -f redis*.tar.gz
    cd redis*
    make && make install
    redis-server &
}

#cloning the package source
cd $HOME
if ! git clone $PACKAGE_URL $PACKAGE_NAME; then
    echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails"
    exit 1
fi

#building the package
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
go get -t -v ./... 
go vet $(go list ./... | grep -v /vendor/)
if ! go vet $(go list ./... | grep -v /vendor/); then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
    exit 1
fi

#testing the package
if ! go test -v -race ./...; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails"
    exit 1
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
