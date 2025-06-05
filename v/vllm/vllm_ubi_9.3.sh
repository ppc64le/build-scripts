#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package           : vllm
# Version           : v0.8.4
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

PACKAGE_VERSION=${1:-v0.8.4}
PYTHON_VERSION=${PYTHON_VERSION:-3.11}

export MAX_JOBS=${MAX_JOBS:-$(nproc)}
export VLLM_TARGET_DEVICE=${VLLM_TARGET_DEVICE:-cpu}
export OPENBLAS_VERSION=${OPENBLAS_VERSION:-0.3.29}

export TORCH_VERSION=${TORCH_VERSION:-2.6.0}
export TORCHVISION_VERSION=${TORCHVISION_VERSION:-0.21.0}
export TORCHAUDIO_VERSION=${TORCHAUDIO_VERSION:-2.6.0}
export PYARROW_VERSION=${PYARROW_VERSION:-19.0.1}
export OPENCV_PYTHON_VERSION=${OPENCV_PYTHON_VERSION:-86}

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
# to build grpcio
export GRPC_PYTHON_BUILD_SYSTEM_OPENSSL=${GRPC_PYTHON_BUILD_SYSTEM_OPENSSL:-1}

# to skip tests if building in Dockerfiles (tests will pull ~10G models which will bloat images)
SKIP_TESTS=${SKIP_TESTS:-False}

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

dnf install -y openssl-devel
dnf install -y https://mirror.stream.centos.org/9-stream/BaseOS/`arch`/os/Packages/centos-gpg-keys-9.0-24.el9.noarch.rpm \
            https://mirror.stream.centos.org/9-stream/BaseOS/`arch`/os/Packages/centos-stream-repos-9.0-24.el9.noarch.rpm \
            https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/BaseOS/`arch`/os
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/AppStream/`arch`/os
dnf config-manager --set-enabled crb
# install whatever is required from centos
dnf install -y openjpeg2-devel lcms2-devel tcl-devel tk-devel fribidi-devel re2-devel utf8proc-devel
# delete centos stuff to avoid conflicts
dnf remove -y centos-gpg-keys-9.0-24.el9.noarch centos-stream-repos-9.0-24.el9.noarch 

dnf install -y git gcc-toolset-13 kmod jq \
    numactl-devel libtiff-devel ninja-build \
    libimagequant-devel libxcb-devel zeromq-devel \
    llvm llvm-devel clang clang-devel cmake \
    python$PYTHON_VERSION-devel \
    python$PYTHON_VERSION-pip \
    python$PYTHON_VERSION-setuptools \
    python$PYTHON_VERSION-wheel

source /opt/rh/gcc-toolset-13/enable

# Install OpenBLAS
curl -sL https://github.com/OpenMathLib/OpenBLAS/releases/download/v$OPENBLAS_VERSION/OpenBLAS-$OPENBLAS_VERSION.tar.gz | tar xvzf -
cd OpenBLAS-$OPENBLAS_VERSION
# keep TARGET=POWER9 for backwards compatibility with Power9 HW
make -j${MAX_JOBS} TARGET=POWER9 BINARY=64 USE_OPENMP=1 USE_THREAD=1 NUM_THREADS=120 DYNAMIC_ARCH=1 INTERFACE64=0
PREFIX=/usr/local make install
cd .. && rm -rf OpenBLAS-$OPENBLAS_VERSION

export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig/
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib64:/usr/local/lib:/usr/lib64:/usr/lib

# need this for sentencepiece (gcc-13 does not create this symlink, gcc-11 does)
ln -sf /usr/lib64/libatomic.so.1 /opt/rh/gcc-toolset-13/root/usr/lib/gcc/ppc64le-redhat-linux/13/libatomic.so 

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


# Build Dependencies when BUILD_DEPS is unset or set to True
if [ -z $BUILD_DEPS ] || [ $BUILD_DEPS == True ]; then

    # gmock-devel gtest-devel libpng-devel(comes from tk-devel) fribidi-devel(comes from libraqm-devel) 
    # freetype-devel(comes from tk-devel) harfbuzz-devel(comes from tk-devel)
    # setup
    dnf install -y tk-devel \
        zlib-devel ninja-build xsimd-devel \
        gflags-devel libraqm-devel libwebp-devel \
        libjpeg-devel rapidjson-devel boost1.78-devel \
        java-17-openjdk-devel utf8proc-devel

    # need rustc 1.81+ for outlines-core (distro rust is 1.79)    
    curl https://sh.rustup.rs -sSf | sh -s -- -y && source "$HOME/.cargo/env"

    DEPS_DIR=$WORKDIR/deps_from_src
    rm -rf $DEPS_DIR
    mkdir -p $DEPS_DIR
    cd $DEPS_DIR

    export PREFIX=/usr
    export OPENSSL_DIR=/usr
    export OPENSSL_LIB_DIR=/usr/lib64
    export OPENSSL_INCLUDE_DIR=/usr/include

    python -m pip install -U pip 'cmake<4' cython wheel build setuptools setuptools_scm setuptools_rust packaging meson-python maturin
    python -m pip install -U pip pandas pillow scikit_build_core scikit-build sentencepiece outlines-core pydantic pythran pybind11 
    
    # Dependencies needed from src: pytorch, torchvision, torchaudio, llvmlite, pyarrow, opencv-python-headless

    # Clone all required dependencies
    git clone --recursive https://github.com/pytorch/pytorch.git -b v${TORCH_VERSION} &
    git clone --recursive https://github.com/pytorch/vision.git -b v${TORCHVISION_VERSION} &
    git clone --recursive https://github.com/pytorch/audio.git -b v${TORCHAUDIO_VERSION} &
    git clone --recursive https://github.com/apache/arrow.git -b apache-arrow-${PYARROW_VERSION} &
    git clone --recursive https://github.com/opencv/opencv-python.git -b ${OPENCV_PYTHON_VERSION} &
    git clone --recursive https://github.com/opencv/opencv-python.git -b ${OPENCV_PYTHON_VERSION} &
    git clone --recursive https://github.com/huggingface/xet-core.git &
    wait $(jobs -p)

    # Arrow, OpenCV, Pytorch can be built independently
    # torchvision, torchaudio depend on pytorch
    # Try building independent packages in parallel

    # Prepare Arrow
    cd $DEPS_DIR/arrow
    git submodule update --init --recursive
    cd cpp
    mkdir build
    cd build
    cmake -DCMAKE_BUILD_TYPE=release \
        -DCMAKE_INSTALL_PREFIX=/usr/local \
        -DARROW_PYTHON=ON \
        -DARROW_BUILD_TESTS=OFF \
        -DARROW_JEMALLOC=ON \
        -DARROW_BUILD_STATIC="OFF" \
        -DARROW_PARQUET=ON \
        ..

    # Prepare Pytorch
    cd $DEPS_DIR/pytorch
    git submodule sync
    git submodule update --init --recursive
    python -m pip install -r requirements.txt

    # Prepare Opencv
    # patch applicable only for opencv-python version 4.11.0.86
    OPENCV_PATCH=97f3f39
    cd $DEPS_DIR/opencv-python
    sed -i -E -e 's/"setuptools.+",/"setuptools",/g' pyproject.toml
    cd opencv && git cherry-pick --no-commit $OPENCV_PATCH

    ##########################################
    # Build Independent packages in parallel #
    ##########################################
    cd $DEPS_DIR/arrow/cpp/build
    make install -j $MAX_JOBS &

    cd $DEPS_DIR/pytorch
    python setup.py install &

    cd $DEPS_DIR/opencv-python
    python -m pip install -v . &

    cd $DEPS_DIR/xet-core/hf_xet/
    python -m pip install -v . &

    wait $(jobs -p)

    ########################################
    # Build Dependent packages in parallel #
    ########################################

    # pyarrow
    cd $DEPS_DIR/arrow/python
    python -m pip install -v . --no-build-isolation &

    # torchvision
    cd $DEPS_DIR/vision
    python -m pip install -v . --no-build-isolation &

    # torchaudio
    cd $DEPS_DIR/audio
    python -m pip install -v . --no-build-isolation &
    
    wait $(jobs -p)

    #########################
    # modify vllm to use built pytorch vesion
    cd $WORKDIR
    python use_existing_torch.py

    # cleanup
    rm -rf $DEPS_DIR
fi

# Build vllm
cd $WORKDIR

# setup
BUILD_ISOLATION=""
# When BUILD_DEPS is unset or set to True
if [ -z $BUILD_DEPS ] || [ $BUILD_DEPS == True ]; then
    BUILD_ISOLATION="--no-build-isolation"
fi

# REMOVE LATER
sed -i -e 's/numba.+//g' requirements/cpu.txt

python -m pip install -v -r requirements/build.txt -r requirements/cpu.txt -r requirements/common.txt $BUILD_ISOLATION
# USE cmake<4
sed -i 's/"cmake>=3.26",/"cmake>=3.26,<4",/g' pyproject.toml

if ! (python -m pip install -v . $BUILD_ISOLATION); then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
    exit 1
fi

if [[ $SKIP_TESTS == True ]]; then
    echo "Skipping  testsas 'SKIP_TESTS' is set to True"
    exit 0
fi

# test dependencies (-- all installed with centos mirrors)
# dnf install -y re2-devel utf8proc-devel

python -m pip install -v pytest pytest-asyncio sentence-transformers transformers

# rename vllm src dir or else pytorch tries to import vllm._C from src dir and fails
# AttributeError: '_OpNamespace' '_C' object has no attribute 'silu_and_mul'
# Explanation: https://github.com/vllm-project/vllm/issues/1814#issuecomment-1870790593
mv vllm vllm_src

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

