#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: beats/metricbeat
# Version	: v8.5.1
# Source repo	: https://github.com/elastic/beats/tree/main/metricbeat
# Tested on	: UBI: 8.5
# Language      : GO
# Travis-Check  : False
# Script License: Apache License, Version 2 or later
# Maintainer	: Sunidhi Gaonkar<Sunidhi.Gaonkar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

CURRENT_DIR=`pwd`
SCRIPT=$(readlink -f $0)
SCRIPT_DIR=$(dirname $SCRIPT)

#Install dependencies
yum install git make gcc python39 python39-devel wget gcc-c++ openssl openssl-devel -y

#Install go
GO_VERSION=1.19
wget https://golang.org/dl/go$GO_VERSION.linux-ppc64le.tar.gz
tar -C /bin -xzf go$GO_VERSION.linux-ppc64le.tar.gz
rm -rf go$GO_VERSION.linux-ppc64le.tar.gz

#Install Rust compiler
curl https://sh.rustup.rs -sSf | sh -s -- -y
PATH="$HOME/.cargo/bin:$PATH"
source $HOME/.cargo/env

pip3 install docker-compose pytest

git clone https://github.com/elastic/beats
cd beats
git checkout v8.5.1

#set GOPATH
export PATH=$PATH:/bin/go/bin
export GOPATH=/root/beats/metricbeat/go
export PATH=$GOPATH/bin:$PATH

#Build
make
cd metricbeat
mage build

#Test
mage unitTest

git apply $SCRIPT_DIR/metricbeat.diff
docker build -t metricbeat:8.5.1 .
docker pull prom/prometheus:v2.40.1
MODULE="prometheus" mage goIntegTest

#Creating virtual environment for python intgration tests.
cd ..
make python-env
cp /root/.cargo /beats/build/python-env/bin/ -r
RUSTUP_HOME=/beats/build/python-env/bin/
CARGO_HOME=/beats/build/python-env/bin/
cd build/python-env/bin
./python3 pip install --quiet  -Ur /beats/libbeat/tests/system/requirements.txt
cd /beats/metricbeat
/beats/build/python-env/bin/pytest  --timeout=90 --durations=20 --junit-xml=build/TEST-python-integration.xml module/prometheus/test_prometheus.py tests/system/test_base.py

#Travis check is set to false as the container needs to be run with --priviledged flag.
