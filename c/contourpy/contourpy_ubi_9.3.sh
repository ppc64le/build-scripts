#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : contourpy
# Version          : v1.0.5
# Source repo      : https://github.com/contourpy/contourpy
# Tested on	       : UBI:9.3
# Language         : Python
# Ci-Check         : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : ICH <ich@us.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=contourpy
PACKAGE_VERSION=${1:-v1.0.5}
PACKAGE_URL=https://github.com/contourpy/contourpy
PACKAGE_DIR="$(pwd)/$PACKAGE_NAME"

yum install -y git python3 python3-devel python3-pip gcc gcc-c++ make wget sudo cmake
yum install -y zlib libjpeg-turbo openssl-devel zlib-devel libjpeg-turbo-devel libjpeg-devel libpng-devel

PATH=$PATH:/usr/local/bin/
export CC=/usr/bin/gcc
export CXX=/usr/bin/g++

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)
SOURCE=Github

# Install rust
if ! command -v rustc &> /dev/null
then
    wget https://static.rust-lang.org/dist/rust-1.75.0-powerpc64le-unknown-linux-gnu.tar.gz
    tar -xzf rust-1.75.0-powerpc64le-unknown-linux-gnu.tar.gz
    cd rust-1.75.0-powerpc64le-unknown-linux-gnu
    sudo ./install.sh
    export PATH=$HOME/.cargo/bin:$PATH
    rustc -V
    cargo -V
    cd ../
fi

#Clone the repo
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

pip3 install pytest tox nox
pip3 install numpy pillow kiwisolver matplotlib

# Install via pip3
if !  python3 -m pip install .; then
        echo "------------------$PACKAGE_NAME:install_fails------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail | Install_Failed"  
        exit 1
fi

# Run Pytest
pytest -k "not test_filled.py and not test_lines.py"
if [ $? -eq 0 ]; then
    echo "------------------$PACKAGE_NAME:install_and_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Pass | Both_Install_and_Test_Success"
    exit 0
else
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail | Install_success_but_test_Fails"
    exit 2
fi
