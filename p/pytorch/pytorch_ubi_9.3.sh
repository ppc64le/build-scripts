#!/bin/bash -e

# -----------------------------------------------------------------------------
#
# Package           : pytorch
# Version           : v2.4.0
# Source repo       : https://github.com/pytorch/pytorch.git
# Tested on         : UBI:9.3
# Language          : Python
# Ci-Check      : True
# Script License    : Apache License, Version 2.0
# Maintainer        : Md. Shafi Hussain <Md.Shafi.Hussain@ibm.com>
#
# Disclaimer        : This script has been tested in root mode on given
# ==========          platform using the mentioned version of the package.
#                     It may not work as expected with newer versions of the
#                     package and/or distribution. In such case, please
#                     contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=pytorch
PACKAGE_VERSION=${1:-v2.10.0}
PACKAGE_URL=https://github.com/pytorch/pytorch.git
OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)
PYTHON_VER=${2:-3.9}
export _GLIBCXX_USE_CXX11_ABI=1

dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm \
    git cmake ninja-build g++ rust cargo pkgconf-pkg-config \
    python${PYTHON_VER}-devel python${PYTHON_VER}-wheel python${PYTHON_VER}-pip python${PYTHON_VER}-setuptools

# Ensure pkg-config can find Python (required for NumPy build with Meson)
export PKG_CONFIG_PATH="/usr/lib64/pkgconfig:${PKG_CONFIG_PATH:-}"

if ! command -v python; then
    ln -s $(command -v python${PYTHON_VER}) /usr/bin/python
fi
if ! command -v pip; then
    ln -s $(command -v pip${PYTHON_VER}) /usr/bin/pip
fi

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout tags/$PACKAGE_VERSION

PPC64LE_PATCH="69cbf05"
if ! git log --pretty=format:"%H" | grep -q "$PPC64LE_PATCH"; then
    echo "Applying POWER patch."
    git config user.email "Md.Shafi.Hussain@ibm.com"
    git config user.name "Md. Shafi Hussain"
    git cherry-pick "$PPC64LE_PATCH"
else
    echo "POWER patch not needed."
fi

git submodule sync
git submodule update --init --recursive
pip install -r requirements.txt

# PyTorch build is very memory-hungry (large generated .cpp files); cap parallel jobs
# to avoid OOM killer terminating the compiler. Override with MAX_JOBS=... if you have enough RAM.
MAX_JOBS=${MAX_JOBS:-$(nproc)}
if [ "${MAX_JOBS}" -gt 4 ] 2>/dev/null; then
    MAX_JOBS=4
fi
export MAX_JOBS

if ! (python setup.py bdist_wheel && pip install dist/*.whl); then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
    exit 1
fi

cd ..
pip install pytest

# basic sanity test (subset)
if ! pytest $PACKAGE_NAME/test/test_utils.py; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
