# -----------------------------------------------------------------------------
#
# Package       : toml
# Version       : v0.3.1
# Source repo   : "https://github.com/BurntSushi/toml"
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

 PACKAGE_NAME="toml"
 PACKAGE_URL="https://github.com/BurntSushi/toml"
 PACKAGE_VERSION=${1:-"v0.3.1"}

export GO_VERSION=${GO_VERSION:-"1.16"}
export GOROOT=${GOROOT:-"/usr/local/go"}
export GOPATH=${GOPATH:-$HOME/go}
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin:/usr/local/bin
export PACKAGE_SOURCE_ROOT=$(awk -F '/' '{print  "/src/" $3 "/" $4;}' <<<$PACKAGE_URL | xargs   printf "%s" $GOPATH)

# step to clean up package installation
if [ $1 = "clean" ]; then
    rm -rf $GOROOT
    rm -rf $GOPATH
    exit 0
fi

echo "installing dependencies from system repo..."
dnf install wget git gcc gcc-c++ make -y  > /dev/null

wget "https://golang.org/dl/go$GO_VERSION.linux-ppc64le.tar.gz"
tar -C /usr/local/ -xzf go$GO_VERSION.linux-ppc64le.tar.gz
rm -f go$version.linux-ppc64le.tar.gz

mkdir -p $PACKAGE_SOURCE_ROOT
cd $PACKAGE_SOURCE_ROOT
export GO111MODULE=off

# installing  toml dependency toml-test 
git clone https://github.com/BurntSushi/toml-test $PACKAGE_SOURCE_ROOT/toml-test || exit 1 
cd $PACKAGE_SOURCE_ROOT/toml-test
git checkout 84959a4 


git clone $PACKAGE_URL $PACKAGE_SOURCE_ROOT/$PACKAGE_NAME || exit 1 
cd $PACKAGE_SOURCE_ROOT/$PACKAGE_NAME
git checkout $PACKAGE_VERSION

# installing toml-test from toml directory because  toml-test depends on toml 
go install ../toml-test

#building and testing toml 

 if !  make && make install; then
     echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
     echo "$PACKAGE_URL $PACKAGE_NAME"
     echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
     exit 1
 fi

 if !   make test; then
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