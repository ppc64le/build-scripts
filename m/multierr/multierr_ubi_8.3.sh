# ----------------------------------------------------------------------------
#
# Package       : multierr
# Version       : v1.1.0
# Source repo   : https://github.com/uber-go/multierr
# Tested on     : UBI 8.3
# Script License: Apache License Version 2.0
# Maintainer	: Siddhesh Ghadi <Siddhesh.Ghadi@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash
set -ex

dnf update -y
dnf install gcc-c++ make wget git -y

export GOPATH=${GOPATH:-$HOME/go}
export GOROOT=${GOROOT:-"/usr/local/go"}
export PATH=$PATH:$GOPATH/bin:$GOROOT/bin

#installing go
wget https://golang.org/dl/go1.12.1.linux-ppc64le.tar.gz -O ~/go.tar.gz
rm -rf $GOROOT && tar -C $(dirname $GOROOT) -xzf  ~/go.tar.gz

#getting PKG version
if [ -z $1 ]; then
    BRANCH="v1.1.0"
else
    BRANCH=$1
fi


#installing package
mkdir -p $GOPATH/src/go.uber.org && cd $GOPATH/src/go.uber.org
git clone https://github.com/uber-go/multierr
cd multierr
git checkout $BRANCH
make
make test
