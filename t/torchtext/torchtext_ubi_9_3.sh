#!/bin/bash -ex
# -----------------------------------------------------------------------------
#
# Package          : text
# Version          : v0.15.2
# Source repo      : https://github.com/pytorch/text.git
# Tested on        : UBI:9.3
# Language         : Python
# Ci-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Ramnath Nayak <Ramnath.Nayak@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------------


# Variables
PACKAGE_NAME=text
PACKAGE_VERSION=${1:-v0.15.2}
PACKAGE_URL=https://github.com/pytorch/text.git
PACKAGE_DIR=text
CURRENT_DIR=$(pwd)
export BUILD_VERSION=${PACKAGE_VERSION#v}

export CC=/usr/bin/gcc
export CXX=/usr/bin/g++

# Install necessary system dependencies
yum install -y git gcc gcc-c++ make cmake wget openssl-devel python-devel python-pip bzip2-devel libffi-devel zlib-devel meson ninja-build gcc-gfortran openblas-devel libjpeg-devel zlib-devel libtiff-devel freetype-devel libomp-devel zip unzip sqlite-devel

#install rust
curl https://sh.rustup.rs -sSf | sh -s -- -y
source "$HOME/.cargo/env"  # Update environment variables to use Rust

#install pytorch
echo "------------------------------------------------------------Cloning pytorch github repo--------------------------------------------------------------"
git clone --recursive https://github.com/pytorch/pytorch.git
cd pytorch
git checkout v2.5.0
echo "------------------------------------------------------------Installing requirements for pytorch------------------------------------------------------"
pip install -r requirements.txt
git submodule update --init --recursive
echo "------------------------------------------------------------Installing setup.py for pytorch------------------------------------------------------"
python3 setup.py install
cd ..

export LD_LIBRARY_PATH=$CURRENT_DIR/pytorch/build/lib/:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=$CURRENT_DIR/text/build/lib.linux-ppc64le-cpython-312/torchtext/lib/:$LD_LIBRARY_PATH

pip install torchdata==0.7.1
pip install numpy pytest regex nltk sacremoses parameterized portalocker expecttest pytest-timeout
export BLIS_ARCH=generic
pip install blis spacy

python3 -c "import torch; print(torch.__version__)"
python3 -c "import numpy; print(numpy.__version__)"
python3 -c "import torchdata; print(torchdata.__version__)"

echo "------------------------------------------------------------Cloning text github repo--------------------------------------------------------------"
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

echo "------------------------------------------------------------Installing requirements for vision------------------------------------------------------"
python3 -m spacy download en_core_web_sm

#install
if ! (python3 setup.py install) ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

#run tests
if !(pytest test/torchtext_unittest -k "not test_with_asset and not test_download_glove_vectors and not test_vectors_get_vecs" --disable-warnings); then
    echo "------------------$PACKAGE_NAME:build_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
