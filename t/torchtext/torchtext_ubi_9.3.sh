#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : torchtext
# Version          : 0.6.0
# Source repo      : https://github.com/pytorch/text.git
# Tested on        : UBI:9.3
# Language         : Python
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Aastha Sharma <aastha.sharma4@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------------

# Variables
PACKAGE_NAME=torchtext
PACKAGE_VERSION=${1:-0.6.0}
PACKAGE_URL=https://github.com/pytorch/text.git

# Install necessary system dependencies
yum install -y git gcc gcc-c++ make wget openssl-devel bzip2-devel libffi-devel zlib-devel python-devel python-pip cmake numpy ninja-build openblas-devel libomp-devel

# Clone the repository
git clone $PACKAGE_URL
cd text  
git checkout $PACKAGE_VERSION  

#Original directory
ORIGINAL_DIR=$(pwd)

# Upgrade pip
python3 -m pip install --upgrade pip

# Check if Rust is installed
if ! command -v rustc &> /dev/null; then
    # If Rust is not found, install Rust
    echo "Rust not found. Installing Rust..."
    curl https://sh.rustup.rs -sSf | sh -s -- -y
    source "$HOME/.cargo/env"  # Update environment variables to use Rust
else
    echo "Rust is already installed."
fi

# Build torch
git clone --recursive https://github.com/pytorch/pytorch.git
cd pytorch
pip install -r requirements.txt
python setup.py install 

# Back to torchtext directory
cd "$ORIGINAL_DIR"

# Install additional dependencies
pip install -r requirements.txt
pip install spacy
python -m spacy download en

#install
if ! (python3 setup.py install) ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi
