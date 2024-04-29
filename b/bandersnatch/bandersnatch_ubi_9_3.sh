#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : bandersnatch
# Version       : 6.5.0
# Source repo   : https://github.com/pypa/bandersnatch
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
# ----------------------------------------------------------------------------

set -e

# Variables
export PACKAGE_VERSION=${1:-"6.5.0"}
export PACKAGE_NAME=bandersnatch
export PACKAGE_URL=https://github.com/pypa/bandersnatch


# Install dependencies
yum install -y git wget sqlite sqlite-devel libxml2-devel libxslt-devel gcc gcc-c++ make cmake

#installation of rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
export PATH="$HOME/.cargo/bin:$PATH"
source ~/.bashrc
rustc --version

#installation of python3.10
yum install -y gcc openssl-devel bzip2-devel libffi-devel wget xz zlib-devel
wget https://www.python.org/ftp/python/3.10.0/Python-3.10.0.tar.xz
tar xf Python-3.10.0.tar.xz
cd Python-3.10.0
./configure --prefix=/usr/local --enable-optimizations
make -j4
make install
python3.10 --version
cd ..

python3 -m pip install --upgrade pip setuptools tox
pip3 install boto3 s3path freezegun keystoneauth1 python-swiftclient
export TOXENV=py310

# Clone the repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
pip3 install -r requirements.txt
pip3 install -r requirements_s3.txt


# Build package
if !(python3 setup.py install) ; then
    echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_Fails"
    exit 1
fi

# Run test cases
# Skipping "test_storage_plugin_s3.py" test as it requires to set up minio/minio server. For more information refer Readme.md
if !(tox -e py310 -- -k "not src/bandersnatch/tests/plugins/test_storage_plugin_s3.py"); then
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
