#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: metricbeat
# Version	: v8.7.0
# Source repo	: https://github.com/elastic/beats
# Tested on	: UBI: 8.5
# Language      : GO
# Travis-Check  : False
# Script License: Apache License, Version 2 or later
# Maintainer	: Stuti Wali <Stuti.Wali@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

# Variables
set -e
PACKAGE_NAME=metricbeat
PACKAGE_URL=https://github.com/elastic/beats
#PACKAGE_VERSION is configurable can be passed as an argument.
PACKAGE_VERSION=${1:-v8.7.0}
GO_VERSION=${GO_VERSION:-1.20.1}
CURRENT_DIR=`pwd`
SCRIPT=$(readlink -f $0)
SCRIPT_DIR=$(dirname $SCRIPT)

#Install dependencies
yum install git make gcc python39 python39-devel wget gcc-c++ openssl openssl-devel -y

#Install go
wget https://go.dev/dl/go${GO_VERSION}.linux-ppc64le.tar.gz
rm -rf /usr/local/go
tar -C /usr/local -xzf go${GO_VERSION}.linux-ppc64le.tar.gz
export GOROOT=/usr/local/go
export GOPATH=$HOME/go
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin:/usr/local/bin
go version

#Install Rust compiler
curl https://sh.rustup.rs -sSf | sh -s -- -y
PATH="$HOME/.cargo/bin:$PATH"
source $HOME/.cargo/env

pip3 install docker-compose pytest

# Cloning the repository from remote to local
git clone $PACKAGE_URL
cd beats
git checkout $PACKAGE_VERSION

#Build
make
cd $PACKAGE_NAME
mage build

#Test
mage goUnitTest

#Below script is for integration tests. It requires virtual environment (Docker inside docker) which is disabled in Currency. That's why commenting out below script

#git apply $SCRIPT_DIR/metricbeat.diff
#docker build -t metricbeat:8.7.0 .
#docker pull prom/prometheus:v2.40.1
#MODULE="prometheus" mage goIntegTest

#Creating virtual environment for python intgration tests.
#cd ..
#make python-env
#cp /root/.cargo /beats/build/python-env/bin/ -r
#RUSTUP_HOME=/beats/build/python-env/bin/
#CARGO_HOME=/beats/build/python-env/bin/
#cd build/python-env/bin
#./python3 pip install grpcio==1.42.0
#./python3 pip install --quiet  -Ur /beats/libbeat/tests/system/requirements.txt
#cd /beats/metricbeat
#/beats/build/python-env/bin/pytest  --timeout=90 --durations=20 --junit-xml=build/TEST-python-integration.xml module/prometheus/test_prometheus.py tests/system/test_base.py

#Travis check is set to false as the container needs to be run with --priviledged flag.
