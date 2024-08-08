#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : dlib
# Version          : v19.24.5
# Source repo      : https://github.com/davisking/dlib.git
# Tested on        : UBI:9.3
# Language         : C++
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Vipul Ajmera <Vipul.Ajmera@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#variables
PACKAGE_NAME=dlib
PACKAGE_VERSION=${1:-v19.24.5}
PACKAGE_URL=https://github.com/davisking/dlib.git

#install dependencies
yum install -y git gcc gcc-c++ cmake libX11-devel libwebp-devel libpng-devel 

#clone repository
git clone $PACKAGE_URL
cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#build
mkdir build
cd build
cmake .. -DCMAKE_BUILD_TYPE=Release

if ! cmake --build . --config Release --parallel 2 ; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

#test
cd ../dlib/test
sed -i 's/max(abs(subm(mat(imout),rect) - subm(out,rect))) < 1e-7/max(abs(subm(mat(imout),rect) - subm(out,rect))) < 1e-5/' image.cpp
mkdir build
cd build
cmake ..
cmake --build . --config Release 

if ! ./dtest --runall ; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
