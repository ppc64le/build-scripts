#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : pandas
# Version       : v2.2.0
# Source repo   : https://github.com/pandas-dev/pandas.git
# Tested on     : UBI:9.3
# Language      : Python, C, Cython, Html
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Bhagyashri Gaikwad <Bhagyashri.Gaikwad2@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=pandas
PACKAGE_VERSION=${1:-v2.2.0}
PYTHON_VERSION=${2:-3.11}
PACKAGE_URL=https://github.com/pandas-dev/pandas.git

yum install -y python${PYTHON_VERSION} python${PYTHON_VERSION}-devel python${PYTHON_VERSION}-pip git gcc gcc-c++ cmake ninja-build openblas-devel  gcc-gfortran

git clone $PACKAGE_URL
cd $PACKAGE_NAME/
git checkout $PACKAGE_VERSION
git submodule update --init --recursive

# Setup virtual environment for python
python${PYTHON_VERSION} -m venv pandas-env
source pandas-env/bin/activate

pip install --upgrade pip setuptools wheel
pip install "numpy==2.0.2" "scipy>=1.8.0,<1.16.0"
pip install cython meson-python ninja joblib threadpoolctl patchelf pytest build


# Optional install via setup (dev install)
python${PYTHON_VERSION} -m pip install .

# Build the package and create whl file (This is dependent on cython)
python${PYTHON_VERSION} -m build --wheel


# Test the package
cd ..
python${PYTHON_VERSION} -m pip show pandas
python${PYTHON_VERSION} -c "import pandas; print(pandas.__file__)"

if [ $? == 0 ]; then
     echo "------------------$PACKAGE_NAME::Test_Pass---------------------"
     echo "$PACKAGE_VERSION $PACKAGE_NAME"
     echo "$PACKAGE_NAME  | $PACKAGE_URL | $PACKAGE_VERSION  | Pass |  Test_Success"

     # Deactivate python environment (pandas-env)
         deactivate

     exit 0
else
     echo "------------------$PACKAGE_NAME::Test_Fail-------------------------"
     echo "$PACKAGE_VERSION $PACKAGE_NAME"
     echo "$PACKAGE_NAME  | $PACKAGE_URL | $PACKAGE_VERSION  | Fail |  Test_Fail"
     exit 2
fi
