#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : zfp
# Version       : 1.0.0
# Source repo   : https://github.com/LLNL/zfp
# Tested on     : UBI:9.5
# Language      : C,Python
# Travis-Check  : True
# Script License: Apache License 2.0
# Maintainer    : Tejas Badjate <Tejas.Badjate@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=zfp
PACKAGE_VERSION=${1:-1.0.0}
PACKAGE_URL=https://github.com/LLNL/zfp
PACKAGE_DIR="./zfp"

echo "Installing dependencies...."
yum install -y wget gcc gcc-c++ gcc-gfortran git make python3 python3-devel python3-pip openssl-devel cmake
echo "Cloning and installing..."
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

echo "Checking Python version..."
PYTHON_VERSION=$(python3 -c "import sys; print('.'.join(map(str, sys.version_info[:2])))")
IFS='.' read -r MAJOR MINOR <<< "$PYTHON_VERSION"
if [[ "$MAJOR" -gt 3 ]] || { [[ "$MAJOR" -eq 3 ]] && [[ "$MINOR" -ge 12 ]]; }; then
    echo "Python version is >= 3.12, installing numpy 2.2.2..."
    pip install cython numpy==2.2.2 wheel
else
    echo "Python version is < 3.12, installing numpy 1.23.5..."
    pip install cython==0.29.36 numpy==1.23.5 wheel
fi

echo "Creating build directory..."
mkdir -p build
cd build

echo "Running CMake..."
cmake .. -DCMAKE_BUILD_TYPE=Release -DBUILD_ZFPY=ON \
    -DPYTHON_EXECUTABLE=$(which python3) \
    -DPYTHON_INCLUDE_DIR=$(python3 -c "import sysconfig; print(sysconfig.get_path('include'))") \
    -DPYTHON_LIBRARY=$(python3 -c "import sysconfig; print(sysconfig.get_config_var('LIBDIR'))")

echo "Building zfp..."
make -j$(nproc)
make install 
# Note before importing zfp package update LD_LIBRARY_PATH with: /usr/local/lib64 else it will give libzfp.s0.1 file not found error
export LD_LIBRARY_PATH=$(pwd)/lib64:$LD_LIBRARY_PATH
ldconfig
cd ..

echo "installing..."
if ! pip install . ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
else
    echo "------------------$PACKAGE_NAME:Install_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass | Install_Success"
    exit 0
fi

#skipping test part as we don't have python tests to run.
