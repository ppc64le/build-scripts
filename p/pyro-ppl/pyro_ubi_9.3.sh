#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : pyro
# Version       : 1.9.0
# Source repo : https://github.com/pyro-ppl/pyro.git
# Tested on     : UBI:9.3
# Language      : Python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
#
# Disclaimer: This script has been tested in root mode on the given
# platform using the mentioned version of the package.
# It may not work as expected with newer versions of the
# package and/or distribution. In such a case, please
# contact the "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

# Exit immediately if a command exits with a non-zero status
set -e
# Variables
PACKAGE_NAME=pyro
PACKAGE_VERSION=${1:-1.9.0}
PACKAGE_URL=https://github.com/pyro-ppl/pyro.git


# Install dependencies and tools
yum install -y git wget gcc gcc-c++ python python3-devel python3 python3-pip openblas-devel
pip install numpy wheel

#clone and install pytorh
git clone https://github.com/pytorch/pytorch.git
cd pytorch
git checkout v2.5.0
conda install -y cmake ninja rust
pip install -r requirements.txt
python setup.py install
cd ..

#clone repository 
git clone $PACKAGE_URL
cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#install
if ! (python3 setup.py install) ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

python3 setup.py bdist_wheel
