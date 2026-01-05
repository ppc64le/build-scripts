#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : pandas
# Version       : v2.2.0
# Source repo   : https://github.com/pandas-dev/pandas.git
# Tested on     : UBI:9.3
# Language      : Python, C, Cython, Html
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Bhagyashri Gaikwad <Bhagyashri.Gaikwad2@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

PACKAGE_NAME=pandas
PACKAGE_VERSION=${1:-v2.3.0}
PACKAGE_URL=https://github.com/pandas-dev/pandas.git

yum install -y python3.12 python3.12-devel python3.12-pip git gcc gcc-c++ cmake ninja-build openblas-devel gcc-gfortran

git clone $PACKAGE_URL
cd $PACKAGE_NAME/
git checkout $PACKAGE_VERSION
git submodule update --init --recursive

# Setup virtual environment for python3.12
#python3.12 -m venv pandas-env
#source pandas-env/bin/activate

python3.12 -m pip install --upgrade pip setuptools wheel
python3.12 -m pip install "numpy==2.0.2" "scipy>=1.8.0,<1.16.0"
python3.12 -m pip install cython meson-python ninja joblib threadpoolctl patchelf pytest build

# Optional install via setup (dev install)
python3.12 -m pip install .

# Build the package and create whl file (This is dependent on cython)
#python3.12 -m build --wheel

# Test the package
cd ..
python3.12 -c "import pandas; print(pandas.__file__)"

if [ $? == 0 ]; then
     echo "------------------$PACKAGE_NAME::Test_Pass---------------------"
     echo "$PACKAGE_VERSION $PACKAGE_NAME"
     echo "$PACKAGE_NAME  | $PACKAGE_URL | $PACKAGE_VERSION  | Pass |  Test_Success"

     # Deactivate python environment (pandas-env)
     exit 0
else
     echo "------------------$PACKAGE_NAME::Test_Fail-------------------------"
     echo "$PACKAGE_VERSION $PACKAGE_NAME"
     echo "$PACKAGE_NAME  | $PACKAGE_URL | $PACKAGE_VERSION  | Fail |  Test_Fail"
     exit 2
fi
