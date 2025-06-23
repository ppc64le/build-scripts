#!/bin/bash -e
#
# -----------------------------------------------------------------------------
#
# Package           : data
# Version           : v0.7.1
# Source repo       : https://github.com/pytorch/data.git
# Tested on         : UBI:9.3
# Language          : Python
# Travis-Check      : True
# Script License    : Apache License, Version 2.0
# Maintainer        : Vinod K<Vinod.K1@ibm.com>
#
# Disclaimer        : This script has been tested in root mode on given
# ==========          platform using the mentioned version of the package.
#                     It may not work as expected with newer versions of the
#                     package and/or distribution. In such case, please
#                     contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
PACKAGE_NAME=data
PACKAGE_VERSION=${1:-v0.7.1}
PACKAGE_URL=https://github.com/pytorch/data.git
PACKAGE_DIR=./data
CURRENT_DIR="${PWD}"

# Install dependencies
yum install -y wget

# Install essential build and Python dependencies
yum install -y python python-devel python-pip git gcc gcc-c++ gcc-gfortran make cmake \
    openssl-devel bzip2-devel libffi-devel zlib-devel libjpeg-devel freetype-devel \
    procps-ng openblas-devel meson ninja-build xz xz-devel libomp-devel \
    zip unzip sqlite-devel libwebp-devel

# Ensure LZMA support for Python
export LD_LIBRARY_PATH=/usr/lib64/libopenblas.so.0:/usr/lib64:$LD_LIBRARY_PATH

# Install Rust for building PyTorch components
curl https://sh.rustup.rs -sSf | sh -s -- -y
source "$HOME/.cargo/env"  # Update environment variables to use Rust

# Install necessary Python packages
pip install wheel scipy ninja build pytest pylzma portalocker
pip install "numpy<2.0" 'cmake==3.31.6'

git clone --recursive https://github.com/pytorch/pytorch.git
cd pytorch
git checkout v2.1.2
git submodule sync
git submodule update --init --recursive
pip install -r requirements.txt

wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/p/pytorch/pytorch_v2.0.1.patch
git apply ./pytorch_v2.0.1.patch
export MAX_JOBS=2
python setup.py install
cd ..

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

# Install additional Python dependencies
pip install setuptools meson meson-python
pip install cython 'cmake==3.31.6'
pip install pytest-mock pytest-xdist pytest-timeout torchtext

# Install the package
if ! python setup.py install ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi
export PYTHONPATH=$(pwd)
cd test
# Run test cases
if ! pytest --ignore=test_audio_examples.py \
             --ignore=test_text_examples.py \
             --ignore=test_period.py \
             --ignore=test_s3io.py; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
