#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : oneTBB
# Version          : v2021.8.0
# Source repo      : https://github.com/uxlfoundation/oneTBB
# Tested on        : UBI:9.3
# Language         : Python
# Ci-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Anumala Rajesh <Anumala.Rajesh@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

set -ex

PACKAGE_NAME=oneTBB
PACKAGE_VERSION=${1:-v2021.8.0}
PACKAGE_URL=https://github.com/uxlfoundation/oneTBB
PACKAGE_DIR=oneTBB/python 
CURRENT_DIR="${PWD}"


yum install -y git make cmake wget python3 python3-devel python3-pip
yum install -y git gcc-toolset-13-gcc gcc-toolset-13-gcc-c++ cmake make wget openssl-devel bzip2-devel glibc-static libstdc++-static libffi-devel zlib-devel pkg-config automake autoconf libtool

yum install gcc-toolset-13 sudo -y

export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH
export GCC_HOME=/opt/rh/gcc-toolset-13/root/usr
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH
export CC=$GCC_HOME/bin/gcc
export CXX=$GCC_HOME/bin/g++

python3 -m pip install --upgrade pip 
python3 -m pip install wheel build setuptools 


# Installing Swing from source
echo " ------------------------------ Installing Swig ------------------------------ "

git clone https://github.com/nightlark/swig-pypi.git
cd swig-pypi

pip3 install .

echo " ------------------------------ Swig Installed Successfully ------------------------------ "

cd $CURRENT_DIR

# Installing hwloc from source
echo " ------------------------------ Installing hwloc ------------------------------ "

git clone https://github.com/open-mpi/hwloc
cd hwloc 

./autogen.sh   
./configure

make
make install

echo " ------------------------------ hwloc Installed Successfully ------------------------------ "

cd $CURRENT_DIR

echo "------------Cloning the Repository------------"
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

mkdir build
cd build/

pwd
if ! (cmake -DCMAKE_INSTALL_PREFIX=/tmp/my_installed_onetbb -DTBB_TEST=OFF -DBUILD_SHARED_LIBS=OFF -DBUILD_STATIC=ON -DCMAKE_CXX_FLAGS="-static-libgcc -static-libstdc++" -DCMAKE_EXE_LINKER_FLAGS="-static" -DTBB_BUILD=ON -DTBB4PY_BUILD=ON ..
);then
        echo "------------------$PACKAGE_NAME:cmake_fails-------------------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  CMAKE_Fails"
        exit 1
fi

echo "------------Building the package------------"
if ! (make -j4 python_build);then
        echo "------------------$PACKAGE_NAME:make_fails-------------------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  MAKE_Fails"
        exit 1
fi

echo "------------Export statements------------"
export TBBROOT=/tmp/my_installed_onetbb/
export CMAKE_PREFIX_PATH=$TBBROOT

echo "------------Installing the package------------"

if ! (make install);then
        echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
        exit 1
fi

cd ..
echo "------------Applying Patch------------"

wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/o/onetbb/tbb.patch
git apply tbb.patch

echo "------------Applied patch successfully---------------------"

echo "------------Export statements------------"
export CMAKE_PREFIX_PATH=/tmp/my_installed_onetbb/lib64/
export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:/usr/local/lib64/pkgconfig"
export CXXFLAGS="-I/tmp/my_installed_onetbb/include"
export LDFLAGS="-L/tmp/my_installed_onetbb/lib64"
export LDFLAGS="-L/usr/local/lib -l:libtbb.a -lstdc++ -static -static-libgcc -static-libstdc++ -lc -lrt -lpthread -ldl"

echo "=============== Building wheel =================="

cd $CURRENT_DIR
cd $PACKAGE_NAME/python

# Attempt to build the wheel without isolation
if ! python3 -m build --wheel --no-isolation --outdir="$CURRENT_DIR/"; then
    echo "============ Wheel Creation Failed for Python (without isolation) ================="
    echo "Attempting to build with isolation..."

    # Attempt to build the wheel without isolation
    if ! python3 -m build --wheel --outdir="$CURRENT_DIR/"; then
        echo "============ Wheel Creation Failed for Python ================="
        exit 1
    fi
else
        echo "------------------$PACKAGE_NAME:wheel_creation_success-------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  wheel_creation_success"
        exit 0
fi