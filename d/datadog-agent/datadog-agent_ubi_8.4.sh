#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package        : Datadog-Agent
# Version        : main
# Source repo    : https://github.com/DataDog/datadog-agent.git
# Tested on		: UBI 8.4
# Language      : Go
# Travis-Check  : True
# Script License : Apache License, Version 2 or later
# Maintainer     : Saurabh Gore <Saurabh.Gore@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

export WORKDIR=`pwd`
SCRIPT=$(readlink -f $0)
SCRIPT_DIR=$(dirname $SCRIPT)

# Install required dependencies
yum install -y wget git python38 python38-devel openssl openssl-devel make gcc gcc-c++ diffutils cmake

# Install go version 1.17
wget https://go.dev/dl/go1.17.6.linux-ppc64le.tar.gz && \
tar -C /bin -xf go1.17.6.linux-ppc64le.tar.gz && \
mkdir -p $WORKDIR/go/src $WORKDIR/go/bin $WORKDIR/go/pkg

export PATH=$PATH:/bin/go/bin
export GOPATH=$WORKDIR/go
export PATH=$PATH:$WORKDIR/go/bin

# Upgrade pip
python3 -m pip install --upgrade pip 


# Clone datadog-agent, build and execute unit tests
git clone https://github.com/DataDog/datadog-agent.git $GOPATH/src/github.com/DataDog/datadog-agent

cd $GOPATH/src/github.com/DataDog/datadog-agent


# To Build and install dependencies
python3 -m pip install codecov -r requirements.txt

inv -e install-tools
inv -e deps

invoke agent.build --build-exclude=systemd

# To build rtloader
inv -e rtloader.make
inv -e rtloader.install

GO111MODULE=on go get github.com/golangci/golangci-lint/cmd/golangci-lint
go mod tidy


# Apply git patch
git apply $SCRIPT_DIR/datadog-agent_ppc64le.patch


# To test
invoke test   --skip-linters --build-exclude=systemd

# 2 tests are in parity with x86.

# === Failed
# === FAIL: pkg/clusteragent/admission/controllers/webhook TestCreateWebhookV1beta1 (3.14s)
#     controller_v1beta1_test.go:67: Invalid Webhook: Webhooks should contain 2 entries, got 1

# === FAIL: pkg/clusteragent/admission/controllers/webhook TestUpdateOutdatedWebhookV1beta1 (3.17s)
#     controller_v1beta1_test.go:114: Invalid Webhook: Webhooks should contain 2 entries, got 1

