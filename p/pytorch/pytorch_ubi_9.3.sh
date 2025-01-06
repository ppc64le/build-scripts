#!/bin/bash -e

# -----------------------------------------------------------------------------
#
# Package           : pytorch
# Version           : v2.4.0
# Source repo       : https://github.com/pytorch/pytorch.git
# Tested on         : UBI:9.3
# Language          : Python
# Travis-Check      : False
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
PACKAGE_URL=https://github.com/pytorch/pytorch.git

PACKAGE_VERSION=${1:-v2.4.0}
PYTHON_VERSION=${PYTHON_VERSION:-3.11}

export MAX_JOBS=${MAX_JOBS:-$(nproc)}
export _GLIBCXX_USE_CXX11_ABI=${_GLIBCXX_USE_CXX11_ABI:-1}
export USE_CUDA=${USE_CUDA:-0}
export BLAS=${BLAS:-OpenBLAS}

WORKDIR=$(pwd)

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)


dnf install -y https://mirror.stream.centos.org/9-stream/BaseOS/ppc64le/os/Packages/centos-gpg-keys-9.0-24.el9.noarch.rpm \
    https://mirror.stream.centos.org/9-stream/BaseOS/`arch`/os/Packages/centos-stream-repos-9.0-24.el9.noarch.rpm \
    https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/AppStream/`arch`/os
dnf config-manager --set-enabled crb

dnf install -y git cmake ninja-build gcc-toolset-13 rust cargo \
    openblas-devel lapack-devel pkgconfig \
    python$PYTHON_VERSION-devel \
    python$PYTHON_VERSION-wheel \
    python$PYTHON_VERSION-pip \
    python$PYTHON_VERSION-setuptools

source /opt/rh/gcc-toolset-13/enable

if [ -z $PACKAGE_SOURCE_DIR ]; then
    git clone $PACKAGE_URL -b $PACKAGE_VERSION
    cd $PACKAGE_NAME
    WORKDIR=$(pwd)
else
    WORKDIR=$PACKAGE_SOURCE_DIR
    cd $WORKDIR
    git checkout $PACKAGE_VERSION
fi

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

# no venv - helps with meson build conflicts #
rm -rf $WORKDIR/PY_PRIORITY
mkdir $WORKDIR/PY_PRIORITY
PATH=$WORKDIR/PY_PRIORITY:$PATH
ln -sf $(command -v python$PYTHON_VERSION) $WORKDIR/PY_PRIORITY/python
ln -sf $(command -v python$PYTHON_VERSION) $WORKDIR/PY_PRIORITY/python3
ln -sf $(command -v python$PYTHON_VERSION) $WORKDIR/PY_PRIORITY/python$PYTHON_VERSION
ln -sf $(command -v pip$PYTHON_VERSION) $WORKDIR/PY_PRIORITY/pip
ln -sf $(command -v pip$PYTHON_VERSION) $WORKDIR/PY_PRIORITY/pip3
ln -sf $(command -v pip$PYTHON_VERSION) $WORKDIR/PY_PRIORITY/pip$PYTHON_VERSION
##############################################

python -m pip install -r requirements.txt
if ! python setup.py develop; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
    exit 1
fi

python -m pip install pytest-xdist

# basic sanity test (subset)
if ! python -m pytest -n auto test/test_utils.py; then
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
