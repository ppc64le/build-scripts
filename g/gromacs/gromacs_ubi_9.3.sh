#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : gromacs 
# Version          : v2024.2
# Source repo      : https://github.com/gromacs/gromacs
# Tested on        : UBI:9.3
# Language         : C++
# Ci-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Vipul Ajmera <Vipul.Ajmera@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------------

PACKAGE_NAME=gromacs
PACKAGE_URL=https://github.com/gromacs/gromacs.git
PACKAGE_VERSION=${1:-v2024.2}

# Install dependencies
yum install -y gcc gcc-c++ make cmake libtool glibc zlib libgomp libgcc libgfortran git python3 python3-devel
pip3 install sphinx

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
mkdir build
cd build

# Configure with CMake
if ! cmake .. -DGMX_BUILD_OWN_FFTW=ON -DREGRESSIONTEST_DOWNLOAD=ON; then
  echo "------------------$PACKAGE_NAME:cmake_configure_fails---------------------------"
  echo "$PACKAGE_URL $PACKAGE_NAME"
  echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | CMake_Configure_Fails"
  exit 1
fi

# Build 
if ! make; then
  echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
  echo "$PACKAGE_URL $PACKAGE_NAME"
  echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Build_Fails"
  exit 1
fi

# Install 
if ! make install; then
  echo "------------------$PACKAGE_NAME:install_fails-----------------------------------"
  echo "$PACKAGE_URL $PACKAGE_NAME"
  echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Install_Fails"
  exit 1
fi

# Run tests
if ! make check; then
  echo "------------------$PACKAGE_NAME:install_success_but_test_fails------------------"
  echo "$PACKAGE_URL $PACKAGE_NAME"
  echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Install_Success_but_Test_Fails"
  exit 2
else
  echo "------------------$PACKAGE_NAME:install_&_test_both_success---------------------"
  echo "$PACKAGE_URL $PACKAGE_NAME"
  echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Pass | Build_Install_and_Test_Success"
  exit 0
fi



