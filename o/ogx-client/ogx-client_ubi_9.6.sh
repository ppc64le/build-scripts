#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : ogx
# Version          : v1.1.3
# Source repo      : https://github.com/ogx-ai/ogx.git
# Tested on        : UBI:9.6
# Language         : Python
# Ci-Check         : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Bhagyashri Gaikwad <Bhagyashri.Gaikwad2@ibm.com> 
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash
set -e

# Variables
PACKAGE_NAME=ogx
PACKAGE_VERSION=${1:-v1.1.3}
PACKAGE_URL=https://github.com/ogx-ai/ogx.git
PACKAGE_DIR=ogx
CURRENT_DIR="${PWD}"

# Install dependencies
yum install -y git gcc gcc-c++ make python3.12 python3.12-devel

yum install -y rust cargo

# Clone source
git clone "$PACKAGE_URL"
cd "$PACKAGE_DIR"

# Checkout requested version
git checkout "v$PACKAGE_VERSION"

# Install Python build dependencies
python3.12 -m ensurepip --upgrade || true
python3.12 -m pip install --upgrade pip setuptools wheel

# Install pre-built IBM ppc64le wheels
IBM_WHEELS="https://wheels.developerfirst.ibm.com/ppc64le/linux/+simple/"

python3.12 -m pip install \
  --trusted-host wheels.developerfirst.ibm.com \
  --extra-index-url "${IBM_WHEELS}" \
  grpcio==1.80.0

# Verify grpcio installation
python3.12 -c "import grpc; print('grpcio version:', grpc.__version__)"

# Build and install
if ! python3.12 -m pip install . ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Install_Fails"
    exit 1
fi

cd "$CURRENT_DIR"

# Verify installation
if ! python3.12 -c "import ogx; print('ogx import successful')" ; then
    echo "------------------$PACKAGE_NAME:Import_fails----------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Import_Fails"
    exit 1
fi

cd "$PACKAGE_DIR"

# Install test dependencies
python3.12 -m pip install pytest

# Run tests
if ! python3.12 -m pytest -v tests ; then
    echo "------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Pass | Both_Install_and_Test_Success"
    exit 0
fi
