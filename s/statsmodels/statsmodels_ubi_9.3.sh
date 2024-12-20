#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : statsmodels
# Version          : 0.13.5
# Source repo      : https://github.com/statsmodels/statsmodels.git
# Tested on        : UBI:9.3
# Language         : Python
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Rakshith R <rakshith.r5@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------- 

PACKAGE_NAME=statsmodels
PACKAGE_VERSION=${1:-v0.13.5}
PACKAGE_URL=https://github.com/statsmodels/statsmodels.git

# dnf groupinstall -y "Development Tools" 

dnf install -y git gcc gcc-c++  gcc-gfortran openssl-devel python3-devel python3-pip \
    meson ninja-build openblas-devel libjpeg-devel bzip2-devel libffi-devel zlib-devel \
    libtiff-devel freetype-devel 
dnf update -y
dnf install -y make cmake automake autoconf g++ git gcc gcc-c++ wget openssl-devel bzip2-devel libffi-devel zlib-devel procps-ng python3-devel python3-pip libjpeg-devel

pip install pytest
pip install numpy==1.23

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#ln -sf /usr/local/bin/python3.10 /usr/bin/python3

#install
if ! pip install .; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# Run tests
if ! pytest; then
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
