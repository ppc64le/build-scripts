#!/bin/bash -e

# -----------------------------------------------------------------------------
#
# Package           : numba
# Version           : 0.61.0
# Source repo       : https://github.com/numba/numba.git
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

PACKAGE_NAME=numba
PACKAGE_URL=https://github.com/numba/numba.git

PACKAGE_VERSION=${1:-0.61.0}
PYTHON_VERSION=${PYTHON_VERSION:-3.11}

export MAX_JOBS=${MAX_JOBS:-$(nproc)}

WORKDIR=$(pwd)

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

dnf install -y git cmake libffi-devel gcc-toolset-12 ninja-build \
    python${PYTHON_VERSION}-devel \
    python${PYTHON_VERSION}-pip \
    python${PYTHON_VERSION}-wheel \
    python${PYTHON_VERSION}-setuptools 

source /opt/rh/gcc-toolset-12/enable

if [ -z $PACKAGE_SOURCE_DIR ]; then
    git clone $PACKAGE_URL -b $PACKAGE_VERSION
    cd $PACKAGE_NAME
    WORKDIR=$(pwd)
else
    WORKDIR=$PACKAGE_SOURCE_DIR
    cd $WORKDIR
    git checkout $PACKAGE_VERSION
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

# Build Dependencies when BUILD_DEPS is unset or set to True
if [ -z $BUILD_DEPS ] || [ $BUILD_DEPS == True ]; then

    # setup
    DEPS_DIR=$WORKDIR/deps_from_src
    rm -rf $DEPS_DIR
    mkdir -p $DEPS_DIR
    cd $DEPS_DIR
    
    export PREFIX=/usr
    
    # Dependencies needed from src: llvmlite

    # Clone all required dependencies
    git clone --recursive https://github.com/llvm/llvm-project.git &
    git clone --recursive https://github.com/numba/llvmlite.git &
    wait $(jobs -p)

    # Prepare LLVM
    cd $DEPS_DIR/llvm-project
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

    cd $DEPS_DIR/llvm-project/build
    ninja install -j $MAX_JOBS

    # llvmlite
    cd $DEPS_DIR/llvmlite
    python -m pip install -v -e . --no-build-isolation

    # cleanup
    rm -rf $DEPS_DIR
fi

# Build numba
cd $WORKDIR

# Patch
if ! grep '#include "dynamic_annotations.h"' numba/_dispatcher.cpp; then
    sed -i '/#include "internal\/pycore_atomic.h"/i\#include "dynamic_annotations.h"' numba/_dispatcher.cpp
fi

# setup
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

if ! python -m numba.tests.test_runtests; then
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
