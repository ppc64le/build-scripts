#!/bin/bash -e

# -----------------------------------------------------------------------------
#
# Package           : vllm
# Version           : v0.6.3
# Source repo       : https://github.com/vllm-project/vllm.git
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

PACKAGE_NAME=vllm
PACKAGE_VERSION=${1:-v0.6.3}
PACKAGE_URL=https://github.com/vllm-project/vllm.git
OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)
PYTHON_VER=${2:-3.11}
export _GLIBCXX_USE_CXX11_ABI=1

dnf install -y https://mirror.stream.centos.org/9-stream/BaseOS/ppc64le/os/Packages/centos-gpg-keys-9.0-24.el9.noarch.rpm \
            https://mirror.stream.centos.org/9-stream/BaseOS/`arch`/os/Packages/centos-stream-repos-9.0-24.el9.noarch.rpm \
                        https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/BaseOS/`arch`/os
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/AppStream/`arch`/os
dnf config-manager --set-enabled crb

dnf install -y git cmake ninja-build rust cargo \
            kmod libatomic procps g++ openblas-devel gfortran \
            boost1.78-devel gflags-devel rapidjson-devel re2-devel \
            utf8proc-devel gtest-devel gmock-devel xsimd-devel java-17-openjdk-devel \
            libtiff-devel libjpeg-devel openjpeg2-devel zlib-devel numactl-devel \
            libpng-devel freetype-devel lcms2-devel libwebp-devel tcl-devel tk-devel \
            harfbuzz-devel fribidi-devel libraqm-devel libimagequant-devel libxcb-devel \
            python${PYTHON_VER}-devel python${PYTHON_VER}-pip python${PYTHON_VER}-setuptools python${PYTHON_VER}-wheel

if ! command -v pip; then
    ln -s $(command -v pip${PYTHON_VER}) /usr/bin/pip
fi
if ! command -v python; then
    ln -s $(command -v python${PYTHON_VER}) /usr/bin/python
fi

pip install -U pip cython wheel build setuptools setuptools_scm setuptools_rust packaging \
    numpy pandas pillow scikit_build_core scikit-build meson-python sentencepiece

export MAX_JOBS=${MAX_JOBS:-$(nproc)}
export USE_FFMPEG=0
export BUILD_SOX=0
export BUILD_KALDI=0
export BUILD_RNNT=0
export USE_ROCM=0
export USE_CUDA=0
export PREFIX=/usr
export CC=$(command -v gcc)
export CXX=$(command -v g++)
export CMAKE_C_COMPILER=$CC
export CMAKE_CXX_COMPILER=$CXX
export CFLAGS="-w -O3 -DLOG_LEVEL=ERROR"
export CXXFLAGS="-w -O3 -DLOG_LEVEL=ERROR"
export CMAKE_C_FLAGS=$CFLAGS
export CMAKE_CXX_FLAGS=$CXXFLAGS
export ARROW_HOME=/repos/dist
export ARROW_BUILD_TYPE=release
export LD_LIBRARY_PATH=$ARROW_HOME/lib64:/usr/lib64:/usr/lib:$LD_LIBRARY_PATH


# Clone all required dependencies
git clone --recursive https://github.com/llvm/llvm-project.git &
git clone --recursive https://github.com/numba/llvmlite.git &
git clone --recursive https://github.com/pytorch/pytorch.git &
git clone --recursive https://github.com/pytorch/vision.git &
git clone --recursive https://github.com/pytorch/audio.git &
git clone --recursive https://github.com/apache/arrow.git &
git clone --recursive https://github.com/vllm-project/vllm.git &

wait $(jobs -p)

# Arrow, LLVM, Pytorch can be built independently
# llvmlite depends on llvm
# torchvision, torchaudio depend on pytorch
# Try building independent packages in parallel

# Prepare Arrow
cd /arrow
git submodule update --init --recursive
cd cpp
mkdir build
cd build
cmake -DCMAKE_BUILD_TYPE=$ARROW_BUILD_TYPE \
      -DCMAKE_INSTALL_PREFIX=$ARROW_HOME   \
          -Dutf8proc_LIB=/usr/lib64/libutf8proc.so \
          -Dutf8proc_INCLUDE_DIR=/usr/include \
          -DARROW_PYTHON=ON \
          -DARROW_BUILD_TESTS=OFF \
          -DARROW_JEMALLOC=ON \
          -DCMAKE_C_COMPILER=$CC \
          -DCMAKE_CXX_COMPILER=$CXX \
          -DARROW_BUILD_STATIC="OFF" \
          -DARROW_PARQUET=ON \
          ..

# Prepare LLVM
cd /llvm-project
git checkout llvmorg-15.0.7
mkdir build && cd  build
CMAKE_ARGS="${CMAKE_ARGS} -DLLVM_ENABLE_PROJECTS=lld;libunwind;compiler-rt"
CFLAGS="$(echo $CFLAGS | sed 's/-fno-plt //g')"
CXXFLAGS="$(echo $CXXFLAGS | sed 's/-fno-plt //g')"
CMAKE_ARGS="${CMAKE_ARGS} -DFFI_INCLUDE_DIR=$PREFIX/include"
CMAKE_ARGS="${CMAKE_ARGS} -DFFI_LIBRARY_DIR=$PREFIX/lib"
cmake -DCMAKE_INSTALL_PREFIX="${PREFIX}"               \
      -DCMAKE_BUILD_TYPE=Release                       \
      -DCMAKE_LIBRARY_PATH="${PREFIX}"                 \
      -DLLVM_ENABLE_LIBEDIT=OFF                        \
      -DLLVM_ENABLE_LIBXML2=OFF                        \
      -DLLVM_ENABLE_RTTI=ON                            \
      -DLLVM_ENABLE_TERMINFO=OFF                       \
      -DLLVM_INCLUDE_BENCHMARKS=OFF                    \
      -DLLVM_INCLUDE_DOCS=OFF                          \
      -DLLVM_INCLUDE_EXAMPLES=OFF                      \
      -DLLVM_INCLUDE_GO_TESTS=OFF                      \
      -DLLVM_INCLUDE_TESTS=OFF                         \
      -DLLVM_INCLUDE_UTILS=ON                          \
      -DLLVM_INSTALL_UTILS=ON                          \
      -DLLVM_UTILS_INSTALL_DIR=libexec/llvm            \
      -DLLVM_BUILD_LLVM_DYLIB=OFF                      \
      -DLLVM_LINK_LLVM_DYLIB=OFF                       \
      -DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD=WebAssembly \
      -DLLVM_ENABLE_FFI=ON                             \
      -DLLVM_ENABLE_Z3_SOLVER=OFF                      \
      -DLLVM_OPTIMIZED_TABLEGEN=ON                     \
      -DCMAKE_POLICY_DEFAULT_CMP0111=NEW               \
      -DCOMPILER_RT_BUILD_BUILTINS=ON                  \
      -DCOMPILER_RT_BUILTINS_HIDE_SYMBOLS=OFF          \
      -DCOMPILER_RT_BUILD_LIBFUZZER=OFF                \
      -DCOMPILER_RT_BUILD_CRT=OFF                      \
      -DCOMPILER_RT_BUILD_MEMPROF=OFF                  \
      -DCOMPILER_RT_BUILD_PROFILE=OFF                  \
      -DCOMPILER_RT_BUILD_SANITIZERS=OFF               \
      -DCOMPILER_RT_BUILD_XRAY=OFF                     \
      -DCOMPILER_RT_BUILD_GWP_ASAN=OFF                 \
      -DCOMPILER_RT_BUILD_ORC=OFF                      \
      -DCOMPILER_RT_INCLUDE_TESTS=OFF                  \
      ${CMAKE_ARGS} -GNinja ../llvm

# Prepare Pytorch
cd /pytorch
git submodule sync
git submodule update --init --recursive
pip install -r requirements.txt

##########################################
# Build Independent packages in parallel #
##########################################
cd /llvm-project/build
ninja install -j $MAX_JOBS &

cd /arrow/cpp/build
make install -j $MAX_JOBS &

cd /pytorch
pip install -v -e . --no-build-isolation &

wait $(jobs -p)


########################################
# Build Dependent packages in parallel #
########################################

# pyarrow
cd /arrow/python
CMAKE_PREFIX_PATH=$ARROW_HOME pip install -v -e . --no-build-isolation &

# llvmlite
cd /llvmlite
pip install -v -e . --no-build-isolation &

# torchvision
cd /vision
pip install -v -e . --no-build-isolation &

# torchaudio
cd /audio
pip install -v -e . --no-build-isolation &

wait $(jobs -p)


##############
# Build VLLM #
##############
cd /vllm
git checkout $PACKAGE_VERSION
python use_existing_torch.py
pip install -r requirements-build.txt

if ! (VLLM_TARGET_DEVICE=cpu pip install -v -e . --no-build-isolation); then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
    exit 1
fi

pip install pytest

if ! pytest tests/test_sequence.py tests/test_inputs.py; then
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
