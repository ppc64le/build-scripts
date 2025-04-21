#!/bin/bash -ex
# -----------------------------------------------------------------------------
#
# Package          : vision
# Version          : v0.16.2
# Source repo      : https://github.com/pytorch/vision
# Tested on        : UBI:9.3
# Language         : Python
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Stuti Wali <Stuti.Wali@ibm.com>
#
# -----------------------------------------------------------------------------

# Variables
PACKAGE_NAME=vision
PACKAGE_VERSION=${1:-v0.16.2}
PACKAGE_URL=https://github.com/pytorch/vision

echo "---------------------------------------------Installing dependencies-------------------------------------------------------"
yum install -y wget

yum install -y \
  python python-devel python-pip git gcc gcc-c++ make cmake openssl-devel bzip2-devel \
  libffi-devel zlib-devel libjpeg-devel freetype-devel procps-ng openblas-devel \
  meson ninja-build gcc-gfortran libomp-devel zip unzip sqlite-devel

export LD_LIBRARY_PATH=/usr/lib64/libopenblas.so.0:$LD_LIBRARY_PATH

# Install Rust
curl https://sh.rustup.rs -sSf | sh -s -- -y
source "$HOME/.cargo/env"

echo "---------------------------------------------Installing Python dependencies via pip----------------------------------------"
pip install wheel scipy ninja build pytest "numpy<2.0" setuptools

# Install PyTorch
echo "---------------------------------------------Cloning pytorch--------------------------------------------------------------"
git clone --recursive https://github.com/pytorch/pytorch.git
cd pytorch
git checkout v2.1.2
git submodule sync
git submodule update --init --recursive
pip install -r requirements.txt

echo "---------------------------------------------Patching pytorch-------------------------------------------------------------"
wget https://raw.githubusercontent.com/ppc64le/build-scripts/python-ecosystem/p/pytorch/pytorch_v2.0.1.patch
git apply ./pytorch_v2.0.1.patch
python setup.py install
cd ..

# Clone the vision repo
echo "---------------------------------------------Cloning vision---------------------------------------------------------------"
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

# Install more Python deps
pip install setuptools meson meson-python cython
pip install pytest-mock pytest-xdist pytest-timeout

# Install vision
echo "---------------------------------------------Installing vision------------------------------------------------------------"
if ! (pip install . --no-build-isolation); then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Install_Fails"
    exit 1
fi

# Run test cases (excluding some long-running or platform-specific ones)
echo "---------------------------------------------Testing vision---------------------------------------------------------------"
if !(pytest -v test/ --dist=loadfile -n 1 -p no:warnings \
    --ignore=test/test_backbone_utils.py \
    --ignore=test/test_models.py \
    --ignore=test/test_transforms.py \
    --ignore=test/test_transforms_v2_functional.py \
    -k "not test_draw_boxes"); then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Pass | Both_Install_and_Test_Success"
    exit 0
fi
