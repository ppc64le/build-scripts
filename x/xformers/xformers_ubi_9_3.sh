#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : xformers
# Version       : 0.0.28
# Source repo   : https://github.com/facebookresearch/xformers.git
# Tested on     : UBI 9.3
# Language      : Python, C++
# Travis-Check  : True
# Script License: Apache License, Version 2.0
# Maintainer    : Puneet Sharma <Puneet.Sharma21@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=xformers
PACKAGE_VERSION=${1:-v0.0.28}
PACKAGE_URL=https://github.com/facebookresearch/xformers.git

# Install dependencies
yum install -y python3.11 python3.11-pip python3.11-devel gcc gcc-c++ git jq

# Clone repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
git submodule update --init

# Install Python dependencies
python3.11 -m pip install ninja cmake 'pytest==8.2.2'

# install dependency - pytorch

PYTORCH_VERSION=${PYTORCH_VERSION:-$(curl -sSL https://api.github.com/repos/pytorch/pytorch/releases/latest | jq -r .tag_name)}
 
git clone https://github.com/pytorch/pytorch.git

cd pytorch

git checkout tags/$PYTORCH_VERSION
 
PPC64LE_PATCH="69cbf05"

if ! git log --pretty=format:"%H" | grep -q "$PPC64LE_PATCH"; then

    echo "Applying POWER patch."

    git config user.email "Puneet.Sharma21@ibm.com"

    git config user.name "puneetsharma21"

    git cherry-pick "$PPC64LE_PATCH"

else

    echo "POWER patch not needed."

fi
 
git submodule sync

git submodule update --init --recursive

pip3.11 install -r requirements.txt

MAX_JOBS=$PARALLEL python3.11 setup.py install
 


# Build and install xformers
if ! python3.11 -m pip install -e .; then
    echo "------------------$PACKAGE_NAME:build_fails---------------------"
    exit 1
else
    echo "------------------$PACKAGE_NAME:build_success-------------------------"
fi

# Test installation
if python3.11 -c "import xformers"; then
    echo "------------------$PACKAGE_NAME::Install_Success---------------------"
else
    echo "------------------$PACKAGE_NAME::Install_Fail-------------------------"
    exit 2
fi

# Run tests
export PY_IGNORE_IMPORTMISMATCH=1
if ! pytest tests; then
    echo "------------------$PACKAGE_NAME:test_fails---------------------"
    exit 2
else
    echo "------------------$PACKAGE_NAME:test_success-------------------------"
    exit 0
fi

