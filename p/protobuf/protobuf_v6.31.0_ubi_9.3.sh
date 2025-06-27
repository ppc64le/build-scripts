#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : protobuf
# Version          : v6.31.0
# Source repo      : https://github.com/protocolbuffers/protobuf
# Tested on        : UBI:9.3
# Language         : Python
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Shivansh Sharma <Shivansh.s1@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -ex

PACKAGE_NAME=protobuf
PACKAGE_VERSION=${1:-v6.31.0}
PACKAGE_URL=https://github.com/protocolbuffers/protobuf
PACKAGE_DIR=$PACKAGE_NAME-${PACKAGE_VERSION#v}
WORK_DIR=$(pwd)

yum install -y make libtool cmake git wget xz zlib-devel openssl-devel bzip2-devel libffi-devel libevent-devel patch python3.12 python3.12-pip python3.12-devel ninja-build gcc-toolset-13

PYTHON_VERSION=$(python --version 2>&1 | cut -d ' ' -f 2 | cut -d '.' -f 1,2)
export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH
python3.12 -m pip install --upgrade cmake pip setuptools wheel ninja packaging tox pytest build

#Download Protobuf tarball from pypi, since source repo does not provide setup.py   
python3.12 -m pip download --no-binary=:all: protobuf==$PACKAGE_VERSION
tar -xvf $PACKAGE_DIR*
cd $PACKAGE_DIR

# Set environment to use upb backend
export PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION=upb

# Build and install in local env (optional)
python3.12 -m pip install .

# Build a wheel using setup.py
python3.12  setup.py bdist_wheel --dist-dir "$WORK_DIR"

# Validate result
echo "Wheel built successfully at:"
ls -lh "$WORK_DIR"/*.whl
