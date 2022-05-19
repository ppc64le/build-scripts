#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : ClickHouse
# Version       : Latest(Top of Tree)
# Source repo   : https://github.com/ClickHouse/ClickHouse
# Tested on     : UBI 8.5
# Language      : C,C++
## Setting Travis to False as currently it can not run on travis CI due to the build time limit being exceeded which in tern will fail the Travis Ci build.
# Travis-Check  : False 
# Script License: Apache License, Version 2 or later
# Maintainer    : Pranav Pandit <pranav.pandit1@ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=ClickHouse
PACKAGE_URL=https://github.com/ClickHouse/ClickHouse

cd $HOME_DIR
sudo yum -y update && sudo yum install -y cmake git gcc wget clang python3

wget https://rpmfind.net/linux/centos/8-stream/PowerTools/ppc64le/os/Packages/ninja-build-1.8.2-1.el8.ppc64le.rpm
sudo yum install -y  ninja-build-1.8.2-1.el8.ppc64le.rpm

sudo yum install -y https://rpmfind.net/linux/centos/8-stream/BaseOS/ppc64le/os/Packages/ncurses-compat-libs-6.1-7.20180224.el8.ppc64le.rpm

if [ -d "$PACKAGE_NAME" ]; then
  echo "ClikHouse already present "
else
  git clone --recursive $PACKAGE_URL
fi

cd $PACKAGE_NAME

# ! each command accepts
# Update remote URLs for submodules. Barely rare case
git submodule sync
# Add new submodules
git submodule init
# Update existing submodules to the current state
git submodule update
# Two last commands could be merged together
git submodule update --init

if [ -d "build" ]; then
  echo "Build already present "
else
  mkdir build
fi
cd build

export CC=clang CXX=clang++
cmake ..

ninja
