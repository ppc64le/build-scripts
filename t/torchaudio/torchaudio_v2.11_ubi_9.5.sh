#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : torchaudio
# Version          : v2.11.0
# Source repo      : https://github.com/pytorch/audio.git
# Tested on        : UBI:9.5
# Language         : Python
# Ci-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Lenzie Camilo <Lenzie.Camilo3@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------------

set -ex

# Variables
PACKAGE_NAME=audio
PACKAGE_URL=https://github.com/pytorch/audio.git
PACKAGE_VERSION=${1:-v2.11.0}
PACKAGE_DIR=./audio
SCRIPT_DIR=$(pwd)

yum install -y git make wget python3.12 python3.12-devel python3.12-pip pkgconfig atlas
yum install gcc-toolset-13 -y
echo "Installed gcc-toolset"
yum install -y make libtool  xz zlib-devel bzip2-devel libffi-devel libevent-devel  patch ninja-build pkg-config
dnf install -y gcc-toolset-13-libatomic-devel
dnf install -y --nobest --skip-broken openssl-devel
echo "Installed required deps from RH"

export BUILD_VERSION=${PACKAGE_VERSION#v}
export MAX_JOBS=$(nproc)
export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH

echo "Installing cmake..."
wget https://cmake.org/files/v3.31/cmake-3.31.6.tar.gz
tar -zxvf cmake-3.31.6.tar.gz
cd cmake-3.31.6
./bootstrap
echo "Building Cmake"
make
echo "Installing Cmake"
make install
cd $SCRIPT_DIR

echo "---------------------openblas installing---------------------"

#install openblas
#clone and install openblas from source

git clone https://github.com/OpenMathLib/OpenBLAS
cd OpenBLAS
git checkout v0.3.32
make -j${MAX_JOBS} TARGET=POWER9 BUILD_BFLOAT16=1 BINARY=64 USE_OPENMP=1 USE_THREAD=1 NUM_THREADS=120 DYNAMIC_ARCH=1 INTERFACE64=0
make install PREFIX=/usr/local
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib64:/usr/local/lib
cd $SCRIPT_DIR
echo "--------------------openblas installed-------------------------------"

#Building scipy
python3.12 -m pip install beniget==0.4.2.post1  Cython==3.0.11 gast==0.6.0 meson==1.6.0 meson-python==0.17.1 numpy==2.0.2 packaging pybind11 pyproject-metadata
echo "Installed required deps from pypi"
python3.12 -m pip install pythran==0.17.0 setuptools==75.3.0 pooch pytest build wheel hypothesis ninja patchelf>=0.11.0
# echo "Installed required deps from pypi"
echo "-------------------- Installing Python dependencies ----------------"

IBM_WHEELS="https://wheels.developerfirst.ibm.com/ppc64le/linux/+simple/"

python3.12 -m pip install \
  --prefer-binary \
  --trusted-host wheels.developerfirst.ibm.com \
  --extra-index-url ${IBM_WHEELS} \
  scipy==1.15.2 abseil-cpp==20240116.2 libprotobuf==4.25.8 protobuf==4.25.8
cd $SCRIPT_DIR
echo "--------------------scipy installed-------------------------------"
cd $SCRIPT_DIR

echo "------------ libprotobuf,protobuf installed--------------"

echo "----Installing rust------"
dnf install -y rust cargo

echo "------------cloning pytorch----------------"
git clone https://github.com/pytorch/pytorch.git
cd pytorch
git checkout $PACKAGE_VERSION
git submodule sync
git submodule update --init --recursive
export LIBPROTO_INSTALL=${SCRIPT_DIR}/pytorch/build

ARCH=`uname -p`
BUILD_NUM="1"
export OPENBLAS_INCLUDE=/OpenBLAS/local/openblas/include/
export OpenBLAS_HOME="/usr/include/openblas"
export build_type="cpu"
export cpu_opt_arch="power9"
export cpu_opt_tune="power10"
export CPU_COUNT=$(nproc --all)
export CXXFLAGS="${CXXFLAGS} -D__STDC_FORMAT_MACROS"
export LDFLAGS="$(echo ${LDFLAGS} | sed -e 's/-Wl\,--as-needed//')"
export LDFLAGS="${LDFLAGS} -Wl,-rpath-link,${LIBPROTO_INSTALL}/lib64 -Wl,-rpath-link,${OpenBLASInstallPATH}/lib"
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
export PYTORCH_BUILD_VERSION=${PACKAGE_VERSION#v}
export PYTORCH_BUILD_NUMBER=${BUILD_NUM}
export USE_CUDA=0
export USE_CUDNN=0
export USE_TENSORRT=0
export Protobuf_INCLUDE_DIR=${LIBPROTO_INSTALL}/include
export Protobuf_LIBRARIES=${LIBPROTO_INSTALL}/lib64
export Protobuf_LIBRARY=${LIBPROTO_INSTALL}/lib64/libprotobuf.so
export Protobuf_LITE_LIBRARY=${LIBPROTO_INSTALL}/lib64/libprotobuf-lite.so
export Protobuf_PROTOC_EXECUTABLE=${LIBPROTO_INSTALL}/bin/protoc
export PATH="/protobuf/local/libprotobuf/bin/protoc:${PATH}"
export LD_LIBRARY_PATH="/protobuf/local/libprotobuf/lib64:${LD_LIBRARY_PATH}"
export LD_LIBRARY_PATH="/protobuf/third_party/abseil-cpp/local/abseilcpp/lib:${LD_LIBRARY_PATH}"
export CXXFLAGS="${CXXFLAGS} -mcpu=${cpu_opt_arch} -mtune=${cpu_opt_tune}"
export CFLAGS="${CFLAGS} -mcpu=${cpu_opt_arch} -mtune=${cpu_opt_tune}"

echo "required env variables got set"
sed -i "s/cmake/cmake==3.*/g" requirements.txt
python3.12 -m pip install -r requirements.txt
echo "Installed requirement files from source"

echo "Installing pytorch...."
if ! (MAX_JOBS=${MAX_JOBS} python3.12 setup.py install);then
   echo "------------------pytorch:Install_fails-------------------------------------"
   echo "https://github.com/pytorch/pytorch.git pytorch"
   echo "pytorch  |  https://github.com/pytorch/pytorch.git  | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
   exit 1
fi

#basic import test
echo " Basic Import test for torch"
cd ..
export LD_LIBRARY_PATH="/OpenBLAS/:${LD_LIBRARY_PATH}"
export LD_LIBRARY_PATH=/lib:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH="${SCRIPT_DIR}/pytorch/torch/lib64:${SCRIPT_DIR}/pytorch/build/lib:/usr/local/lib:${LD_LIBRARY_PATH}"

if ! (python3.12 -c "import torch;"); then
     echo "--------------------pytorch:Install_success_but_test_fails---------------------"
     echo "https://github.com/pytorch/pytorch.git pytorch"
     echo "pytorch  |  https://github.com/pytorch/pytorch.git  | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but__Import_Fails"
     exit 2
fi
cd $SCRIPT_DIR

echo "------------------------clone and build torchaudio-------------------"
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/t/torchaudio/0001-Excluded-source-that-has-commercial-license-new.patch
# Below patch excludes the source files that has commercial license
git apply 0001-Excluded-source-that-has-commercial-license-new.patch
echo "-----------------------Applied patch successfully---------------------------------------"

SRC_DIR=$(pwd)

export USE_FFMPEG=OFF
export BUILD_SOX=OFF
export USE_OPENMP=OFF
export BUILD_TORCHAUDIO_PYTHON_EXTENSION=ON
# Use the protobuf built by PyTorch
export Protobuf_DIR=${SCRIPT_DIR}/pytorch/build/third_party/protobuf/cmake/lib64/cmake/protobuf

export Protobuf_INCLUDE_DIR=${SCRIPT_DIR}/pytorch/third_party/protobuf/src
export Protobuf_LIBRARIES=${SCRIPT_DIR}/pytorch/build/lib
export Protobuf_LIBRARY=${SCRIPT_DIR}/pytorch/build/lib/libprotobuf.so
export Protobuf_LITE_LIBRARY=${SCRIPT_DIR}/pytorch/build/lib/libprotobuf-lite.so
export Protobuf_PROTOC_EXECUTABLE=${SCRIPT_DIR}/pytorch/build/bin/protoc

export CMAKE_PREFIX_PATH="${SCRIPT_DIR}/pytorch/build/third_party/protobuf/cmake:/usr/local/lib64/python3.12/site-packages/torch/share/cmake:${CMAKE_PREFIX_PATH}"
export CMAKE_ARGS="-DProtobuf_DIR=${Protobuf_DIR}"

export PATH="${SCRIPT_DIR}/pytorch/build/bin:${PATH}"

export LD_LIBRARY_PATH="${SCRIPT_DIR}/pytorch/build/lib:${SCRIPT_DIR}/pytorch/torch/lib64:/usr/local/lib64:/usr/local/lib:${LD_LIBRARY_PATH}"

PY_VER=$(python3.12 -c 'import sys; print(f"{sys.version_info.major}{sys.version_info.minor}")')
export LD_LIBRARY_PATH="${SCRIPT_DIR}/audio/build/lib.linux-ppc64le-cpython-${PY_VER}/torchaudio/lib:$LD_LIBRARY_PATH"

echo "LD_LIBRARY_PATH= $LD_LIBRARY_PATH"
echo "Installing torchaudio..." 
if ! (python3.12 -m pip install -v . --no-build-isolation --no-deps);then
   echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
   echo "$PACKAGE_URL $PACKAGE_NAME"
   echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
   exit 1
fi

#basic import test
export LD_LIBRARY_PATH="/OpenBLAS/:${LD_LIBRARY_PATH}"

if ! (python3.12 -c "import torch; import torch._C; import torchaudio"); then
     echo "--------------------$PACKAGE_NAME:Install_success_but_test_fails--------------------"
     echo "$PACKAGE_URL $PACKAGE_NAME"
     echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but__Import_Fails"
     exit 2
else
     echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
     echo "$PACKAGE_URL $PACKAGE_NAME"
     echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Import_Success"
     exit 0
fi
