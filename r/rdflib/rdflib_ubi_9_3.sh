#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : rdflib
# Version       : 7.0.0
# Source repo   : https://github.com/RDFLib/rdflib
# Tested on     : UBI: 9.3
# Language      : Python
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
# ----------------------------------------------------------------------------set -e

# Variables
export PACKAGE_VERSION=${1:-"7.0.0"}
export PACKAGE_NAME=rdflib
export PACKAGE_URL=https://github.com/RDFLib/rdflib
export LANG=en_US.utf8
export LD_LIBRARY_PATH=/usr/local/lib
HOME_DIR=`pwd`

# Install dependencies
yum install -y  git gcc gcc-c++  wget sqlite sqlite-devel libxml2-devel libxslt-devel make cmake 

# miniconda installation 
wget https://repo.anaconda.com/miniconda/Miniconda3-py310_23.10.0-1-Linux-ppc64le.sh -O miniconda.sh 
bash miniconda.sh -b -p $HOME/miniconda
export PATH="$HOME/miniconda/bin:$PATH"
conda create -n $PACKAGE_NAME python=3.10 -y
eval "$(conda shell.bash hook)"
conda activate $PACKAGE_NAME
python3 -m pip install -U pip

yum install -y openssl-devel
export PKG_CONFIG_PATH=/root/miniconda/envs/$PACKAGE_NAME/lib/pkgconfig

#installation of rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
export PATH="$HOME/.cargo/bin:$PATH"
source ~/.bashrc
rustc --version

# Clone the repository
cd $HOME_DIR
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
export TOXENV=py310
pip install -r devtools/requirements-poetry.in
pip install --upgrade poetry tox

PATH=$PATH:/usr/local/bin/


# Build package
if !(pip install -e .) ; then
    echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_Fails"
    exit 1
fi

# Run test cases
# Skipping "test_sparqleval" and "test_parser" test, reference : https://github.com/RDFLib/rdflib/issues/2649 and https://github.com/RDFLib/rdflib/issues/1519
if !(tox -e py310 -- pytest -k "not test_sparqleval and not test_parser"); then
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


