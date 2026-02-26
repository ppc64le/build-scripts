#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : opencv-python-headless
# Version       : 4.13.0.92
# Source repo   : https://github.com/opencv/opencv-python.git
# Tested on     : UBI:9.5
# Language      : Python
# Ci-Check  : True
# Script License: Apache License 2.0
# Maintainer    : Akash Kaothalkar <akash.kaothalkar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -e

PACKAGE_NAME=opencv-python-headless
PACKAGE_VERSION=${1:-92}
PACKAGE_URL=https://github.com/opencv/opencv-python
CURRENT_DIR=$(pwd)
PACKAGE_DIR=opencv-python

# -----------------------------------------------------------------------------
# System dependencies
# -----------------------------------------------------------------------------
yum install -y wget gcc-toolset-13 gcc-toolset-13-gcc gcc-toolset-13-gcc-c++ \
    gcc-toolset-13-gcc-gfortran gcc-toolset-13-binutils gcc-toolset-13-binutils-devel \
    python3.12 python3.12-devel python3.12-pip \
    git ninja-build make cmake pkgconfig autoconf \
    automake libtool zlib-devel freetype-devel gmp-devel openssl openssl-devel

export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

# -----------------------------------------------------------------------------
# Python tooling
# -----------------------------------------------------------------------------
python3.12 -m pip install --upgrade pip setuptools wheel

# -----------------------------------------------------------------------------
# Install pre-built dependencies from IBM devpi
# -----------------------------------------------------------------------------
IBM_WHEELS="https://wheels.developerfirst.ibm.com/ppc64le/linux/+simple/"

python3.12 -m pip install \
  --prefer-binary \
  --trusted-host wheels.developerfirst.ibm.com \
  --extra-index-url ${IBM_WHEELS} \
  openblas==0.3.29 \
  numpy==2.0.2

python3.12 -m pip install cython pytest scikit-build build wheel cmake

# -----------------------------------------------------------------------------
# Resolve OpenBLAS paths (installed via devpi)
# Note: devpi packages install to /usr/local/lib/ (not lib64/)
# -----------------------------------------------------------------------------
export OpenBLAS_HOME=/usr/local/lib/python3.12/site-packages/openblas
export OpenBLAS_DIR=${OpenBLAS_HOME}
export LD_LIBRARY_PATH=${OpenBLAS_HOME}/lib:${LD_LIBRARY_PATH}
export PKG_CONFIG_PATH="${OpenBLAS_HOME}/lib/pkgconfig:${PKG_CONFIG_PATH}"

# -----------------------------------------------------------------------------
# Clone opencv-python source
# -----------------------------------------------------------------------------
cd $CURRENT_DIR
git clone $PACKAGE_URL
cd $PACKAGE_DIR
git checkout $PACKAGE_VERSION
git submodule update --init --recursive

# -----------------------------------------------------------------------------
# Patch vsx_utils.hpp for ppc64le compatibility (OpenCV 4.13.0 specific)
# Fixes POWER10 intrinsic detection so it builds correctly on ppc64le
# -----------------------------------------------------------------------------
HEADER_FILE="$(pwd)/opencv/modules/core/include/opencv2/core/vsx_utils.hpp"
if [ -f "$HEADER_FILE" ]; then
    sed -i '261c\#if defined(__POWER10__) || (defined(__powerpc64__) && defined(__ARCH_PWR10__))' "$HEADER_FILE"
    echo "Patched vsx_utils.hpp line 261:"
    sed -n '261p' "$HEADER_FILE"
fi

export ENABLE_HEADLESS=1

# Let OpenCV build its own bundled protobuf (avoids header path issues with devpi)
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
                   -DBUILD_OPENEXR=1
                   -DBUILD_JASPER=0
                   -DWITH_ITT=1
                   -DBUILD_JPEG=0
                   -DBUILD_PROTOBUF=ON
                   -DBUILD_LIBPROTOBUF_FROM_SOURCES=ON
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
                   -DLAPACK_LAPACKE_H=$OpenBLAS_HOME/include/lapacke.h
                   -DLAPACK_CBLAS_H=$OpenBLAS_HOME/include/cblas.h"

# -----------------------------------------------------------------------------
# Install build dependencies (Python 3.12 requires setuptools < 70)
# -----------------------------------------------------------------------------
python3.12 -m pip install "setuptools<70.0.0"

# Set environment variables for build
export C_INCLUDE_PATH=$(python3.12 -c "import numpy; print(numpy.get_include())")
export CPLUS_INCLUDE_PATH=$C_INCLUDE_PATH
ln -sf $CURRENT_DIR/$PACKAGE_DIR/tests/SampleVideo_1280x720_1mb.mp4 SampleVideo_1280x720_1mb.mp4

# Build package
if ! python3.12 -m pip install . ; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# Build wheel
echo "---------------------------------------------------Building the wheel--------------------------------------------------"
python3.12 setup.py bdist_wheel --dist-dir $CURRENT_DIR

# Test package
#Skipping one test case because some of the coders and decoders are disabled while building ffmpeg and errors are faced because of that.
if ! (python3.12 -m pytest tests/test.py -k "not test_video_capture" -v) ; then
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

