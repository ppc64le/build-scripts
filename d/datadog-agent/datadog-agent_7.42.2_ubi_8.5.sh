#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package           : Datadog-Agent
# Version           : 7.42.2
# Source repo       : https://github.com/DataDog/datadog-agent.git
# Tested on         : UBI: 8.5
# Language          : Go
# Travis-Check      : True
# Script License    : Apache License, Version 2 or later
# Maintainer        : Vishaka Desai <Vishaka.Desai@ibm.com>
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
PACKAGE_VERSION=${1:-7.42.2}

export WORKDIR=`pwd`
SCRIPT=$(readlink -f $0)
SCRIPT_DIR=$(dirname $SCRIPT)
PATCH=$SCRIPT_DIR/datadog-agent_7.42.2.patch

# Install required dependencies
yum install -y wget git python38 python38-devel openssl openssl-devel make gcc gcc-c++ diffutils cmake

# Install go version 1.18
wget https://go.dev/dl/go1.18.5.linux-ppc64le.tar.gz && \
tar -C /bin -xf go1.18.5.linux-ppc64le.tar.gz && \
mkdir -p $WORKDIR/go/src $WORKDIR/go/bin $WORKDIR/go/pkg

export PATH=$PATH:/bin/go/bin
export GOPATH=$WORKDIR/go
export PATH=$PATH:$WORKDIR/go/bin

# Upgrade pip
python3 -m pip install --upgrade pip 

cd $GOPATH/src
git clone $PACKAGE_URL $GOPATH/src/github.com/DataDog/$PACKAGE_NAME 
cd $GOPATH/src/github.com/DataDog/$PACKAGE_NAME
git checkout $PACKAGE_VERSION

# Apply patch
git apply --ignore-whitespace $PATCH

# Build and install dependencies
python3 -m pip install codecov -r requirements.txt
export PATH=$PATH:/usr/local/bin
invoke -e install-tools
invoke agent.build --build-exclude=systemd

# To build rtloader
invoke -e rtloader.make && invoke -e rtloader.install

# To test
invoke test --skip-linters --build-exclude=systemd
