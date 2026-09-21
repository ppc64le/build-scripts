#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : libclang
# Version          : llvm-18.1.1
# Source repo      : https://github.com/sighingnow/libclang.git
# Tested on        : UBI:10.2
# Language         : Python
# Ci-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Tejas Badjate <tejasBadjateIBM@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------------

# Variables
PACKAGE_NAME=libclang
PACKAGE_VERSION=${1:-llvm-18.1.1}
PACKAGE_URL=https://github.com/sighingnow/libclang.git
PACKAGE_DIR=libclang
CURRENT_DIR="${PWD}"

# Install necessary system dependencies
yum install -y git make wget llvm-devel clang-devel openssl-devel bzip2-devel libffi-devel zlib-devel python3.14-devel python3.14-pip cmake clang

yum install gcc-toolset-15 gcc-toolset-15-gcc gcc-toolset-15-gcc-c++ gcc-toolset-15-gcc-gfortran -y

# ---------------------------------------------------------------------------
# Activate GCC Toolset 15 (SCL removed in UBI 10 — use PATH export)
# ---------------------------------------------------------------------------
if [[ -f /opt/rh/gcc-toolset-15/enable ]]; then
    source /opt/rh/gcc-toolset-15/enable
elif [[ -d /opt/rh/gcc-toolset-15/root/usr/bin ]]; then
    export PATH="/opt/rh/gcc-toolset-15/root/usr/bin:$PATH"
    export LD_LIBRARY_PATH="/opt/rh/gcc-toolset-15/root/usr/lib64:$LD_LIBRARY_PATH"
else
    echo "ERROR: gcc-toolset-15 not found"
    exit 1
fi

export PATH="/opt/rh/gcc-toolset-15/root/usr/bin:$PATH"
export LD_LIBRARY_PATH="/opt/rh/gcc-toolset-15/root/usr/lib64:${LD_LIBRARY_PATH:-}"

export CC="/opt/rh/gcc-toolset-15/root/usr/bin/gcc"
export CXX="/opt/rh/gcc-toolset-15/root/usr/bin/g++"

# Clone the repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

# Check if Rust is installed
if ! command -v rustc &> /dev/null; then
    echo "Rust not found. Installing Rust..."
    curl https://sh.rustup.rs -sSf | sh -s -- -y
    source "$HOME/.cargo/env"
else
    echo "Rust is already installed."
fi

# Install additional Python dependencies
python3.14 -m pip install pytest setuptools tox wheel

# Install the package
if ! python3.14 -m pip install . ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# Building wheel with script itself as the wheel need to create with ppc64le arch.
if ! python3.14  setup.py bdist_wheel --plat-name manylinux2014_ppc64le --dist-dir="$CURRENT_DIR"; then
    echo "------------------$PACKAGE_NAME: Wheel Build Failed ---------------------"
    exit 2
else
    echo "------------------$PACKAGE_NAME: Wheel Build Success -------------------------"
    exit 0
fi

# No tests to run for this package