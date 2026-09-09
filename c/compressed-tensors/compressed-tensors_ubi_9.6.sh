#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : compressed-tensors
# Version          : 0.17.0
# Source repo      : https://github.com/vllm-project/compressed-tensors.git
# Tested on     : UBI:9.6
# Language      : Python
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Bhagyashri Gaikwad <Bhagyashri.Gaikwad2@ibm.com> 
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash
set -ex

# Variables
PACKAGE_NAME=compressed-tensors
PACKAGE_VERSION=${1:-0.17.0}
PACKAGE_URL=https://github.com/vllm-project/compressed-tensors.git
PACKAGE_DIR=compressed-tensors
CURRENT_DIR="${PWD}"

# Install dependencies
yum install -y git gcc-toolset-13-gcc gcc-toolset-13-gcc-c++ gcc-toolset-13-gcc-gfortran \
    cmake make wget openssl-devel bzip2-devel glibc-static libstdc++-static libffi-devel \
    zlib-devel python3.11 python3.11-pip python3.11-devel pkg-config

# Enable GCC Toolset
source /opt/rh/gcc-toolset-13/enable

export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH

# Set Python 3.11 as default
ln -sf /usr/bin/python3.11 /usr/bin/python3
ln -sf /usr/bin/pip3.11 /usr/bin/pip
ln -sf /usr/bin/pip3.11 /usr/bin/pip3

python3 --version
pip --version
gcc --version

# Clone the repository
git clone $PACKAGE_URL
cd $PACKAGE_DIR
git checkout $PACKAGE_VERSION

# Upgrade packaging tools
python3 -m pip install --upgrade pip setuptools wheel build

# Install Python dependencies
pip install \
    pytest \
    pytest-cov \
    pytest-xdist \
    pytest-asyncio \
    pytest-timeout \
    packaging \
    numpy

# Install compressed-tensors
if ! pip install -e . ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Install_Fails"
    exit 1
fi

# Verify installation
if ! python3 -c "import compressed_tensors; print(compressed_tensors.__version__)" ; then
    echo "------------------$PACKAGE_NAME:Import_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Import_Fails"
    exit 1
fi

# Run tests
if ! pytest -v --timeout=60 --capture=no -p no:warnings ; then
    echo "------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Pass | Both_Install_and_Test_Success"
fi
