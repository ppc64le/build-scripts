#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : hdbscan
# Version          : 0.8.33
# Source repo      : https://github.com/scikit-learn-contrib/hdbscan
# Tested on        : UBI:9.3
# Language         : Jupyter Notebook,Python
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Haritha Nagothu <haritha.nagothu2@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=hdbscan
PACKAGE_VERSION=${1:-0.8.33}
PACKAGE_URL=https://github.com/scikit-learn-contrib/hdbscan

echo "Installing dependencies..."
yum install -y git python3.11 python3.11-devel python3.11-pip wget  gcc-toolset-13 bzip2 cmake pkgconfig gcc-gfortran libjpeg-devel libjpeg zlib-devel
source /opt/rh/gcc-toolset-13/enable
export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH

#install openblas
echo "Downloading and installing openblas..."
git clone https://github.com/xianyi/OpenBLAS.git
cd OpenBLAS
echo "Starting make..."
make -j2
echo "Starting make install..."
make PREFIX=/usr/local/OpenBLAS install
echo "Completed make install..."
export PKG_CONFIG_PATH=/usr/local/OpenBLAS/lib/pkgconfig
cd ..

echo "Installing dependencies..."
echo "Installing dependencies..."
python3.11 -m pip install "numpy==1.26.3" "scikit-learn===1.3.2"
python3.11 -m pip install  setuptools wheel build packaging cython

echo "Cloning and installing..."
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
python3.11 -m pip install --upgrade pip

echo "Installing dependencies..."
python3.11 -m pip install pytest pandas NetworkX matplotlib

echo "Installing requirements.txt..."
python3.11 -m pip install -r requirements.txt
python3.11 setup.py build_ext --inplace

echo "Installing..."
if ! python3.11 -m pip install . ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

echo "Testing..."
if ! pytest; then
    echo "------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
