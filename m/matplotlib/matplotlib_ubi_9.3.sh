#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : matplotlib
# Version       : v3.9.2
# Source repo   : https://github.com/matplotlib/matplotlib.git
# Tested on     : UBI 9.3
# Language      : Python, C++, Jupyter Notebook
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Chandan.Abhyankar@ibm.com
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=matplotlib
PACKAGE_URL=https://github.com/matplotlib/matplotlib.git

PACKAGE_VERSION=${1:-v3.9.2}
PYTHON_VERSION=${PYTHON_VERSION:-3.11}

export MAX_JOBS=${MAX_JOBS:-$(nproc)}

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

dnf install -y git gcc-toolset-13 ninja-build pybind11-devel \
    python$PYTHON_VERSION-devel \
    python$PYTHON_VERSION-pip \
    python$PYTHON_VERSION-setuptools \
    python$PYTHON_VERSION-wheel

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
python -m pip install meson-python pybind11 setuptools-scm patchelf pybind11
##############################################

# Build Dependencies when BUILD_DEPS is unset or set to True
if [ -z $BUILD_DEPS ] || [ $BUILD_DEPS == True ]; then
    dnf install -y https://mirror.stream.centos.org/9-stream/BaseOS/ppc64le/os/Packages/centos-gpg-keys-9.0-24.el9.noarch.rpm \
        https://mirror.stream.centos.org/9-stream/BaseOS/`arch`/os/Packages/centos-stream-repos-9.0-24.el9.noarch.rpm \
        https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
    dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/BaseOS/`arch`/os
    dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/AppStream/`arch`/os
    dnf config-manager --set-enabled crb
    
    # dependencies for pillow
    dnf install -y libtiff-devel libjpeg-devel openjpeg2-devel zlib-devel \
        freetype-devel lcms2-devel libwebp-devel tcl-devel tk-devel \
        harfbuzz-devel fribidi-devel libraqm-devel libimagequant libimagequant-devel libxcb-devel

    python -m pip install numpy
fi

cd $WORKDIR

# build setup
BUILD_ISOLATION=""
# When BUILD_DEPS is unset or set to True
if [ -z $BUILD_DEPS ] || [ $BUILD_DEPS == True ]; then
    BUILD_ISOLATION="--no-build-isolation"
fi

if ! python -m pip install -vvv . $BUILD_ISOLATION; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
    exit 1
fi

if ! python -c "import matplotlib; print(matplotlib.__file__)"; then
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
