#!/bin/bash -e

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
PYTHON_VER=${2:-3.9}

WORKDIR=$(pwd)

dnf install -y git jq

# install dependency - pytorch
PYTORCH_VERSION=${3:-$(curl -sSL https://api.github.com/repos/pytorch/pytorch/releases/latest | jq -r .tag_name)}
curl -sL https://raw.githubusercontent.com/ppc64le/build-scripts/master/p/pytorch/pytorch_ubi_9.3.sh | bash -s $PYTORCH_VERSION $PYTHON_VER

cd $WORKDIR

# install additional dependencies for pillow
dnf install -y https://mirror.stream.centos.org/9-stream/BaseOS/ppc64le/os/Packages/centos-gpg-keys-9.0-24.el9.noarch.rpm \
            https://mirror.stream.centos.org/9-stream/BaseOS/`arch`/os/Packages/centos-stream-repos-9.0-24.el9.noarch.rpm \
			https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/AppStream/`arch`/os
dnf config-manager --set-enabled crb
dnf install -y libtiff-devel libjpeg-devel openjpeg2-devel zlib-devel \
    libpng-devel freetype-devel lcms2-devel libwebp-devel tcl-devel tk-devel \
    harfbuzz-devel fribidi-devel libraqm-devel libimagequant-devel libxcb-devel
# install dependency - pillow
PILLOW_VERSION=${4:-$(curl -sSL https://api.github.com/repos/python-pillow/Pillow/releases/latest | jq -r .tag_name)}
curl -sL https://raw.githubusercontent.com/ppc64le/build-scripts/master/p/pillow/pillow_v11.0.0_ubi_9.3.sh | bash -s $PILLOW_VERSION $PYTHON_VER

cd $WORKDIR

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

if ! (MAX_JOBS=$(nproc) python setup.py bdist_wheel && pip install dist/*.whl); then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
    exit 1
fi

# register PrivateUse1HooksInterface
set -x
python test/test_utils.py TestDeviceUtilsCPU.test_device_mode_ops_sparse_mm_reduce_cpu_bfloat16
python test/test_utils.py TestDeviceUtilsCPU.test_device_mode_ops_sparse_mm_reduce_cpu_float16
python test/test_utils.py TestDeviceUtilsCPU.test_device_mode_ops_sparse_mm_reduce_cpu_float32
python test/test_utils.py TestDeviceUtilsCPU.test_device_mode_ops_sparse_mm_reduce_cpu_float64
set +x

cd $WORKDIR
pip install pytest pytest-xdist

if ! pytest -n $(nproc) $PACKAGE_NAME/test/common_extended_utils.py $PACKAGE_NAME/test/common_utils.py $PACKAGE_NAME/test/smoke_test.py $PACKAGE_NAME/test/test_architecture_ops.py $PACKAGE_NAME/test/test_datasets_video_utils_opt.py $PACKAGE_NAME/test/test_tv_tensors.py; then
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
