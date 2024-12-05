#!/bin/bash -e

# -----------------------------------------------------------------------------
#
# Package           : cryptography
# Version           : 38.0.1
# Source repo       : https://github.com/pyca/cryptography.git
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

PACKAGE_NAME=cryptography
PACKAGE_URL=https://github.com/pyca/cryptography.git

PACKAGE_VERSION=${1:-38.0.1}
PYTHON_VERSION=${PYTHON_VERSION:-3.11}

WORKDIR=$(pwd)

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)


dnf install -yq https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm \
    git redhat-rpm-config gcc libffi-devel openssl-devel cargo pkg-config \
    python$PYTHON_VERSION-devel \
    python$PYTHON_VERSION-pip \
    python$PYTHON_VERSION-wheel \
    python$PYTHON_VERSION-setuptools

if [ -z $PACKAGE_SOURCE_DIR ]; then
    git clone $PACKAGE_URL -b $PACKAGE_VERSION
    cd $PACKAGE_NAME
    WORKDIR=$(pwd)
else
    WORKDIR=$PACKAGE_SOURCE_DIR
    cd $WORKDIR
    git checkout $PACKAGE_VERSION
fi

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
python -m pip install -q setuptools wheel build
##############################################

python -m pip install -q setuptools_rust 
if ! python -m pip install -v -e . ; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
    exit 1
fi

# Build wheel
python -m build --wheel

# cleanup
rm -rf build

python -m pip install -r dev-requirements.txt
# basic sanity test (subset)
if ! python -m pytest -n auto tests/conftest.py tests/test_cryptography_utils.py tests/test_rust_utils.py tests/test_fernet.py tests/test_warnings.py tests/hypothesis/ tests/bench/ tests/doubles.py; then
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
