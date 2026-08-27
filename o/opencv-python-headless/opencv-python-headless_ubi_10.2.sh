#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : opencv-python-headless
# Version          : 5.0.0.93
# Source repo      : https://github.com/opencv/opencv-python.git
# Tested on        : UBI:10.2
# Language         : Python
# Ci-Check         : True
# Script License   : Apache License 2.0
# Maintainer       : Sakshi Jain <sakshi.jain16@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
#                    platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

set -e

PACKAGE_NAME=opencv-python-headless
PACKAGE_VERSION=${1:-93}
# The git tag is the last dot-separated component: 5.0.0.93 → 93
GIT_TAG=${1:-93}
PACKAGE_URL=https://github.com/opencv/opencv-python
CURRENT_DIR=$(pwd)
PACKAGE_DIR=opencv-python

# -----------------------------------------------------------------------------
# System dependencies — Python packages first (wrapper requirement)
# -----------------------------------------------------------------------------
yum install -y python3.14 python3.14-devel python3.14-pip \
    wget git ninja-build make cmake pkgconfig autoconf \
    automake libtool zlib-devel freetype-devel gmp-devel \
    openssl openssl-devel openjpeg2-devel \
    gcc-toolset-15 gcc-toolset-15-gcc gcc-toolset-15-gcc-c++ \
    gcc-toolset-15-gcc-gfortran gcc-toolset-15-binutils gcc-toolset-15-binutils-devel

# Activate gcc-toolset-15 (UBI 10 — SCL removed, use guard block)
if [[ -f /opt/rh/gcc-toolset-15/enable ]]; then
    source /opt/rh/gcc-toolset-15/enable
elif [[ -d /opt/rh/gcc-toolset-15/root/usr/bin ]]; then
    export PATH="/opt/rh/gcc-toolset-15/root/usr/bin:$PATH"
    export LD_LIBRARY_PATH="/opt/rh/gcc-toolset-15/root/usr/lib64:$LD_LIBRARY_PATH"
else
    echo "ERROR: gcc-toolset-15 not found"
    exit 1
fi

echo "Using gcc: $(gcc --version | head -1)"

# -----------------------------------------------------------------------------
# Python tooling
# opencv-python pyproject.toml build-system.requires pins setuptools<70.0.0 —
# keep it in the host environment so --no-build-isolation picks it up correctly.
# -----------------------------------------------------------------------------
python3.14 -m pip install --upgrade pip wheel
python3.14 -m pip install --no-cache-dir "setuptools<70.0.0"

IBM_WHEELS="https://wheels.developerfirst.ibm.com/ppc64le/linux/+simple/"
NUMPY_VERSION="2.5.0"

python3.14 -m pip install "numpy==2.5.0" setuptools

python3.14 -m pip install cython pytest scikit-build build wheel cmake

# -----------------------------------------------------------------------------
# Resolve OpenBLAS paths (installed via IBM devpi)
# devpi packages install to /usr/local/lib/ (not lib64/)
# -----------------------------------------------------------------------------
export OpenBLAS_HOME=/usr/local/lib/python3.14/site-packages/openblas
export OpenBLAS_DIR=${OpenBLAS_HOME}
export LD_LIBRARY_PATH=${OpenBLAS_HOME}/lib:${LD_LIBRARY_PATH}
export PKG_CONFIG_PATH="${OpenBLAS_HOME}/lib/pkgconfig:${PKG_CONFIG_PATH}"

# -----------------------------------------------------------------------------
# Install pre-built abseil-cpp and protobuf from IBM devpi
# Avoids compiling the enormous descriptor.cc translation unit on ppc64le.
# libprotobuf wheel layout: libprotobuf/{bin,include,lib64,...}
# abseil-cpp wheel layout:  abseilcpp/{include,lib,...}
# -----------------------------------------------------------------------------
python3.14 -m pip install \
    --prefer-binary \
    --trusted-host wheels.developerfirst.ibm.com \
    --extra-index-url ${IBM_WHEELS} \
    "libprotobuf==28.0" \
    "abseil-cpp==20240116.2"

ABSEILCPP_PREFIX=$(python3.14 -c "import sysconfig, os; print(os.path.join(sysconfig.get_path('purelib'), 'abseilcpp'))")
LIBPROTOBUF_PREFIX=$(python3.14 -c "import sysconfig, os; print(os.path.join(sysconfig.get_path('purelib'), 'libprotobuf'))")
export LD_LIBRARY_PATH="${LIBPROTOBUF_PREFIX}/lib64:${ABSEILCPP_PREFIX}/lib:${LD_LIBRARY_PATH}"
export PATH="${LIBPROTOBUF_PREFIX}/bin:${PATH}"
echo "abseil-cpp prefix: ${ABSEILCPP_PREFIX}"
echo "libprotobuf prefix: ${LIBPROTOBUF_PREFIX}"
echo "-----------------------------------------------------Installed abseil-cpp + protobuf-----------------------------------------------------"

# -----------------------------------------------------------------------------
# Clone opencv-python source
# -----------------------------------------------------------------------------
cd $CURRENT_DIR
if [ ! -d "$PACKAGE_DIR" ]; then
    git clone $PACKAGE_URL
fi
cd $PACKAGE_DIR
git -c advice.detachedHead=false checkout $GIT_TAG
git submodule update --init --recursive

# -----------------------------------------------------------------------------
# Ensure MLAS headers are visible to the compiler
# Fixes: fatal error: asmmacro.h / SgemmKernelpower.h: No such file or directory
# The MLAS build under opencv/3rdparty/mlas compiles .S and .cpp sources that
# #include headers living in mlas/include, mlas/lib, and mlas/lib/power, but
# CMake does not add those directories to the compiler include path on ppc64le.
# -----------------------------------------------------------------------------
MLAS_DIR="$(pwd)/opencv/3rdparty/mlas"
if [ -d "${MLAS_DIR}" ]; then
    echo "Adding MLAS include locations to compiler flags:"
    ls -l "${MLAS_DIR}/lib/power" || true
    ls -l "${MLAS_DIR}/include"   || true
    export CFLAGS="-I${MLAS_DIR}/include -I${MLAS_DIR}/lib -I${MLAS_DIR}/lib/power ${CFLAGS:-}"
    export CXXFLAGS="${CFLAGS}"
    export CPPFLAGS="${CFLAGS}"
fi

# -----------------------------------------------------------------------------
# Patch vsx_utils.hpp for ppc64le compatibility
# Fixes POWER10 intrinsic detection so it builds correctly on ppc64le
# -----------------------------------------------------------------------------
HEADER_FILE="$(pwd)/opencv/modules/core/include/opencv2/core/vsx_utils.hpp"
if [ -f "$HEADER_FILE" ]; then
    sed -i '261c\#if defined(__POWER10__) || (defined(__powerpc64__) && defined(__ARCH_PWR10__))' "$HEADER_FILE"
    echo "Patched vsx_utils.hpp line 261:"
    sed -n '261p' "$HEADER_FILE"
fi

export ENABLE_HEADLESS=1

# Point OpenCV at the pre-built protobuf; disable in-tree protobuf compilation
export CMAKE_ARGS="-DCMAKE_BUILD_TYPE=Release
                   -DCMAKE_CXX_STANDARD=17
                   -DCMAKE_CXX_STANDARD_REQUIRED=ON
                   -DWITH_EIGEN=1
                   -DBUILD_TESTS=0
                   -DBUILD_DOCS=0
                   -DBUILD_PERF_TESTS=0
                   -DBUILD_ZLIB=0
                   -DBUILD_TIFF=0
                   -DBUILD_PNG=0
                   -DBUILD_OPENEXR=0
                   -DWITH_OPENEXR=0
                   -DBUILD_OPENJPEG=0
                   -DWITH_OPENJPEG=1
                   -DBUILD_JASPER=0
                   -DWITH_ITT=1
                   -DBUILD_JPEG=0
                   -DBUILD_PROTOBUF=OFF
                   -DBUILD_LIBPROTOBUF_FROM_SOURCES=OFF
                   -DPROTOBUF_UPDATE_FILES=ON
                   -DProtobuf_LIBRARY=${LIBPROTOBUF_PREFIX}/lib64/libprotobuf.so
                   -DProtobuf_INCLUDE_DIR=${LIBPROTOBUF_PREFIX}/include
                   -DCMAKE_PREFIX_PATH=${ABSEILCPP_PREFIX}:${LIBPROTOBUF_PREFIX}
                   -DBUILD_opencv_dnn=OFF
                   -DWITH_V4L=1
                   -DWITH_OPENCL=0
                   -DWITH_OPENCLAMDFFT=0
                   -DWITH_OPENCLAMDBLAS=0
                   -DWITH_OPENCL_D3D11_NV=0
                   -DWITH_1394=0
                   -DWITH_CARBON=0
                   -DWITH_OPENNI=0
                   -DWITH_FFMPEG=0
                   -DHAVE_FFMPEG=0
                   -DWITH_JASPER=0
                   -DWITH_VA=0
                   -DWITH_VA_INTEL=0
                   -DWITH_GSTREAMER=0
                   -DWITH_MATLAB=0
                   -DWITH_TESSERACT=0
                   -DWITH_VTK=0
                   -DWITH_GTK=0
                   -DWITH_QT=0
                   -DWITH_GPHOTO2=0
                   -DINSTALL_C_EXAMPLES=0
                   -DWITH_LAPACK=0
                   -DHAVE_LAPACK=0
                   -DLAPACK_LAPACKE_H=${OpenBLAS_HOME}/include/lapacke.h
                   -DLAPACK_CBLAS_H=${OpenBLAS_HOME}/include/cblas.h
                   -DOPENCV_DISABLE_OPTIMIZATION=ON
                   -DWITH_VSX=OFF
                   -DENABLE_VSX=OFF
                   -DCPU_DISPATCH=
                   -DCPU_BASELINE="

# Set NumPy include paths for the build
export C_INCLUDE_PATH=$(python3.14 -c "import numpy; print(numpy.get_include())")
export CPLUS_INCLUDE_PATH=$C_INCLUDE_PATH
ln -sf $CURRENT_DIR/$PACKAGE_DIR/tests/SampleVideo_1280x720_1mb.mp4 SampleVideo_1280x720_1mb.mp4

# Build package (--no-build-isolation ensures numpy C headers are found)
if ! python3.14 -m pip install . --no-build-isolation ; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# Build wheel — use setup.py bdist_wheel to bypass pyproject.toml
# build-system.requires (which pins setuptools<70.0.0 and conflicts with
# setuptools>=70.1 required by the bdist_wheel entrypoint).
echo "---------------------------------------------------Building the wheel--------------------------------------------------"
python3.14 setup.py bdist_wheel --plat-name=linux_$(uname -m) --dist-dir="$CURRENT_DIR"

# Test package
# Skipping test_video_capture: ffmpeg coders/decoders are disabled at build time
if ! python3.14 -m pytest tests/test.py -k "not test_video_capture" -v ; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
