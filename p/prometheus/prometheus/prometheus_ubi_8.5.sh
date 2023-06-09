#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : prometheus
# Version       : v2.29.1
# Source repo   : https://github.com/prometheus/prometheus.git
# Tested on     : ubi 8.5
# Language      : go
# Travis-Check  : true
# Script License: Apache License, Version 2 or later
# Maintainer    : Sachin K {sachin.kakatkar@ibm.com}
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#Run the script:./prometheus_ubi_8.5.sh v2.29.1(version_to_test)
PACKAGE_NAME=prometheus
PACKAGE_VERSION=${1:-v2.29.1}
GO_VERSION=1.14.1
PACKAGE_URL=https://github.com/prometheus/prometheus.git

dnf install git wget jq make gcc-c++ python3-pip -y
pip3 install yamllint graphviz

#Install node
wget https://nodejs.org/download/release/latest-v14.x/node-v14.19.1-linux-ppc64le.tar.gz
tar -xvf node-v14.19.1-linux-ppc64le.tar.gz
ln -sf $(pwd)/node-v14.19.1-linux-ppc64le/bin/npm /bin/npm
ln -sf $(pwd)/node-v14.19.1-linux-ppc64le/bin/node /bin/node
ln -sf $(pwd)/node-v14.19.1-linux-ppc64le/bin/npx /bin/npx 
npm install -g yarn
ln -sf $(pwd)/node-v14.19.1-linux-ppc64le/bin/yarn /bin/yarn

mkdir -p /home/tester/output
cd /home/tester

#Install go
wget https://golang.org/dl/go$GO_VERSION.linux-ppc64le.tar.gz
rm -rf /home/tester/go && tar -C /home/tester -xzf go$GO_VERSION.linux-ppc64le.tar.gz
rm -rf go$GO_VERSION.linux-ppc64le.tar.gz
export GOPATH=/home/tester/go
export PATH=$GOPATH/bin:$GOROOT/bin:$PATH
export  GO111MODULE=on
mkdir -p $GOPATH/src/github.com/prometheus
cd $GOPATH/src/github.com/prometheus

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)


if ! git clone $PACKAGE_URL $PACKAGE_NAME; then
        echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/clone_fails
    echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails" > /home/tester/output/version_tracker
        exit 1
fi

cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

if ! make build SKIP_PREFLIGHT_CHECK=true; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/install_fails
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails" > /home/tester/output/version_tracker
	exit 1
fi

if ! make test; then
        echo "------------------$PACKAGE_NAME :install_success_but_test_fails---------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME " > /home/tester/output/test_fails
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails" > /home/tester/output/version_tracker
		exit 1
else
        echo "------------------$PACKAGE_NAME :install_&_test_both_success-------------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME " > /home/tester/output/test_success
        echo "$PACKAGE_NAME   |  $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success" > /home/tester/output/version_tracker
		exit 0
fi

#Build success and test failed with error: method Seek(t int64) bool should have signature Seek(int64, int) (int64, error)
#Similar error observed in other packages. error is because of signature conflift with standard file seek method and local seek method
