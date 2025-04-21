#!/bin/bash -e
#
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
PACKAGE_VERSION=${1:-v0.16.1}
PACKAGE_URL=https://github.com/pytorch/vision.git
OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)
MAX_JOBS=${MAX_JOBS:-$(nproc)}
export _GLIBCXX_USE_CXX11_ABI=${_GLIBCXX_USE_CXX11_ABI:-1}
WORKDIR=$(pwd)


yum install -y git cmake ninja-build g++ rust cargo jq \
            libtiff-devel libjpeg-devel zlib-devel \
            harfbuzz-devel libxcb-devel \
            python-devel python-pip

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
pip install -r requirements.txt
pip install 'cmake==3.31.6'
pip install -v -e . --no-build-isolation
pip install setuptools wheel

cd $WORKDIR

# build torchvision
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

if ! (pip install -v -e . --no-build-isolation); then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
    exit 1
fi

cd $WORKDIR
pip install pytest pytest-xdist

if ! pytest $PACKAGE_NAME/test/common_extended_utils.py $PACKAGE_NAME/test/common_utils.py $PACKAGE_NAME/test/smoke_test.py $PACKAGE_NAME/test/test_architecture_ops.py $PACKAGE_NAME/test/test_datasets_video_utils_opt.py $PACKAGE_NAME/test/test_tv_tensors.py; then
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
