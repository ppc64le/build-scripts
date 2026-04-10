# -----------------------------------------------------------------------------
#
# Package       : vllm
# Version       : v0.18.0
# Source repo   : https://github.com/vllm-project/vllm
# Tested on     : UBI:9.6
# Language      : Python
# Ci-Check  :     True
# Script License: Apache License 2.0
# Maintainer    : Nishidha Panpaliya <nishidha.panpaliya@partner.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash
set -eoux pipefail

########################################
# Resolve repo root (IMPORTANT)
########################################

REPO_ROOT="$(pwd)"

cd "$REPO_ROOT"

########################################
# DevPI configuration
########################################

IBM_DEVPI_URL=${IBM_DEVPI_URL:-"https://wheels.developerfirst.ibm.com/ppc64le/linux/+simple/"}

if [[ -n "$IBM_DEVPI_URL" ]]; then
    echo "Using IBM's Python index: $IBM_DEVPI_URL"
    export PIP_EXTRA_INDEX_URL=$IBM_DEVPI_URL
fi

########################################
# install system dependencies
########################################

rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm

microdnf install -y \
    python3.12 python3.12-devel python3.12-pip gcc \
    git jq gcc-toolset-14 gcc-toolset-14-libatomic-devel \
    automake libtool clang-devel openssl-devel freetype-devel fribidi-devel \
    harfbuzz-devel kmod lcms2-devel libimagequant-devel libjpeg-turbo-devel \
    llvm15-devel libraqm-devel libtiff-devel libwebp-devel libxcb-devel \
    ninja-build openjpeg2-devel pkgconfig protobuf* \
    tcl-devel tk-devel xsimd-devel zeromq-devel zlib-devel patchelf file libjpeg-turbo-devel

rpm -ivh --nodeps https://mirror.stream.centos.org/9-stream/CRB/ppc64le/os/Packages/protobuf-lite-devel-3.14.0-17.el9.ppc64le.rpm

########################################
# Python 3.12 virtual environment
########################################

python3.12 -m venv /opt/vllm
source /opt/vllm/bin/activate

export PATH=/opt/vllm/bin:$PATH

python --version

########################################
# install build tools (stable uv)
########################################

pip install -U pip
pip install "uv==0.4.30"
uv pip install setuptools cython build wheel auditwheel cmake meson-python --no-build-isolation

########################################
# Rust
########################################

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source /root/.cargo/env

########################################
# Compiler env
########################################

source /opt/rh/gcc-toolset-14/enable

export PATH=/usr/lib64/llvm15/bin:$PATH
export LLVM_CONFIG=/usr/lib64/llvm15/bin/llvm-config
export CMAKE_ARGS="-DPython3_EXECUTABLE=python"

export MAX_JOBS=${MAX_JOBS:-$(nproc)}
export GRPC_PYTHON_BUILD_SYSTEM_OPENSSL=1

########################################
# wheel dir
########################################

mkdir -p $WHEEL_DIR

########################################
# DevPI helper
########################################

try_install_from_devpi() {
    pkg=$1
    if [[ -n "$IBM_DEVPI_URL" ]]; then
        if uv pip install \
            --extra-index-url "$IBM_DEVPI_URL" \
            --index-strategy unsafe-best-match \
            --no-build-isolation \
            "$pkg"; then
            echo "Installed $pkg from DevPI"
            return 0
        fi
    fi
    return 1
}

########################################
# LAPACK
########################################

cd /root
LAPACK_VERSION=$(curl -s https://api.github.com/repos/Reference-LAPACK/lapack/releases/latest | jq -r '.tag_name' | sed 's/v//')

git clone --depth 1 https://github.com/Reference-LAPACK/lapack.git -b v${LAPACK_VERSION}
cd lapack
cmake -B build -S .
cmake --build build -j ${MAX_JOBS}
cmake --install build

########################################
# NUMACTL
########################################

cd /root
NUMACTL_VERSION=$(curl -s https://api.github.com/repos/numactl/numactl/releases/latest | jq -r '.tag_name' | sed 's/v//')

git clone --depth 1 https://github.com/numactl/numactl.git -b v${NUMACTL_VERSION}
cd numactl

autoreconf -i
./configure
make -j ${MAX_JOBS}
make install

########################################
# OPENBLAS
########################################

cd /root
OPENBLAS_VERSION=$(curl -s https://api.github.com/repos/OpenMathLib/OpenBLAS/releases/latest | jq -r '.tag_name' | sed 's/v//')

curl -L https://github.com/OpenMathLib/OpenBLAS/releases/download/v${OPENBLAS_VERSION}/OpenBLAS-${OPENBLAS_VERSION}.tar.gz | tar xz

mv OpenBLAS-${OPENBLAS_VERSION}/ OpenBLAS/
cd OpenBLAS/

make -j${MAX_JOBS} TARGET=POWER9 BUILD_BFLOAT16=1 BINARY=64 USE_OPENMP=1 USE_THREAD=1 NUM_THREADS=120 DYNAMIC_ARCH=1 INTERFACE64=0
make install

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib64:/usr/local/lib

########################################
# PYTORCH FAMILY
########################################

install_torch_family() {

    cd "$REPO_ROOT"
    export TORCH_VERSION=2.10.0
    TORCH_VERSION=${TORCH_VERSION:-$(grep -E '^torch==.+==\s*\"ppc64le\"' requirements/cpu.txt | grep -Eo '\b[0-9\.]+\b')}
    echo "Torch version: $TORCH_VERSION"
    TORCHVISION_VERSION=0.24.1
    export TORCHVISION_VERSION=${TORCHVISION_VERSION:-$(grep -E '^torchvision==.+==\s*\"ppc64le\"' requirements/cpu.txt | grep -Eo '\b[0-9\.]+\b')}
    TORCHAUDIO_VERSION=2.9.1
    export TORCHAUDIO_VERSION=${TORCHAUDIO_VERSION:-$(grep -E '^torchaudio==.+==\s*\"ppc64le\"' requirements/cpu.txt | grep -Eo '\b[0-9\.]+\b')}

    TEMP_BUILD_DIR=$(mktemp -d)
    cd ${TEMP_BUILD_DIR}

    export BLAS=OpenBLAS
    export USE_OPENMP=1
    export USE_MKLDNN=OFF
    export USE_MKLDNN_CBLAS=OFF
    export OPENBLAS_HOME="/usr/local"
    export PKG_CONFIG_PATH="$OPENBLAS_HOME/lib/pkgconfig:${PKG_CONFIG_PATH}"
    export LIBRARY_PATH="$OPENBLAS_HOME/lib:${LD_LIBRARY_PATH}"
    export C_INCLUDE_DIR="$OPENBLAS_HOME/include"
    export CPLUS_INCLUDE_DIR="$OPENBLAS_HOME/include"

    : ================== Installing Pytorch ==================
    export _GLIBCXX_USE_CXX11_ABI=1
    git clone --recursive https://github.com/pytorch/pytorch.git -b v${TORCH_VERSION}
    cd pytorch
    sed -i '/lintrunner ;/s/$/ and platform_machine != "ppc64le"/' requirements.txt
    uv pip install -r requirements.txt \
       --extra-index-url "$IBM_DEVPI_URL" \
       --index-strategy unsafe-best-match \
       --no-build-isolation
    python setup.py develop
    rm -f dist/torch*+git*whl
    MAX_JOBS=${MAX_JOBS:-$(nproc)} \
    PYTORCH_BUILD_VERSION=${TORCH_VERSION} PYTORCH_BUILD_NUMBER=1 uv build --wheel --out-dir ${WHEEL_DIR}

    cd ${TEMP_BUILD_DIR}

    : ================== Installing Torchvision ==================
    export TORCHVISION_USE_NVJPEG=0 TORCHVISION_USE_FFMPEG=0
    git clone --recursive https://github.com/pytorch/vision.git -b v${TORCHVISION_VERSION}
    cd vision
    uv pip install standard-pkg-resources --no-build-isolation
    MAX_JOBS=${MAX_JOBS:-$(nproc)} \
    BUILD_VERSION=${TORCHVISION_VERSION} \
    uv build --wheel --out-dir ${WHEEL_DIR} --no-build-isolation

    cd ${TEMP_BUILD_DIR}

    : ================== Installing Torchaudio ==================
    export BUILD_SOX=1 BUILD_KALDI=1 BUILD_RNNT=1 USE_FFMPEG=0 USE_ROCM=0 USE_CUDA=0
    export TORCHAUDIO_TEST_ALLOW_SKIP_IF_NO_FFMPEG=1
    git clone --recursive https://github.com/pytorch/audio.git -b v${TORCHAUDIO_VERSION}
    cd audio
    MAX_JOBS=${MAX_JOBS:-$(nproc)} \
    BUILD_VERSION=${TORCHAUDIO_VERSION} \
    uv build --wheel --out-dir ${WHEEL_DIR} --no-build-isolation

    cd ${REPO_ROOT}
    rm -rf ${TEMP_BUILD_DIR}

}

# TODO(): figure out exact llvmlite version needed by numba
install_llvmlite() {

    if try_install_from_devpi llvmlite==0.44.0; then
       return
    fi

    TEMP_BUILD_DIR=$(mktemp -d)
    cd $TEMP_BUILD_DIR

    export LLVMLITE_VERSION=${LLVMLITE_VERSION:-0.44.0}

    TEMP_BUILD_DIR=$(mktemp -d)
    cd ${TEMP_BUILD_DIR}

    : ================== Installing Llvmlite ==================
    git clone --recursive https://github.com/numba/llvmlite.git -b v${LLVMLITE_VERSION}
    cd llvmlite
    echo "setuptools<70.0.0" > build_constraints.txt
    uv build --wheel --out-dir /llvmlitewheel --build-constraint build_constraints.txt

    : ================= Fix LLvmlite Wheel ====================
    cd /llvmlitewheel

    auditwheel repair llvmlite*.whl
    mv wheelhouse/llvmlite*.whl ${WHEEL_DIR}

    cd "$REPO_ROOT"
    rm -rf $TEMP_BUILD_DIR
}



########################################
# PYARROW
########################################

install_pyarrow() {

TEMP_BUILD_DIR=$(mktemp -d)
cd $TEMP_BUILD_DIR

PYARROW_VERSION=$(curl -s https://api.github.com/repos/apache/arrow/releases/latest | jq -r '.tag_name' | grep -Eo "[0-9.]+")

git clone --depth 1 https://github.com/apache/arrow.git -b apache-arrow-${PYARROW_VERSION}

cd arrow/cpp
mkdir build && cd build

cmake -DCMAKE_BUILD_TYPE=release \
-DCMAKE_INSTALL_PREFIX=/usr/local \
-DARROW_PYTHON=ON \
-DARROW_PARQUET=ON \
-DCMAKE_POLICY_VERSION_MINIMUM=3.5 ..
make install -j ${MAX_JOBS}

cd ../../python
uv pip install -r requirements-wheel-build.txt \
    --extra-index-url "$IBM_DEVPI_URL" \
    --index-strategy unsafe-best-match \
    --no-build-isolation

python setup.py build_ext \
--build-type=release --bundle-arrow-cpp \
bdist_wheel --dist-dir ${WHEEL_DIR}

cd "$REPO_ROOT"
rm -rf $TEMP_BUILD_DIR
}

########################################
# NUMBA
########################################

install_numba() {

TEMP_BUILD_DIR=$(mktemp -d)
cd $TEMP_BUILD_DIR

NUMBA_VERSION=$(grep 'numba' "$REPO_ROOT/requirements/cpu.txt" | \
    sed -E 's/.*numba *== *([0-9.]+).*/\1/' | \
    head -1)
git clone --depth 1 https://github.com/numba/numba.git -b ${NUMBA_VERSION}

cd numba

sed -i '/#include "internal\/pycore_atomic.h"/i\#include "dynamic_annotations.h"' numba/_dispatcher.cpp || true

uv build --wheel --out-dir ${WHEEL_DIR} --no-build-isolation

cd "$REPO_ROOT"
rm -rf $TEMP_BUILD_DIR
}

install_xgrammar() {
    cd ${REPO_ROOT}

    echo "========== Installing xgrammar =========="
    export XGRAMMAR_VERSION="0.1.32"
    echo "xgrammar version: ${XGRAMMAR_VERSION}"

    TEMP_BUILD_DIR=$(mktemp -d)
    cd ${TEMP_BUILD_DIR}


    export CFLAGS="-fno-lto -mcpu=power9"
    export CXXFLAGS="-fno-lto -mcpu=power9"
    export LDFLAGS="-fno-lto"
    export CMAKE_ARGS="-DCMAKE_INTERPROCEDURAL_OPTIMIZATION=OFF"

    echo "========== Cloning xgrammar =========="
    git clone --recursive https://github.com/mlc-ai/xgrammar -b v${XGRAMMAR_VERSION}

    cd xgrammar

    cp cmake/config.cmake .

    echo "========== Building wheel =========="
    uv build --wheel --out-dir ${WHEEL_DIR}

    echo "========== Installing wheel =========="
    uv pip install ${WHEEL_DIR}/xgrammar*.whl

    echo "========== Cleanup =========="
    cd ${REPO_ROOT}
    rm -rf ${TEMP_BUILD_DIR}

}

install_opencv() {
    TEMP_BUILD_DIR=$(mktemp -d)
    cd ${TEMP_BUILD_DIR}
    export OPENCV_VERSION=92

    export ENABLE_HEADLESS=1
    git clone --recursive https://github.com/opencv/opencv-python.git -b ${OPENCV_VERSION} && \
    cd opencv-python && \
    if  [[ ${OPENCV_VERSION} == "92" ]]; then sed -i 's/__ARCH_PWR10__/__ARCH_PWR10__)/' opencv/modules/core/include/opencv2/core/vsx_utils.hpp; fi && \
    uv build --wheel --out-dir ${WHEEL_DIR} && \
    cd "$REPO_ROOT" && \
    rm -rf $TEMP_BUILD_DIR

}


########################################
# RUN BUILDS
########################################
export CMAKE_C_COMPILER=/opt/rh/gcc-toolset-14/root/usr/bin/gcc
export CMAKE_CXX_COMPILER=/opt/rh/gcc-toolset-14/root/usr/bin/g++
source /opt/rh/gcc-toolset-14/enable
export CC=/opt/rh/gcc-toolset-14/root/usr/bin/gcc
export CXX=/opt/rh/gcc-toolset-14/root/usr/bin/g++

uv pip install sentencepiece==0.2.1 --no-build-isolation

install_opencv
install_torch_family
install_llvmlite
install_pyarrow
install_numba
install_xgrammar

########################################
# install built wheels
########################################

uv pip install maturin setuptools-rust scikit-build-core pybind11 nanobind \
    --no-build-isolation

uv pip install ${WHEEL_DIR}/*.whl \
    --extra-index-url "$IBM_DEVPI_URL" \
    --index-strategy unsafe-best-match \
    --no-build-isolation


########################################
# install remaining deps
########################################

sed -i.bak -e 's/.*torch.*//g' pyproject.toml requirements/*.txt

uv pip install httptools \
    --extra-index-url "$IBM_DEVPI_URL" \
    --index-strategy unsafe-best-match \
    --no-build-isolation || true


export PKG_CONFIG_PATH=$(find / -type d -name "pkgconfig" 2>/dev/null | tr '\n' ':')

uv pip install -r requirements/common.txt \
               -r requirements/cpu.txt \
               -r requirements/build.txt --extra-index-url "$IBM_DEVPI_URL" --index-strategy unsafe-best-match
