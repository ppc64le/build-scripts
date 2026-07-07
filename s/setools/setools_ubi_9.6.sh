#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : murmurhash
# Version          : v1.0.15
# Source repo      : https://github.com/explosion/murmurhash
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
PACKAGE_NAME=setools
PACKAGE_VERSION=${1:-4.4.4}
PACKAGE_URL=https://github.com/SELinuxProject/setools.git
PACKAGE_DIR=setools
CURRENT_DIR="${PWD}"

# Install dependencies
yum install -y git gcc gcc-c++ make cmake python3.11 python3.11-devel libselinux-devel libsepol-devel python3-setuptools

# Clone source
git clone $PACKAGE_URL
cd $PACKAGE_DIR

git checkout $PACKAGE_VERSION

# Install Python dependencies
python3.11 -m ensurepip --upgrade || true
python3.11 -m pip install --upgrade pip setuptools wheel cython

python3.11 setup.py build_ext --inplace

# Build and install
if ! python3.11 -m pip install . ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Install_Fails"
    exit 1
fi

cd "$CURRENT_DIR"
# Verify installation
python3.11 -c "from setools import SELinuxPolicy; print('SELinuxPolicy import successful')"


cd "$PACKAGE_DIR"
# Install test dependencies
python3.11 -m pip install pytest networkx

# Run tests
if ! python3.11 -m pytest -v tests ; then
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