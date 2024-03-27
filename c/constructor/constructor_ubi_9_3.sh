#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : constructor
# Version       : 3.7.0
# Source repo   : https://github.com/conda/constructor
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


# Variables
export PACKAGE_VERSION=${1:-"3.7.0"}
export PACKAGE_NAME=constructor
export PACKAGE_URL=https://github.com/conda/constructor
export PYTHON_VERSION=3.8


yum install -y gcc gcc-c++ make cmake git wget  autoconf automake libtool pkgconf-pkg-config info gzip tar bzip2 zip unzip xz zlib-devel yum-utils fontconfig fontconfig-devel openssl-devel  fontconfig fontconfig-devel  ncurses-devel python3-setuptools

#Installing python3.8 on ubi9.3
wget https://www.python.org/ftp/python/3.8.12/Python-3.8.12.tgz
tar xzf Python-3.8.12.tgz
cd Python-3.8.12
./configure --prefix=/opt/python3.8 --enable-optimizations
make -j4
make altinstall
ln -s /opt/python3.8/bin/python3.8 /usr/local/bin/python3.8
python3.8 --version
cd ..

# Clone the repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
cd ..

# miniconda installation 
wget https://repo.anaconda.com/miniconda/Miniconda3-py38_4.9.2-Linux-ppc64le.sh -O miniconda.sh
bash miniconda.sh -b -p $HOME/miniconda
export PATH="$HOME/miniconda/bin:$PATH"
conda --version
python3 --version
$HOME/miniconda/condabin/conda config --add channels conda-forge
conda env create -n constructor-dev -f constructor/dev/environment.yml 
conda init bash 
eval "$(conda shell.bash hook)"
conda activate constructor-dev
pip install pytest pytest-cov coverage jinja2
yum install -y python3-ruamel-yaml-clib

export PATH="$HOME/miniconda/bin:$PATH"
export LD_LIBRARY_PATH=/usr/lib64
export PATH=$LD_LIBRARY_PATH:$PATH

cd $PACKAGE_NAME
python3 setup.py build
conda install constructor -y


# Build package
if !(python3 setup.py install) ; then
    echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_Fails"
    exit 1
fi

# Run test cases
if !(pytest -vv --cov=constructor --cov-branch tests/ -m "not examples"); then
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

