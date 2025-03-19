#!/bin/bash -e

# -----------------------------------------------------------------------------
#
# Package           : sentencepiece
# Version           : v0.2.0
# Source repo       : https://github.com/google/sentencepiece.git
# Tested on         : UBI:9.3
# Language          : Python
# Travis-Check      : True
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

PACKAGE_NAME=sentencepiece
PACKAGE_URL=https://github.com/google/sentencepiece.git

PACKAGE_VERSION=${1:-v0.2.0}
PYTHON_VERSION=${PYTHON_VERSION:-3.11}

WORKDIR=$(pwd)

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)


dnf install -yq git cmake gcc-toolset-13 \
    python$PYTHON_VERSION-devel \
    python$PYTHON_VERSION-pip \
    python$PYTHON_VERSION-wheel \
    python$PYTHON_VERSION-setuptools

source /opt/rh/gcc-toolset-13/enable
ln -s /usr/lib64/libatomic.so.1 /usr/lib64/libatomic.so


if [ -z $PACKAGE_SOURCE_DIR ]; then
    git clone $PACKAGE_URL -b $PACKAGE_VERSION
    cd $PACKAGE_NAME/python
    WORKDIR=$(pwd)
else
    WORKDIR=$PACKAGE_SOURCE_DIR
    cd $WORKDIR/python
    git checkout $PACKAGE_VERSION
fi
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

if ! python -m pip install -v -e . ; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
    exit 1
fi

python -m pip install pytest-xdist
if ! python -m pytest -n auto; then
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
