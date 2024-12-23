#!/bin/bash -e
set -x
# -----------------------------------------------------------------------------
#
# Package           : vision
# Version           : v0.16.1
# Source repo       : https://github.com/pytorch/vision.git
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

PACKAGE_NAME=vision
PACKAGE_URL=https://github.com/pytorch/vision.git

PACKAGE_VERSION=${1:-v0.16.1}
PYTHON_VERSION=${PYTHON_VERSION:-3.11}

export MAX_JOBS=${MAX_JOBS:-$(nproc)}
export _GLIBCXX_USE_CXX11_ABI=${_GLIBCXX_USE_CXX11_ABI:-1}
export TORCHVISION_USE_NVJPEG=${TORCHVISION_USE_NVJPEG:-0}
export TORCHVISION_USE_FFMPEG=${TORCHVISION_USE_FFMPEG:-0}

WORKDIR=$(pwd)

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

dnf install -y https://mirror.stream.centos.org/9-stream/BaseOS/ppc64le/os/Packages/centos-gpg-keys-9.0-24.el9.noarch.rpm \
            https://mirror.stream.centos.org/9-stream/BaseOS/`arch`/os/Packages/centos-stream-repos-9.0-24.el9.noarch.rpm \
			https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/BaseOS/`arch`/os
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/AppStream/`arch`/os
dnf config-manager --set-enabled crb
dnf install -y git cmake ninja-build gcc-toolset-13 rust cargo jq \
            libjpeg-devel openjpeg2-devel libpng-devel \
            python$PYTHON_VERSION-devel \
            python$PYTHON_VERSION-pip \
            python$PYTHON_VERSION-setuptools \
            python$PYTHON_VERSION-wheel

export PATH=/opt/rh/gcc-toolset-13/root/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/lib:/opt/rh/gcc-toolset-13/root/lib64:/usr/lib:/usr/lib64:$LD_LIBRARY_PATH
export CC=$(command -v gcc)
export CXX=$(command -v g++)

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
##############################################


# Build Dependencies when BUILD_DEPS is unset or set to True
if [ -z $BUILD_DEPS ] || [ $BUILD_DEPS == True ]; then
    # dependencies for numpy
    dnf install -y gfortran openblas-devel lapack-devel pkgconfig

    # dependencies for pillow
    dnf install -y libtiff-devel libjpeg-devel openjpeg2-devel zlib-devel \
        libpng-devel freetype-devel lcms2-devel libwebp-devel tcl-devel tk-devel \
        harfbuzz-devel fribidi-devel libraqm-devel libimagequant-devel libxcb-devel

    # setup
    DEPS_DIR=$WORKDIR/deps_from_src
    rm -rf $DEPS_DIR
    mkdir -p $DEPS_DIR
    cd $DEPS_DIR
    

    # install dependency - pytorch
    PYTORCH_VERSION=${PYTORCH_VERSION:-$(curl -sSL https://api.github.com/repos/pytorch/pytorch/releases/latest | jq -r .tag_name)}

    git clone https://github.com/pytorch/pytorch.git
    cd pytorch
    git checkout tags/$PYTORCH_VERSION

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
    python -m pip install -r requirements.txt
    python setup.py develop

    # cleanup
    rm -rf $DEPS_DIR
fi

cd $WORKDIR

# torchvision build setup
BUILD_ISOLATION=""
# When BUILD_DEPS is unset or set to True
if [ -z $BUILD_DEPS ] || [ $BUILD_DEPS == True ]; then
    BUILD_ISOLATION="--no-build-isolation"
fi

if ! (python -m pip install -v -e . $BUILD_ISOLATION); then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
    exit 1
fi

python -m pip install pytest pytest-xdist
if ! python -m pytest -n auto test/common_extended_utils.py test/common_utils.py test/smoke_test.py test/test_architecture_ops.py test/test_datasets_video_utils_opt.py test/test_tv_tensors.py; then
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
