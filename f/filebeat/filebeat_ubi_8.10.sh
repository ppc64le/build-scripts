#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : filebeat
# Version          : v8.15.2
# Source repo      : https://github.com/elastic/beats
# Tested on        : UBI 8.10
# Language         : Go
# Travis-Check     : False
# Script License   : Apache License, Version 2 or later
# Maintainer       : Balavva Mirji <Balavva.Mirji@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -e 
PACKAGE_NAME=filebeat
PACKAGE_VERSION=${1:-v8.15.2}
PACKAGE_URL=https://github.com/elastic/beats

# Install required dependencies
yum install -y git curl make wget tar gcc gcc-c++ openssl openssl-devel python3.11 python3.11-devel systemd-devel

#Installing pip
wget --no-check-certificate -q https://bootstrap.pypa.io/get-pip.py
python3 get-pip.py
rm get-pip.py 

pip3 install wheel -v
pip3 install "cython<3.0.0" pyyaml==5.4.1 --no-build-isolation -v

# Install Rust
export RUST_VERSION="1.76.0"
printf -- 'Installing Rust \n'
wget -q -O rustup-init.sh https://sh.rustup.rs
bash rustup-init.sh -y
export PATH=$PATH:$HOME/.cargo/bin
rustup toolchain install ${RUST_VERSION}
rustup default ${RUST_VERSION}
rustc --version | grep "${RUST_VERSION}"

# Install go
export GO_VERSION=${GO_VERSION:-1.22.9}
export GOROOT=${GOROOT:-"/usr/local/go"}
export GOPATH=${GOPATH:-$HOME/go}
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin:/usr/local/bin
wget https://golang.org/dl/go${GO_VERSION}.linux-ppc64le.tar.gz
tar -C /usr/local -xvzf go${GO_VERSION}.linux-ppc64le.tar.gz
rm -rf go${GO_VERSION}.linux-ppc64le.tar.gz
export CGO_ENABLED="0"

git clone $PACKAGE_URL
cd beats/$PACKAGE_NAME
git checkout $PACKAGE_VERSION

export GRPC_PYTHON_BUILD_SYSTEM_OPENSSL=true
export PYTHON_EXE=python3
export PYTHON_ENV=/tmp/venv3

if ! make ; then
    echo "------------------$PACKAGE_NAME::Build_Fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
    exit 1
fi

if ! make update ; then
    echo "------------------$PACKAGE_NAME::Update_Fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Update_Fails"
    exit 1
fi

if ! make fmt ; then
    echo "------------------$PACKAGE_NAME::Formatting_Fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Formatting_Fails"
    exit 1
fi

if ! make unit ; then
    echo "------------------$PACKAGE_NAME::Unit_Test_Fails-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Fail|  Build_Success_but_Unit_Test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME::Build_and_Unit_Test_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Build_and_Unit_Test_Success"
fi

if ! make system-tests ; then
    echo "------------------$PACKAGE_NAME::System_Test_Fails-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Fail|  Build_Success_but_System_Test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME::Build_and_System_Test_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Build_and_System_Test_Success"
    exit 0
fi
