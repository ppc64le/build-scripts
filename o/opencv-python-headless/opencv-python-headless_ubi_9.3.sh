#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : opencv-python-headless
# Version       : 4.11.0.86
# Source repo   : https://github.com/opencv/opencv-python.git
# Tested on     : UBI:9.3
# Language      : Python
# Travis-Check  : True
# Script License: Apache License 2.0
# Maintainer    : Vinod K <Vinod.K1@ibm.com>
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
PACKAGE_VERSION=${1:-86}
PACKAGE_URL=https://github.com/opencv/opencv-python
CURRENT_DIR=$(pwd)
PACKAGE_DIR=opencv-python

# Install core dependencies
yum install -y wget gcc-toolset-13 gcc-toolset-13-gcc gcc-toolset-13-gcc-c++ \
    gcc-toolset-13-gcc-gfortran gcc-toolset-13-binutils gcc-toolset-13-binutils-devel \
    python python-pip python-devel git ninja-build make cmake pkgconfig autoconf \
    automake libtool zlib-devel freetype-devel gmp-devel openssl openssl-devel

export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

INSTALL_ROOT="/install-deps"
mkdir -p $INSTALL_ROOT

for package in openblas lame opus libvpx ffmpeg libprotobuf protobuf abseilcpp; do
    mkdir -p ${INSTALL_ROOT}/${package}
    export "${package^^}_PREFIX=${INSTALL_ROOT}/${package}"
    echo "Exported ${package^^}_PREFIX=${INSTALL_ROOT}/${package}"
done

# Install OpenBLAS
cd $CURRENT_DIR
git clone https://github.com/OpenMathLib/OpenBLAS
cd OpenBLAS
git checkout v0.3.29
git submodule update --init

# Set build options
declare -a build_opts
LDFLAGS=$(echo "${LDFLAGS}" | sed "s/-Wl,--gc-sections//g")
export CF="${CFLAGS} -Wno-unused-parameter -Wno-old-style-declaration"
unset CFLAGS
export USE_OPENMP=1
build_opts+=(USE_OPENMP=${USE_OPENMP})

if [ ! -z "$FFLAGS" ]; then
    export FFLAGS="${FFLAGS/-fopenmp/ }"
    export FFLAGS="${FFLAGS} -frecursive"
    export LAPACK_FFLAGS="${FFLAGS}"
fi

build_opts+=(BINARY="64")
build_opts+=(DYNAMIC_ARCH=1)
build_opts+=(TARGET="POWER9")
BUILD_BFLOAT16=1
build_opts+=(INTERFACE64=0)
build_opts+=(SYMBOLSUFFIX="")
build_opts+=(NO_LAPACK=0)
build_opts+=(USE_THREAD=1)
build_opts+=(NUM_THREADS=8)
build_opts+=(NO_AFFINITY=1)

make ${build_opts[@]} CFLAGS="${CF}" FFLAGS="${FFLAGS}" prefix=${OPENBLAS_PREFIX}
CFLAGS="${CF}" FFLAGS="${FFLAGS}" make install PREFIX="${OPENBLAS_PREFIX}" ${build_opts[@]}
export LD_LIBRARY_PATH=${OPENBLAS_PREFIX}/lib:$LD_LIBRARY_PATH
export PKG_CONFIG_PATH=${OPENBLAS_PREFIX}/lib/pkgconfig:$PKG_CONFIG_PATH
echo "-----------------------------------------------------Installed openblas-----------------------------------------------------"

echo "-----------------------------------------------------Installed openblas-----------------------------------------------------"


#installing abseil-cpp
cd $CURRENT_DIR
git clone https://github.com/abseil/abseil-cpp -b 20240116.2

export C_COMPILER=$(which gcc)
export CXX_COMPILER=$(which g++)

#installing libprotobuf
cd $CURRENT_DIR
git clone https://github.com/protocolbuffers/protobuf -b v4.25.3
cd protobuf
git submodule update --init --recursive
#Create build directory
mkdir build
cd build
cmake -G "Ninja" \
   ${CMAKE_ARGS} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_STANDARD=17 \
    -DCMAKE_C_COMPILER=$C_COMPILER \
    -DCMAKE_CXX_COMPILER=$CXX_COMPILER \
    -DCMAKE_INSTALL_PREFIX=${LIBPROTOBUF_PREFIX} \
    -Dprotobuf_BUILD_TESTS=OFF \
    -Dprotobuf_BUILD_LIBUPB=OFF \
    -Dprotobuf_BUILD_SHARED_LIBS=ON \
    -Dprotobuf_ABSL_PROVIDER="module" \
    -DCMAKE_PREFIX_PATH=${ABSEILCPP_PREFIX} \
    -Dprotobuf_JSONCPP_PROVIDER="package" \
    -Dprotobuf_USE_EXTERNAL_GTEST=OFF \
    ..
cmake --build . --verbose
cmake --install .
echo "-----------------------------------------------------Installed libprotobuf-----------------------------------------------------"
cd ..

#setting required paths
export PROTOC="$LIBPROTOBUF_PREFIX/bin/protoc"
export LD_LIBRARY_PATH="$ABSEILCPP_PREFIX/lib:$LIBPROTOBUF_PREFIX/lib64:$LD_LIBRARY_PATH"
export LIBRARY_PATH="$LIBPROTOBUF_PREFIX/lib64:$LD_LIBRARY_PATH"
export PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION=cpp
export PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION_VERSION=2

# Apply patch
wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/p/protobuf/set_cpp_to_17_v4.25.3.patch
git apply set_cpp_to_17_v4.25.3.patch

#installing protobuf
cd python
python setup.py install --cpp_implementation
echo "-----------------------------------------------------Installed protobuf-----------------------------------------------------"


# Install Python dependencies
python -m pip install --upgrade pip
python -m pip install numpy==2.0.2 cython pytest

# Install libvpx
cd $CURRENT_DIR
git clone https://github.com/webmproject/libvpx.git
cd libvpx
git checkout v1.13.1
export target_platform=$(uname)-$(uname -m)
if [[ ${target_platform} == Linux-* ]]; then
    LDFLAGS="$LDFLAGS -pthread"
fi

./configure --prefix=$LIBVPX_PREFIX \
    --as=yasm \
    --enable-shared \
    --disable-static \
    --disable-install-docs \
    --disable-install-srcs \
    --enable-vp8 \
    --enable-postproc \
    --enable-vp9 \
    --enable-vp9-highbitdepth \
    --enable-pic \
    --enable-runtime-cpu-detect \
    --enable-experimental || { cat config.log; exit 1; }

make
make install PREFIX="${LIBVPX_PREFIX}"
export LD_LIBRARY_PATH=${LIBVPX_PREFIX}/lib:$LD_LIBRARY_PATH
export PKG_CONFIG_PATH=${LIBVPX_PREFIX}/lib/pkgconfig:$PKG_CONFIG_PATH
echo "-----------------------------------------------------Installed libvpx------------------------------------------------"

# Install lame
cd $CURRENT_DIR
wget https://downloads.sourceforge.net/sourceforge/lame/lame-3.100.tar.gz
tar -xvf lame-3.100.tar.gz
cd lame-3.100
find $LAME_PREFIX -name '*.la' -delete

./configure --prefix=$LAME_PREFIX \
            --disable-dependency-tracking \
            --disable-debug \
            --enable-shared \
            --enable-static \
            --enable-nasm

make
make install PREFIX="${LAME_PREFIX}"
export LD_LIBRARY_PATH=/install-deps/lame/lib:$LD_LIBRARY_PATH
export PATH="/install-deps/lame/bin:$PATH"
echo "-----------------------------------------------------Installed lame------------------------------------------------"

# Install opus
cd $CURRENT_DIR
git clone https://github.com/xiph/opus
cd opus
git checkout v1.3.1
./autogen.sh
./configure --prefix=$OPUS_PREFIX
make
make install PREFIX="${OPUS_PREFIX}"
export LD_LIBRARY_PATH=${OPUS_PREFIX}/lib:$LD_LIBRARY_PATH
export PKG_CONFIG_PATH=${OPUS_PREFIX}/lib/pkgconfig:$PKG_CONFIG_PATH
echo "-----------------------------------------------------Installed opus------------------------------------------------"

# Install ffmpeg
cd $CURRENT_DIR

git clone https://github.com/FFmpeg/FFmpeg
cd FFmpeg
git checkout n7.1
git submodule update --init

mkdir prefix

export PREFIX=$(pwd)/prefix

unset SUBDIR

export CPU_COUNT=$(nproc)

export CC=`which gcc`

export PKG_CONFIG_PATH=$OPUS_PREFIX/lib/pkgconfig:$LAME_PREFIX/lib/pkgconfig:$LIBVPX_PREFIX/lib/pkgconfig:$PKG_CONFIG_PATH

./configure \
        --prefix="$PREFIX" \
        --cc=${CC} \
        --disable-doc \
        --enable-gmp \
        --enable-hardcoded-tables \
        --enable-libfreetype \
        --enable-pthreads \
        --enable-postproc \
        --enable-pic \
        --enable-pthreads \
        --enable-shared \
        --enable-static \
        --enable-version3 \
        --enable-zlib \
        --enable-libopus \
        --enable-libmp3lame \
        --enable-libvpx \
        --extra-cflags="-I$LAME_PREFIX/include -I$OPUS_PREFIX/include -I$LIBVPX_PREFIX/include" \
        --extra-ldflags="-L$LAME_PREFIX/lib -L$OPUS_PREFIX/lib -L$LIBVPX_PREFIX/lib" \
        --disable-encoder=h264 \
        --disable-decoder=h264 \
        --disable-decoder=libh264 \
        --disable-decoder=libx264 \
        --disable-decoder=libopenh264 \
        --disable-encoder=libopenh264 \
        --disable-encoder=libx264 \
        --disable-decoder=libx264rgb \
        --disable-encoder=libx264rgb \
        --disable-encoder=hevc \
        --disable-decoder=hevc \
        --disable-encoder=aac \
        --disable-decoder=aac \
        --disable-decoder=aac_fixed \
        --disable-encoder=aac_latm \
        --disable-decoder=aac_latm \
        --disable-encoder=mpeg \
        --disable-encoder=mpeg1video \
        --disable-encoder=mpeg2video \
        --disable-encoder=mpeg4 \
        --disable-encoder=msmpeg4 \
        --disable-encoder=mpeg4_v4l2m2m \
        --disable-encoder=msmpeg4v2 \
        --disable-encoder=msmpeg4v3 \
        --disable-decoder=mpeg \
        --disable-decoder=mpegvideo \
        --disable-decoder=mpeg1video \
        --disable-decoder=mpeg1_v4l2m2m \
        --disable-decoder=mpeg2video \
        --disable-decoder=mpeg2_v4l2m2m \
        --disable-decoder=mpeg4 \
        --disable-decoder=msmpeg4 \
        --disable-decoder=mpeg4_v4l2m2m \
        --disable-decoder=msmpeg4v1 \
        --disable-decoder=msmpeg4v2 \
        --disable-decoder=msmpeg4v3 \
        --disable-encoder=h264_v4l2m2m \
        --disable-decoder=h264_v4l2m2m \
        --disable-encoder=hevc_v4l2m2m \
        --disable-decoder=hevc_v4l2m2m \
        --disable-nonfree --disable-gpl --disable-gnutls --enable-openssl --disable-libopenh264 --disable-libx264    #"${_CONFIG_OPTS[@]}"

make -j$CPU_COUNT
make install -j$CPU_COUNT
echo "--------------------------------- ffmpeg Installed successfully ---------------------------------"

export PKG_CONFIG_PATH=${FFMPEG_PREFIX}/lib/pkgconfig:${PKG_CONFIG_PATH}
export LD_LIBRARY_PATH=${FFMPEG_PREFIX}/lib:${LD_LIBRARY_PATH}
export PATH="/install-deps/ffmpeg/bin:$PATH"

echo "-----------------------------------------------------Installed ffmpeg------------------------------------------------"

# Clone source repository
cd $CURRENT_DIR
git clone $PACKAGE_URL
cd $PACKAGE_DIR
git checkout $PACKAGE_VERSION
git submodule update --init --recursive

sed -i "s/^[[:space:]]*name=package_name/name=\"${PACKAGE_NAME}\"/" setup.py

export CMAKE_PREFIX_PATH="$ABSEILCPP_PREFIX;$LIBPROTOBUF_PREFIX"
export CMAKE_ARGS="-DCMAKE_BUILD_TYPE=Release
                   -DCMAKE_PREFIX_PATH=$CMAKE_PREFIX_PATH
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
                   -DBUILD_LIBPROTOBUF_FROM_SOURCES=OFF
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
                   -DBUILD_PROTOBUF=OFF
                   -DENABLE_VSX=OFF
                   -DCV_ENABLE_INTRINSICS=OFF
                   -DPROTOBUF_UPDATE_FILES=ON
                   -DProtobuf_LIBRARY=$LIBPROTOBUF_PREFIX/lib64/libprotobuf.so
                   -DProtobuf_INCLUDE_DIR=$LIBPROTOBUF_PREFIX/include/google/protobuf
                   -DWITH_LAPACK=0
                   -DHAVE_LAPACK=0
                   -DLAPACK_LAPACKE_H=$OPENBLAS_PREFIX/include/lapacke.h
                   -DLAPACK_CBLAS_H=$OPENBLAS_PREFIX/include/cblas.h"

# Install build dependencies
PYTHON_VERSION=$(python -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
if [[ "$PYTHON_VERSION" == "3.12" ]]; then
    pip install "setuptools<70.0.0"
else
    pip install "setuptools==59.2.0"
fi

pip install scikit-build build wheel

# Set environment variables for build
export PATH=${LIBPROTOBUF_PREFIX}/bin:$PATH
export C_INCLUDE_PATH=$(python -c "import numpy; print(numpy.get_include())")
export CPLUS_INCLUDE_PATH=$C_INCLUDE_PATH
export CPLUS_INCLUDE_PATH=${LIBPROTOBUF_PREFIX}/include:$CPLUS_INCLUDE_PATH
ln -sf $CURRENT_DIR/opencv-python/tests/SampleVideo_1280x720_1mb.mp4 SampleVideo_1280x720_1mb.mp4

# Build package
if ! pip install -e . ; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# Build wheel
echo "---------------------------------------------------Building the wheel--------------------------------------------------"
python setup.py bdist_wheel --dist-dir $CURRENT_DIR

# Test package
#Skipping one test case because some of the coders and decoders are disabled while building ffmpeg and errors are faced because of that.
if ! (pytest tests/test.py -k "not test_video_capture" -v) ; then
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
