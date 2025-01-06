#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : numactl
# Version          : v2.0.16
# Source repo      : https://github.com/numactl/numactl.git
# Tested on        : UBI:9.3
# Language         : C
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Rakshith R <rakshith.r5@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------- 

PACKAGE_NAME=numactl
PACKAGE_VERSION=${1:-v2.0.16}
PACKAGE_URL=https://github.com/numactl/numactl.git

# Install dependencies 
dnf install -y git gcc make autoconf automake libtool 

# Clone the repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME

# Prepare build environment
autoreconf -i

# Configure build 
./configure --prefix=$HOME/numactl_install

# Build the package
make
make install

# Add installation path
export PATH=$HOME/numactl_install/bin:$PATH
source ~/.bashrc  

# Run basic functionality tests for numactl
# Get available NUMA node 
available_node=$(numactl --hardware | grep -oP 'node \K\d+' | head -n 1)

# Check if numactl hardware information can be displayed
if ! numactl --hardware || ! numactl --show; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# Test interleaving memory across all NUMA nodes
if ! numactl --interleave=all stress --cpu 4 --vm 2 --vm-bytes 128M --timeout 30s; then
    echo "------------------$PACKAGE_NAME: Install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME: Install_&_Test_Both_Success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Pass | Both_Install_and_Test_Success"
    exit 0
fi
