#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : scikit-image
# Version       : v0.26.0
# Source repo   : https://github.com/scikit-image/scikit-image
# Tested on     : UBI:9.3
# Language      : Python
# Ci-Check  : False
# Script License: Apache License 2.0
# Maintainer    : Shivansh Sharma  <shivansh.s11@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=scikit-image
PACKAGE_VERSION=${1:-v0.26.0}
PACKAGE_URL=https://github.com/scikit-image/scikit-image
CURRENT_DIR="${PWD}"

yum install -y gcc gcc-c++ make python python-devel libtool sqlite-devel ninja-build cmake git wget xz zlib-devel openssl-devel bzip2-devel libffi-devel libevent-devel libjpeg-turbo-devel gcc-gfortran openblas openblas-devel libgomp

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)


#install rust
curl https://sh.rustup.rs -sSf | sh -s -- -y
source "$HOME/.cargo/env"  # Update environment variables to use Rust


#installing patchelf from source
cd $CURRENT_DIR
yum install -y git autoconf automake libtool make
git clone https://github.com/NixOS/patchelf.git
cd patchelf
./bootstrap.sh
./configure
make
make install
ln -s /usr/local/bin/patchelf /usr/bin/patchelf
cd $CURRENT_DIR
echo "-----------------------------------------------------Installed patchelf-----------------------------------------------------"



# clone source repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

python3 -m pip install -r requirements.txt
python3  -m pip install -r requirements/build.txt
python3 -m pip install --upgrade pip

# build the project with pip and install
if ! python3 -m pip install . ; then
        echo "------------------$PACKAGE_NAME:build_fails---------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
        exit 1
else
        echo "------------------$PACKAGE_NAME:build_success-------------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Build_Success"
		exit 0
fi

#skippping tests as tests are parity with intel
