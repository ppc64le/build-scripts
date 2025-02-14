#!/bin/bash -e

# -----------------------------------------------------------------------------
#
# Package           : vllm
# Version           : v0.7.2
# Source repo       : https://github.com/vllm-project/vllm.git
# Tested on         : UBI:9.3
# Language          : Python
# Travis-Check      : False
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
PACKAGE_URL=https://github.com/vllm-project/vllm.git

PACKAGE_VERSION=${1:-v0.7.2}
PYTHON_VERSION=${PYTHON_VERSION:-3.11}

export MAX_JOBS=${MAX_JOBS:-$(nproc)}
export VLLM_TARGET_DEVICE=${VLLM_TARGET_DEVICE:-cpu} 

export BUILD_SOX=${BUILD_SOX:-1}
export BUILD_KALDI=${BUILD_KALDI:-1}
export BUILD_RNNT=${BUILD_RNNT:-1}
# skip ffmpeg features
export USE_FFMPEG=${USE_FFMPEG:-0}
export USE_ROCM=${USE_ROCM:-0}
export USE_CUDA=${USE_CUDA:-0}
export _GLIBCXX_USE_CXX11_ABI=${_GLIBCXX_USE_CXX11_ABI:-1}
# opencv-python-headless 
export ENABLE_HEADLESS=${ENABLE_HEADLESS:-1}

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

dnf install -y https://mirror.stream.centos.org/9-stream/BaseOS/`arch`/os/Packages/centos-gpg-keys-9.0-24.el9.noarch.rpm \
            https://mirror.stream.centos.org/9-stream/BaseOS/`arch`/os/Packages/centos-stream-repos-9.0-24.el9.noarch.rpm \
            https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/BaseOS/`arch`/os
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/AppStream/`arch`/os
dnf config-manager --set-enabled crb

dnf install -y git gcc-toolset-13 openblas-devel kmod \
    numactl-devel libtiff-devel openjpeg2-devel openssl-devel \
    libimagequant-devel libxcb-devel zeromq-devel \
    python$PYTHON_VERSION-devel \
    python$PYTHON_VERSION-pip \
    python$PYTHON_VERSION-setuptools \
    python$PYTHON_VERSION-wheel

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
pip install -q setuptools wheel build
##############################################


# Build Dependencies when BUILD_DEPS is unset or set to True
if [ -z $BUILD_DEPS ] || [ $BUILD_DEPS == True ]; then

    # setup
    dnf install -y g++ rust cmake cargo tk-devel tcl-devel \
        libatomic zlib-devel ninja-build gmock-devel xsimd-devel lcms2-devel \
        gtest-devel libpng-devel gflags-devel libraqm-devel libwebp-devel \
        libjpeg-devel fribidi-devel freetype-devel harfbuzz-devel \
        rapidjson-devel boost1.78-devel java-17-openjdk-devel \
        re2-devel utf8proc-devel

    DEPS_DIR=$WORKDIR/deps_from_src
    rm -rf $DEPS_DIR
    mkdir -p $DEPS_DIR
    cd $DEPS_DIR
    
    export PREFIX=/usr
    export CC=$(command -v gcc)
    export CXX=$(command -v g++)
    export CMAKE_C_COMPILER=$CC
    export CMAKE_CXX_COMPILER=$CXX
    export CFLAGS="-w -O3 -DLOG_LEVEL=ERROR"
    export CXXFLAGS="-w -O3 -DLOG_LEVEL=ERROR"
    export CMAKE_C_FLAGS=$CFLAGS
    export CMAKE_CXX_FLAGS=$CXXFLAGS
    export OPENSSL_DIR=/usr
    export OPENSSL_LIB_DIR=/usr/lib64
    export OPENSSL_INCLUDE_DIR=/usr/include
    export ARROW_HOME=/repos/dist
    export ARROW_BUILD_TYPE=release
    export LD_LIBRARY_PATH=$ARROW_HOME/lib64:/usr/lib64:/usr/lib:$LD_LIBRARY_PATH

    
    # Build numpy with gcc-11 & not gcc-13
    pip install -U pip cython wheel build setuptools setuptools_scm setuptools_rust packaging \
    numpy pandas pillow scikit_build_core scikit-build meson-python sentencepiece outlines-core pydantic
    
    # Use gcc-13 for torch and other deps
    source /opt/rh/gcc-toolset-13/enable
    
    # Dependencies needed from src: pytorch, torchvision, torchaudio, llvmlite, pyarrow

    # Clone all required dependencies
    git clone --recursive https://github.com/llvm/llvm-project.git &
    git clone --recursive https://github.com/numba/llvmlite.git &
    git clone --recursive https://github.com/pytorch/pytorch.git &
    git clone --recursive https://github.com/pytorch/vision.git &
    git clone --recursive https://github.com/pytorch/audio.git &
    git clone --recursive https://github.com/apache/arrow.git &
    git clone --recursive https://github.com/apache/arrow.git &
    git clone --recursive https://github.com/vllm-project/vllm.git &
    git clone --recursive https://github.com/opencv/opencv-python.git &
    wait $(jobs -p)

    # Arrow, LLVM, Pytorch can be built independently
    # llvmlite depends on llvm
    # torchvision, torchaudio depend on pytorch
    # Try building independent packages in parallel

    # Prepare Arrow
    cd $DEPS_DIR/arrow
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

    # Prepare Pytorch
    cd $DEPS_DIR/pytorch
    git submodule sync
    git submodule update --init --recursive
    python -m pip install -r requirements.txt

    # Prepare Opencv-Python
    cd $DEPS_DIR/opencv-python/opencv
    PPC64LE_PATCH="97f3f39"
    if ! git log --pretty=format:"%H" | grep -q "$PPC64LE_PATCH"; then
        echo "Applying POWER patch."
        git config --global user.email "Md.Shafi.Hussain@ibm.com"
        git config --global user.name "Md. Shafi Hussain"
        git cherry-pick "$PPC64LE_PATCH"
        cd ..
        git add opencv
        git commit -m "Applied POWER patch: $PPC64LE_PATCH"
    else
        echo "POWER patch not needed."
    fi

    ##########################################
    # Build Independent packages in parallel #
    ##########################################
    cd $DEPS_DIR/llvm-project/build
    ninja install -j $MAX_JOBS &

    cd $DEPS_DIR/arrow/cpp/build
    make install -j $MAX_JOBS &

    cd $DEPS_DIR/pytorch
    python setup.py develop &

    cd $DEPS_DIR/opencv-python
    python -m pip install -v . &

    wait $(jobs -p)

    ########################################
    # Build Dependent packages in parallel #
    ########################################

    # pyarrow
    cd $DEPS_DIR/arrow/python
    CMAKE_PREFIX_PATH=$ARROW_HOME python -m pip install -v -e . --no-build-isolation &

    # llvmlite
    cd $DEPS_DIR/llvmlite
    python -m pip install -v -e . --no-build-isolation &

    # torchvision
    cd $DEPS_DIR/vision
    python -m pip install -v -e . --no-build-isolation &

    # torchaudio
    cd $DEPS_DIR/audio
    python -m pip install -v -e . --no-build-isolation &
    
    wait $(jobs -p)

    #########################

    # modify vllm to use built pytorch vesion
    cd $WORKDIR
    python use_existing_torch.py

else
    source /opt/rh/gcc-toolset-13/enable
fi

# Build vllm
cd $WORKDIR

# setup
BUILD_ISOLATION=""
# When BUILD_DEPS is unset or set to True
if [ -z $BUILD_DEPS ] || [ $BUILD_DEPS == True ]; then
    BUILD_ISOLATION="--no-build-isolation"
fi

python -m pip install -r requirements-build.txt

if ! (python -m pip install -v -e . $BUILD_ISOLATION); then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
    exit 1
fi

# test dependencies
dnf install -y re2-devel utf8proc-devel
python -m pip install -v pytest pytest-asyncio sentence-transformers 

if ! python -m pytest -v -s tests/test_sequence.py tests/test_inputs.py tests/models/embedding/language/test_cls_models.py; then
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
