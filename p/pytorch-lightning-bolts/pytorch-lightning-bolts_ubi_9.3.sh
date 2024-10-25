#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : lightning-bolts
# Version       : 0.7.0
# Source repo : https://github.com/Lightning-Universe/lightning-bolts.git
# Tested on     : UBI:9.3
# Language      : Python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
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
PACKAGE_NAME=lightning-bolts
PACKAGE_VERSION=${1:-0.7.0}
PACKAGE_URL=https://github.com/Lightning-Universe/lightning-bolts.git
TORCHVISION_URL=https://github.com/pytorch/vision.git


# Install dependencies and tools
yum install -y git wget gcc gcc-c++ python python3-devel python3 python3-pip openblas-devel
wget https://repo.anaconda.com/miniconda/Miniconda3-py39_4.9.2-Linux-ppc64le.sh -O miniconda.sh
bash miniconda.sh -b -u -p $HOME/miniconda
export PATH="$HOME/miniconda/bin:$PATH"

#clone and install pytorh
git clone https://github.com/pytorch/pytorch.git
cd pytorch
git checkout v2.5.0
conda install -y cmake ninja rust
pip install -r requirements.txt
python setup.py install
cd ..


# Step 1: Clone and install torchvision (dependency for lightning-bolts)
yum install -y openblas-devel
conda install conda-forge::pillow
conda install libstdcxx-ng
pip install numpy
git clone $TORCHVISION_URL
cd vision
# Install torchvision package
python3 setup.py install
cd ..  # Exit torchvision folder after installing it

# Step 2: Clone the main lightning-bolts repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME

# Checkout the specified version of lightning-bolts
git checkout $PACKAGE_VERSION

# Step 3: Install grpcio via conda
conda install -y grpcio

# Step 4: Install dependencies from the requirements.txt file
pip install -r requirements.txt

# Step 5: Build the wheel for lightning-bolts
python3 setup.py bdist_wheel

echo "------------------$PACKAGE_NAME: Install and build succeeded----------------------"
