#!/bin/bash -e
 
# -----------------------------------------------------------------------------
#
# Package : pytorch
# Version : v2.5.1
# Source repo : https://github.com/pytorch/pytorch.git
# Tested on : UBI:9.3
# Language : Python
# Travis-Check : True
# Script License: Apache License, Version 2 or later
# Maintainer : Shubham Garud
#
# Disclaimer: This script has been tested in root mode on the given
# platform using the mentioned version of the package.
# It may not work as expected with newer versions of the
# package and/or distribution. In such a case, please
# contact the "Maintainer" of this script.
#
# -----------------------------------------------------------------------------
 
# Exit immediately if a command exits with a non-zero status
set -e
PACKAGE_NAME=pytorch
PACKAGE_URL=https://github.com/pytorch/pytorch.git
PACKAGE_VERSION=${1:-v2.5.1}
PACKAGE_DIR=$PACKAGE_NAME

yum install -y git wget
yum install -y gcc-toolset-13
export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
gcc --version

yum install -y python3.12 python3.12-devel python3.12-pip
ln -sf /usr/bin/python3.12 /usr/bin/python3

yum install -y openblas-devel cmake gcc-gfortran

dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/AppStream/ppc64le/os/
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/BaseOS/ppc64le/os/
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/CRB/ppc64le/os/

wget http://mirror.centos.org/centos/RPM-GPG-KEY-CentOS-Official
mv RPM-GPG-KEY-CentOS-Official /etc/pki/rpm-gpg/.
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-Official

dnf install --nodocs -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm

yum install -y abseil-cpp abseil-cpp-devel
yum install -y protobuf-c protobuf protobuf-devel.ppc64le
python3 -m pip install wheel scipy ninja build pytest
python3 -m pip install numpy==2.2.2

curl https://sh.rustup.rs -sSf | sh -s -- -y
source "$HOME/.cargo/env"

BUILD_NUM="1"
export SITE_PACKAGE_PATH=/usr/local/lib/python3.12/site-packages
export OpenBLAS_HOME="/usr/include/openblas"
export ppc_arch="p9"
export build_type="cpu"
export cpu_opt_arch="power8"
export cpu_opt_tune="power9"
export CPU_COUNT=$(nproc --all)
export CXXFLAGS="${CXXFLAGS} -D__STDC_FORMAT_MACROS"
export LDFLAGS="$(echo ${LDFLAGS} | sed -e 's/-Wl\,--as-needed//')"
export LDFLAGS="${LDFLAGS} -Wl,-rpath-link,${VIRTUAL_ENV}/lib"
export CXXFLAGS="${CXXFLAGS} -fplt"
export CFLAGS="${CFLAGS} -fplt"
export BLAS=OpenBLAS
export USE_FBGEMM=0
export USE_SYSTEM_NCCL=1
export USE_MKLDNN=0
export USE_NNPACK=0
export USE_QNNPACK=0
export USE_XNNPACK=0
export USE_PYTORCH_QNNPACK=0
export TH_BINARY_BUILD=1
export USE_LMDB=1
export USE_LEVELDB=1
export USE_NINJA=0
export USE_MPI=0
export USE_OPENMP=1
export USE_TBB=0
export BUILD_CUSTOM_PROTOBUF=OFF
export BUILD_CAFFE2=1
export PYTORCH_BUILD_VERSION=${PACKAGE_VERSION}
export PYTORCH_BUILD_NUMBER=${BUILD_NUM}
export USE_CUDA=0
export USE_CUDNN=0
export USE_TENSORRT=0

ARCH=`uname -p`

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
git submodule sync
git submodule update --init --recursive


if ! (python3 -m pip install -r requirements.txt);then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

if ! (MAX_JOBS=$(nproc) python3 setup.py install);then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

cd ..

if ! (pytest pytorch/test/test_utils.py -k "not test_device_mode_ops_sparse_mm_reduce_cpu_bfloat16 and not test_device_mode_ops_sparse_mm_reduce_cpu_float16  and not test_device_mode_ops_sparse_mm_reduce_cpu_float32 and not test_device_mode_ops_sparse_mm_reduce_cpu_float64"); then
    echo "--------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
