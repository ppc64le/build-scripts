#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: protobuf
# Version	: v22.2
# Source repo	: https://github.com/protocolbuffers/protobuf.git
# Tested on	: UBI 8.5
# Language      : C,C++,Java
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Pooja Shah <Pooja.Shah4@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=protobuf
PACKAGE_VERSION=${1:-v22.2}
PACKAGE_URL=https://github.com/protocolbuffers/protobuf.git
HOME_DIR=${PWD}

sudo yum update -y
sudo yum install -y gcc-c++ wget git

#Installing Bazel
sudo dnf install -y dnf-plugins-core
sudo dnf copr enable vbatts/bazel -y
sudo dnf install -y bazel4

#Cloning into Protobuf repo
cd $HOME_DIR
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
git submodule update --init --recursive

#Building & Testing Protobuf
if ! bazel build :protoc :protobuf; then
    echo "Build and Test Fails"
    exit 2
else
    sudo cp bazel-bin/protoc /usr/local/bin
    protoc --version
    echo "Build and Test Success"
    exit 0
fi

#In this build script we are not running any tests as targets :protoc and :protobuf does not contain any tests