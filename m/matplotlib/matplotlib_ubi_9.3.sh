#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : matplotlib
# Version       : v3.10.3
# Source repo   : https://github.com/matplotlib/matplotlib.git
# Tested on     : UBI 9.3
# Language      : Python, C++, Jupyter Notebook
# Ci-Check  : True
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

yum install -y python3.12 python3.12-devel python3.12-pip git gcc-toolset-13-gcc gcc-toolset-13-gcc-c++ cmake wget
yum install -y openblas-devel ninja-build
yum install -y zlib zlib-devel libjpeg-turbo libjpeg-turbo-devel

export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH

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
wget https://github.com/qhull/qhull/archive/refs/tags/v8.0.2.tar.gz -O qhull-8.0.2.tar.gz
tar -xzf qhull-8.0.2.tar.gz
mv qhull-8.0.2 build/qhull-2020.2

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
python3.12 -m pip install  "pyparsing<3.2"  "patchelf>=0.11.0" "setuptools_scm>=7" 'meson-python<0.17.0,>=0.13.1'
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
