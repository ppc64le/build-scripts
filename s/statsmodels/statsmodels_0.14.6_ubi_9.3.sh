#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : statsmodels
# Version          : 0.14.6
# Source repo      : https://github.com/statsmodels/statsmodels.git
# Tested on        : UBI:9.3
# Language         : Python
# Ci-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Shivansh sharma <shivansh.s1@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# -----------------------------------------------------------------------------
echo "------------------------------------------------------------Cloning statsmodels github repo--------------------------------------------------------------"
PACKAGE_NAME=statsmodels
PACKAGE_VERSION=${1:-v0.14.6}
PACKAGE_URL=https://github.com/statsmodels/statsmodels.git
PACKAGE_DIR=statsmodels

echo "------------------------------------------------------------Installing requirements for statsmodels------------------------------------------------------"
dnf install -y wget git g++ gcc gcc-c++ gcc-gfortran \
    meson ninja-build openblas-devel libjpeg-devel bzip2-devel libffi-devel zlib-devel \
    libtiff-devel freetype-devel make cmake automake autoconf procps-ng \
    python3.12 python3.12-devel python3.12-pip

git clone $PACKAGE_URL
cd $PACKAGE_DIR
git checkout $PACKAGE_VERSION

echo "------------------------------------------------------------Installing statsmodels------------------------------------------------------"
if ! python3.12 -m pip install .; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

python3.12 -m pip install pytest
if python3.12 --version | grep -Eq "3\.(11|12|13)"; then
  python3.12 -m pip install numpy==2.0.2
  python3.12 -m pip install pandas==2.2.3
  python3.12 -m pip install scipy==1.15.2 --prefer-binary
fi

echo "------------------------------------------------------------Run tests for statsmodels------------------------------------------------------"
cd $PACKAGE_DIR
export PYTEST_ADDOPTS="--continue-on-collection-errors --ignore=tsa/tests/test_stattools.py"
if ! pytest --import-mode=importlib; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_Test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
