# ----------------------------------------------------------------------------
#
# Package	: libHLC
# Version	: 0.1
# Source repo	: https://github.com/numba/libHLC
# Tested on	: ubuntu_16.04
# Script License: Apache License, Version 2 or later
# Maintainer	: Snehlata Mohite <smohite@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

sudo apt-get update -y
sudo apt-get install -y git cmake libdwarf-dev libelf-dev llvm-dev \
    ncurses-dev re2c perl g++ make zlib1g-dev libedit-dev python-dev \
    llvm-3.6-dev

WDIR=`pwd`
git clone https://github.com/numba/libHLC
git clone https://github.com/HSAFoundation/HSAIL-Tools.git
cd HSAIL-Tools
mkdir -p build/lnx64
cd build/lnx64
cmake ../..
make -j
sudo make install

cd $WDIR
git clone https://github.com/HSAFoundation/HLC-HSAIL-Development-LLVM
mkdir test_llvm
cd test_llvm
cmake $WDIR/HLC-HSAIL-Development-LLVM -DLLVM_ENABLE_EH=ON \
    -DLLVM_ENABLE_RTTI=ON -DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD=HSAIL
cd ..
cd test_llvm
make -j4
sudo make install
sudo cp $WDIR/test_llvm/lib/libLLVMHSAILUtil.a /usr/local/lib
cd $WDIR/libHLC
LLVMCONFIG=/usr/lib/llvm-3.6/bin/llvm-config make
sudo cp $WDIR/libHLC/libHLC.so /usr/local/lib
