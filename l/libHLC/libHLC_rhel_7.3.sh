# ----------------------------------------------------------------------------
#
# Package	: libHLC
# Version	: 0.1
# Source repo	: https://github.com/numba/libHLC
# Tested on	: rhel_7.3
# Script License: Apache License, Version 2 or later
# Maintainer	: Atul Sowani <sowania@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

# Install dependencies.
sudo yum update -y
sudo yum install -y git cmake llvm-devel autoconf automake \
    ncurses-devel re2c perl gcc-c++ make python-devel \

WDIR=`pwd`

# Build and install re2c package.
git clone https://github.com/skvadrik/re2c.git re2c
cd re2c/re2c
./autogen.sh
./configure
make
make install
make bootstrap

# Build and install HSAIL.
cd $WDIR
git clone https://github.com/HSAFoundation/HSAIL-Tools.git
cd HSAIL-Tools
mkdir -p build/lnx64
cd build/lnx64
cmake ../..
make -j
sudo make install

# Build and install libLLVMHSAILUtil.
cd $WDIR
git clone https://github.com/HSAFoundation/HLC-HSAIL-Development-LLVM
mkdir test_llvm
cd test_llvm
cmake $WDIR/HLC-HSAIL-Development-LLVM -DLLVM_ENABLE_EH=ON \
    -DLLVM_ENABLE_RTTI=ON -DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD=HSAIL
make -j4
sudo make install
sudo cp $WDIR/test_llvm/lib/libLLVMHSAILUtil.a /usr/local/lib

# Build and install libHLC.
cd $WDIR
git clone https://github.com/numba/libHLC
cd libHLC
LLVMCONFIG=/usr/lib/llvm-3.6/bin/llvm-config make
sudo cp $WDIR/libHLC/libHLC.so /usr/local/lib
