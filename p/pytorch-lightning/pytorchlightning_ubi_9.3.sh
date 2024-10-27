#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : pytorch-lightning
# Version       : 2.2.4
# Source repo : https://github.com/Lightning-AI/pytorch-lightning.git
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
PACKAGE_NAME=pytorch-lightning
PACKAGE_VERSION=${1:-2.2.4}
PACKAGE_URL=https://github.com/Lightning-AI/pytorch-lightning.git
 
# Install dependencies and tools
yum install -y git wget gcc gcc-c++ python python3-devel python3 python3-pip openblas-devel
pip install numpy wheel
 
# Clone and install PyTorch
git clone https://github.com/pytorch/pytorch.git
cd pytorch
git checkout v2.5.0
wget https://repo.anaconda.com/miniconda/Miniconda3-py39_4.9.2-Linux-ppc64le.sh -O miniconda.sh
bash miniconda.sh -b -u -p $HOME/miniconda
export PATH="$HOME/miniconda/bin:$PATH"
conda install -y cmake ninja rust
pip install -r requirements.txt
python setup.py install
cd ..
 
# Clone the Lightning Fabric repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
 
# Comment out the torch version line in base.txt files
FILES=(
    "./requirements/fabric/base.txt"
    "./requirements/pytorch/base.txt"
)
for FILE in "${FILES[@]}"; do
    if [ -f "$FILE" ]; then
        sed -i '/torch >=2.1.0, <2.5.0/s/^/# /' "$FILE"
        echo "Commented torch version in $FILE"
    else
        echo "File $FILE not found."
    fi
done
 
# Install requirements and package
pip install -r requirements.txt
if ! (python3 setup.py install); then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Install_Fails"
    exit 1
fi
 
# Build the wheel package
python3 setup.py bdist_wheel
