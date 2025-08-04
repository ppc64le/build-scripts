#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : matplotlib
# Version       : v3.10.3
# Source repo   : https://github.com/matplotlib/matplotlib.git
# Tested on     : UBI 9.3
# Language      : Python, C++, Jupyter Notebook
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : shivansh.s1@ibm.com
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

yum install -y python3.12 python3.12-devel python3.12-pip git gcc-c++ cmake wget
yum install -y openblas-devel ninja-build
yum install -y zlib zlib-devel libjpeg-turbo libjpeg-turbo-devel

# Clone the matplotlib package.
PACKAGE_NAME=matplotlib
PACKAGE_VERSION=${1:-v3.10.3}
PACKAGE_URL=https://github.com/matplotlib/matplotlib.git

git clone $PACKAGE_URL
cd $PACKAGE_NAME/
git checkout $PACKAGE_VERSION
git submodule update --init

# Download qhull
mkdir -p build
wget 'http://www.qhull.org/download/qhull-2020-src-8.0.2.tgz'
gunzip qhull-2020-src-8.0.2.tgz
tar -xvf qhull-2020-src-8.0.2.tar --no-same-owner
mv qhull-2020.2 build/
rm -f qhull-2020-src-8.0.2.tar

# Setup virtual environment for python
python3.12 -m pip install pytest hypothesis build meson pybind11 meson-python

# Build and Install the package (This is dependent on numpy,pillow)
python3.12 -m build
python3.12 -m pip install -e .

if [ $? == 0 ]; then
     echo "------------------$PACKAGE_NAME::Build_Pass---------------------"
     echo "$PACKAGE_VERSION $PACKAGE_NAME"
     echo "$PACKAGE_NAME  | $PACKAGE_URL | $PACKAGE_VERSION  | Pass |  Build_Success"
else
     echo "------------------$PACKAGE_NAME::Build_Fail-------------------------"
     echo "$PACKAGE_VERSION $PACKAGE_NAME"
     echo "$PACKAGE_NAME  | $PACKAGE_URL | $PACKAGE_VERSION  | Fail |  Build_Fail"
     exit 1
fi

# Test the package
python3.12 -c "import matplotlib; print(matplotlib.__file__)"

pytest ./lib/matplotlib/tests/test_units.py

if [ $? == 0 ]; then
     echo "------------------$PACKAGE_NAME::Test_Pass---------------------"
     echo "$PACKAGE_VERSION $PACKAGE_NAME"
     echo "$PACKAGE_NAME  | $PACKAGE_URL | $PACKAGE_VERSION  | Pass |  Test_Success"
     exit 0
else
     echo "------------------$PACKAGE_NAME::Test_Fail-------------------------"
     echo "$PACKAGE_VERSION $PACKAGE_NAME"
     echo "$PACKAGE_NAME  | $PACKAGE_URL | $PACKAGE_VERSION  | Fail |  Test_Fail"
     exit 2
fi