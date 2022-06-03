#!/bin/bash -e


# ----------------------------------------------------------------------------
# Package          : protobuf
# Version          : v21.1
# Source repo      : https://github.com/protocolbuffers/protobuf.git
# Tested on        : UBI 8.5
# Language         : C++
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Ankit Paraskar <Ankit.Paraskar@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

# Variables

PACKAGE_NAME=protobuf
PACKAGE_URL=https://github.com/protocolbuffers/protobuf.git
#PACKAGE_VERSION is configurable can be passed as an argument.
PACKAGE_VERSION=v21.1


yum install -y git autoconf automake libtool make unzip gcc-c++

HOME_DIR=$(pwd)
echo $HOME_DIR

if ! git clone $PACKAGE_URL $PACKAGE_NAME; then
    echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails"
    exit 1
fi



cd "$HOME_DIR"/$PACKAGE_NAME || exit
git checkout $PACKAGE_VERSION

git submodule update --init --recursive
./autogen.sh
./configure
make -j$(nproc)

if ! make check; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
    exit 1
fi

make install
ldconfig

