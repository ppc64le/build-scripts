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
yum install -y git wget gcc gcc-c++ python python3-devel python3 python3-pip openblas-devel cmake gcc-gfortran
pip install numpy wheel scipy ninja build pytest wheel
pip install "numpy<2.0"
 
#clone and install pytorch
git clone https://github.com/pytorch/pytorch.git
cd pytorch
git checkout v2.5.0
 
# Check if Rust is installed
if ! command -v rustc &> /dev/null; then
    # If Rust is not found, install Rust
    echo "Rust not found. Installing Rust..."
    curl https://sh.rustup.rs -sSf | sh -s -- -y
    source "$HOME/.cargo/env"
else
    echo "Rust is already installed."
fi
 
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
 
#run tests
if !(pytest -m "not supported or test_verify_cert_signature or verify_cert_signature" \
--ignore=tests/distributions/test_pickle.py \
--ignore=tests/distributions/test_spanning_tree.py \
--ignore=tests/distributions/test_stable.py \
--ignore=tests/infer/autoguide/test_gaussian.py \
--ignore=tests/infer/mcmc/test_valid_models.py \
--ignore=tests/infer/test_autoguide.py \
--ignore=tests/nn/test_module.py \
--ignore=tests/optim/test_optim.py \
--ignore=tests/poutine/test_poutines.py \
--ignore=tests/test_examples.py \
--disable-warnings); then
    echo "------------------$PACKAGE_NAME:build_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Build_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:build_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Pass | Both_Build_and_Test_Success"
fi
