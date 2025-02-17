#!/bin/bash 

set -e  # Exit immediately if a command fails

export PACKAGE_VERSION=${1:-"4.3.3"}
export PACKAGE_NAME=gensim
export PACKAGE_URL=https://github.com/RaRe-Technologies/gensim

# Install system dependencies
yum install -y git gcc gcc-c++ wget atlas pkg-config openblas-devel \
               atlas-devel pkgconfig cmake python3.12-devel \
               python3.12-setuptools python3.12-test gcc-gfortran make

# Ensure Python 3.12 is installed
dnf install -y python3.12 python3.12-pip
python3.12 --version
pip3.12 --version

# Create and activate Python 3.12 virtual environment
python3.12 -m venv py312_env
source py312_env/bin/activate

# Upgrade pip and install required dependencies
python -m pip install --upgrade pip setuptools wheel meson pytest
python -m pip install requests ruamel-yaml nbformat testfixtures mock nbconvert
python -m pip install numpy==1.26.4 scipy==1.13.1 Cython 

# Clone the repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
export TOXENV=py312
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