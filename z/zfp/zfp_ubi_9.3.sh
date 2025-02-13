#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : zfp
# Version       : 1.0.0
# Source repo   : https://github.com/LLNL/zfp
# Tested on     : UBI:9.3
# Language      : C,Python
# Travis-Check  : True
# Script License: Apache License 2.0
# Maintainer    : Vinod K<Vinod.K1@ibm.com>
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

echo "Installing dependencies..."
yum install -y wget gcc gcc-c++ gcc-gfortran git make python python-devel openssl-devel cmake

echo "Cloning and installing..."
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

echo "Installing cython and numpy.."
pip install  cython==0.29.36 numpy==1.23.5

mkdir build
cmake -B /zfp/build -DCMAKE_BUILD_TYPE=Release -DBUILD_ZFPY=ON -DPYTHON_INCLUDE_DIR=$(python -c "from distutils.sysconfig import get_python_inc; print(get_python_inc())")  -DPYTHON_LIBRARY=$(python -c "import distutils.sysconfig as sysconfig; print(sysconfig.get_config_var('LIBDIR'))")
cmake --build /zfp/build --target all --config Release

export LD_LIBRARY_PATH=/zfp/build/lib64:$LD_LIBRARY_PATH
ldconfig

echo "installing..."
if ! python setup.py install ; then
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
