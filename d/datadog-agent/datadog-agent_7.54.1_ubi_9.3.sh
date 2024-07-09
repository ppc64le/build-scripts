#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package           : datadog-agent
# Version           : 7.54.1
# Source repo       : https://github.com/DataDog/datadog-agent
# Tested on         : UBI:9.3
# Language          : Go
# Travis-Check      : True
# Script License    : Apache License, Version 2 or later
# Maintainer        : Ramnath Nayak <Ramnath.Nayak@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=datadog-agent
PACKAGE_URL=https://github.com/DataDog/datadog-agent.git
PACKAGE_VERSION=${1:-7.54.1}

# Install required dependencies
yum install -y wget git python3 python3-devel openssl openssl-devel make gcc gcc-c++ diffutils cmake patch

# Install go version 1.22
export GO_VERSION=${GO_VERSION:-1.22.0}
export GOROOT=${GOROOT:-"/usr/local/go"}
export GOPATH=${GOPATH:-$HOME/go}
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin:/usr/local/bin

wget https://golang.org/dl/go${GO_VERSION}.linux-ppc64le.tar.gz
tar -C /usr/local -xvzf go${GO_VERSION}.linux-ppc64le.tar.gz
rm -rf go${GO_VERSION}.linux-ppc64le.tar.gz

# Upgrade pip
python3 -m pip install --upgrade pip 

git clone $PACKAGE_URL 
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

# Apply patch
wget https://raw.githubusercontent.com/ramnathnayak-ibm/build-scripts/datadog-agent/d/datadog-agent/datadog-agent_7.54.1.patch
git apply --ignore-whitespace datadog-agent_7.54.1.patch

# Build and install dependencies
python3 -m pip install codecov --ignore-installed -r requirements.txt
export PATH=$PATH:/usr/local/bin
invoke -e install-tools

# To build rtloader
invoke -e rtloader.make && invoke -e rtloader.install

if ! invoke agent.build --build-exclude=systemd; then
        echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
	      exit 1
fi

if ! invoke test --targets=./pkg/aggregator; then
        echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Test_Fails"
	      exit 2
else
        echo "------------------$PACKAGE_NAME:install_and_test_success-------------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Install_and_Test_Success"
	      exit 0
fi
