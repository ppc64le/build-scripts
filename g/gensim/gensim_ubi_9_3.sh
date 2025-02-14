#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : gensim
# Version       : 4.3.2
# Source repo   : https://github.com/RaRe-Technologies/gensim
# Tested on     : UBI: 9.3
# Language      : python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Stuti Wali <Stuti.Wali@ibm.com>
#
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------


set -e

export PACKAGE_VERSION=${1:-"4.3.2"}
export PACKAGE_NAME=gensim
export PACKAGE_URL=https://github.com/RaRe-Technologies/gensim

# Install dependencies
yum install -y git gcc gcc-c++ wget python3-devel python3-setuptools python3-test gcc-gfortran make

# miniconda, cmake installation
wget https://repo.anaconda.com/miniconda/Miniconda3-py39_4.9.2-Linux-ppc64le.sh -O miniconda.sh
bash miniconda.sh -b -p $HOME/miniconda
export PATH="$HOME/miniconda/bin:$PATH"
conda --version
python3 --version
python3 -m pip install -U pip

pip3 install --upgrade requests ruamel-yaml
conda install numpy Cython scipy -y
pip3 install nbformat pytest testfixtures mock nbconvert


# Clone the repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
export TOXENV=py39
python3 setup.py build_ext --inplace

# Build package
if !(python3 setup.py install) ; then
    echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_Fails"
    exit 1
fi

# Run test cases
if !(pytest); then
    echo "------------------$PACKAGE_NAME:build_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:build_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Build_and_Test_Success"
    exit 0
fi