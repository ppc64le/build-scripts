#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: protobuf
# Version	: v21.12
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
PACKAGE_VERSION=${1:-v21.12}
PACKAGE_URL=https://github.com/protocolbuffers/protobuf.git
HOME_DIR=${PWD}

sudo yum update -y
sudo yum install -y unzip autoconf automake bzip2 diffutils gcc-c++ git gzip libtool make tar wget zlib-devel

#Cloning into Protobuf repo
cd $HOME_DIR
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
git submodule update --init --recursive

#Generate config file
./autogen.sh

#Configuring Protobuf
./configure

#Building, Installing & Testing Protobuf
if ! make -j$(nproc); then
    echo "Build and Test Fails"
    exit 1
elif ! make check; then
    echo "Test Fails"
    exit 2
elif ! sudo make install; then
    echo "Install Fails"
	exit 1
else
    export PATH=/usr/local/bin:$PATH
	protoc --version
	echo "Build, Install and Test Success"
    exit 0
fi