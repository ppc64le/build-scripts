#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : matplotlib
# Version       : v3.8.2
# Source repo   : https://github.com/matplotlib/matplotlib.git
# Tested on     : UBI 8.10
# Language      : Python, C++, Jupyter Notebook
# Travis-Check  : False
# Script License: Apache License, Version 2 or later
# Maintainer    : Chandan.Abhyankar@ibm.com
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

yum install -y python311 python3.11-devel python3.11-pip git gcc-c++ cmake wget
yum install -y openblas-devel openblas --enablerepo=codeready-builder-for-rhel-8-ppc64le-rpms
yum install -y zlib zlib-devel libjpeg-turbo libjpeg-turbo-devel
pip3.11 install pytest hypothesis build pybind11

# Clone the matplotlib package.
PACKAGE_NAME=matplotlib
PACKAGE_VERSION=${1:-v3.8.2}
PACKAGE_URL=https://github.com/matplotlib/matplotlib.git

git clone $PACKAGE_URL
cd $PACKAGE_NAME/
git checkout $PACKAGE_VERSION
git submodule update --init

# Download qhull
mkdir -p build
wget 'http://www.qhull.org/download/qhull-2020-src-8.0.2.tgz'
gunzip qhull-2020-src-8.0.2.tgz
tar -xvf qhull-2020-src-8.0.2.tar
mv qhull-2020.2 build/

# Build the package and create the whl file in /dist folder (This is dependent on numpy,pillow)
python3.11 -m build --wheel

# Install the package
python3.11 -m pip install dist/matplotlib-3.8.2-cp311-cp311-linux_ppc64le.whl
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
python3.11 -c "import matplotlib; print(matplotlib.__file__)"

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

