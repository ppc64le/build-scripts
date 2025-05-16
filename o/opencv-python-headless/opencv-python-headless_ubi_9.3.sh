#!/bin/bash -e
#
# -----------------------------------------------------------------------------
#
# Package           : opencv-python-headless
# Version           : 4.11.0.86
# Source repo       : https://github.com/opencv/opencv-python
# Tested on         : UBI:9.3
# Language          : Python
# Travis-Check      : True
# Script License    : Apache License, Version 2.0
# Maintainer        : Vinod K <Vinod.K1@ibm.com>
#
# Disclaimer        : This script has been tested in root mode on given
# ==========          platform using the mentioned version of the package.
#                     It may not work as expected with newer versions of the
#                     package and/or distribution. In such case, please
#                     contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=opencv-python-headless
PACKAGE_VERSION=${1:-86}
PACKAGE_URL=https://github.com/opencv/opencv-python
CURRENT_DIR=$(pwd)
PACKAGE_DIR=opencv-python

yum install -y git make wget python3.12 python3.12-devel python3.12-pip pkgconfig atlas
yum install gcc-toolset-13 -y
yum install -y make libtool  xz zlib-devel openssl-devel bzip2-devel libffi-devel libevent-devel  patch ninja-build gcc-toolset-13  pkg-config  gmp-devel  freetype-devel

dnf install -y gcc-toolset-13-libatomic-devel
export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH

echo "------------Installing cmake---------------------------"

echo "Installing cmake..."
wget https://cmake.org/files/v3.31/cmake-3.31.0.tar.gz
tar -zxvf cmake-3.31.0.tar.gz
cd cmake-3.31.0
./bootstrap
make
make install
cd $CURRENT_DIR

echo "---------------------openblas installing---------------------"

git clone https://github.com/OpenMathLib/OpenBLAS
cd OpenBLAS
git checkout v0.3.29
git submodule update --init

# Set build options
declare -a build_opts
# Fix ctest not automatically discovering tests
LDFLAGS=$(echo "${LDFLAGS}" | sed "s/-Wl,--gc-sections//g")
export CF="${CFLAGS} -Wno-unused-parameter -Wno-old-style-declaration"
unset CFLAGS
export USE_OPENMP=1
build_opts+=(USE_OPENMP=${USE_OPENMP})
export PREFIX=${PREFIX}

# Handle Fortran flags
if [ ! -z "$FFLAGS" ]; then
    export FFLAGS="${FFLAGS/-fopenmp/ }"
    export FFLAGS="${FFLAGS} -frecursive"
    export LAPACK_FFLAGS="${FFLAGS}"
fi
export PLATFORM=$(uname -m)
build_opts+=(BINARY="64")
build_opts+=(DYNAMIC_ARCH=1)
build_opts+=(TARGET="POWER9")
BUILD_BFLOAT16=1

# Placeholder for future builds that may include ILP64 variants.
build_opts+=(INTERFACE64=0)
build_opts+=(SYMBOLSUFFIX="")

# Build LAPACK
build_opts+=(NO_LAPACK=0)

# Enable threading and set the number of threads
build_opts+=(USE_THREAD=1)
build_opts+=(NUM_THREADS=8)

# Disable CPU/memory affinity handling to avoid problems with NumPy and R
build_opts+=(NO_AFFINITY=1)

# Build OpenBLAS
make -j8 ${build_opts[@]} CFLAGS="${CF}" FFLAGS="${FFLAGS}" prefix=${PREFIX}

# Install OpenBLAS
CFLAGS="${CF}" FFLAGS="${FFLAGS}" make install PREFIX="${PREFIX}" ${build_opts[@]}
OpenBLASInstallPATH=$(pwd)/$PREFIX
OpenBLASConfigFile=$(find . -name OpenBLASConfig.cmake)
OpenBLASPCFile=$(find . -name openblas.pc)
export LD_LIBRARY_PATH="$OpenBLASInstallPATH/lib":${LD_LIBRARY_PATH}
export PKG_CONFIG_PATH="$OpenBLASInstallPATH/lib/pkgconfig:${PKG_CONFIG_PATH}"
export LD_LIBRARY_PATH=${PREFIX}/lib:$LD_LIBRARY_PATH
export PKG_CONFIG_PATH=${PREFIX}/lib/pkgconfig:$PKG_CONFIG_PATH
pkg-config --modversion openblas
cd $CURRENT_DIR

echo "--------------------scipy installing-------------------------------"

python3.12 -m pip install beniget==0.4.2.post1 Cython==3.0.11 gast==0.6.0 meson==1.6.0 meson-python==0.17.1 numpy==2.0.2 packaging pybind11 pyproject-metadata pythran==0.17.0 setuptools==75.3.0 pooch pytest build wheel hypothesis ninja patchelf
git clone https://github.com/scipy/scipy
cd scipy/
git checkout v1.15.2
git submodule update --init
echo "instaling scipy......."
python3.12 -m pip install .
cd $CURRENT_DIR

echo "--------------------abseil-cpp installing-------------------------------"

ABSEIL_VERSION=20240116.2
ABSEIL_URL="https://github.com/abseil/abseil-cpp"

git clone $ABSEIL_URL -b $ABSEIL_VERSION

echo "------------abseil-cpp cloned--------------"

export C_COMPILER=$(which gcc)
export CXX_COMPILER=$(which g++)

echo "----------------protobuf installing-------------------"
git clone https://github.com/protocolbuffers/protobuf
cd protobuf
git checkout v4.25.3

LIBPROTO_DIR=$(pwd)
mkdir -p $LIBPROTO_DIR/local/libprotobuf
LIBPROTO_INSTALL=$LIBPROTO_DIR/local/libprotobuf

git submodule update --init --recursive
rm -rf ./third_party/googletest | true
rm -rf ./third_party/abseil-cpp | true

cp -r $CURRENT_DIR/abseil-cpp ./third_party/

mkdir build
cd build

cmake -G "Ninja" \
   ${CMAKE_ARGS} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_STANDARD=17 \
    -DCMAKE_C_COMPILER=$C_COMPILER \
    -DCMAKE_CXX_COMPILER=$CXX_COMPILER \
    -DCMAKE_INSTALL_PREFIX=$LIBPROTO_INSTALL \
    -Dprotobuf_BUILD_TESTS=OFF \
    -Dprotobuf_BUILD_LIBUPB=OFF \
    -Dprotobuf_BUILD_SHARED_LIBS=ON \
    -Dprotobuf_ABSL_PROVIDER="module" \
    -Dprotobuf_JSONCPP_PROVIDER="package" \
    -Dprotobuf_USE_EXTERNAL_GTEST=OFF \
    ..
echo "building libprotobuf...."
cmake --build . --verbose
echo "Installing libprotobuf...."
cmake --install .

cd ..

#Build protobuf
export PROTOC=$LIBPROTO_DIR/build/protoc
export LD_LIBRARY_PATH=$CURRENT_DIR/abseil-cpp/abseilcpp/lib:$(pwd)/build/libprotobuf.so:$LD_LIBRARY_PATH
export LIBRARY_PATH=$(pwd)/build/libprotobuf.so:$LD_LIBRARY_PATH
export PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION=cpp
export PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION_VERSION=2

#Apply patch
wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/p/protobuf/set_cpp_to_17_v4.25.3.patch
git apply set_cpp_to_17_v4.25.3.patch

echo "--------------Installing protobuf--------------"
cd python
python3.12 -m pip install .
cd $CURRENT_DIR

echo "------------ libprotobuf,protobuf installed--------------"

echo "--------------------------------- Installing Opus ---------------------------------"

git clone https://github.com/xiph/opus
cd opus
git checkout v1.3.1

mkdir opus_prefix
export OPUS_PREFIX=$(pwd)/opus_prefix

if [[ $(uname) == MSYS* ]]; then
  if [[ ${ARCH} == 32 ]]; then
    HOST_BUILD="--host=i686-w64-mingw32 --build=i686-w64-mingw32"
  else
    HOST_BUILD="--host=x86_64-w64-mingw32 --build=x86_64-w64-mingw32"
  fi
  OPUS_PREFIX=${OPUS_PREFIX}/Library/mingw-w64
  JOBS=${NUMBER_OF_PROCESSORS}
elif [[ $(uname) == Darwin ]]; then
  JOBS=$(sysctl -n hw.ncpu)
else
  JOBS=$(grep -c ^processor /proc/cpuinfo 2>/dev/null || 1)
fi

./autogen.sh
./configure --prefix=$OPUS_PREFIX $HOST_BUILD && make -j$JOBS && make install

echo "--------------------------------- Opus Installed Successfully ---------------------------------"

cd $CURRENT_DIR

echo "--------------------------------- Installing libvpx ---------------------------------"

git clone https://github.com/webmproject/libvpx
cd libvpx
git checkout v1.13.1

mkdir libvpx_prefix
export LIBVPX_PREFIX=$(pwd)/libvpx_prefix

export target_platform=$(uname)-$(uname -m)
export GCC_HOME=/opt/rh/gcc-toolset-13/root/usr
export CC=$(which gcc)
export CXX=$(which g++)

# Get an updated config.sub and config.guess
#cp $BUILD_PREFIX/share/libtool/build-aux/config.* .


if [[ ${target_platform} == Linux-* ]]; then
    LDFLAGS="$LDFLAGS -pthread"
fi

CPU_DETECT="${CPU_DETECT} --enable-runtime-cpu-detect"

./configure --prefix=$LIBVPX_PREFIX $HOST_BUILD \
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
            ${CPU_DETECT} \
            --enable-experimental || { cat config.log; exit 1; }
make -j${CPU_COUNT}
make install

echo "--------------------------------- libvpx Installed Successfully ---------------------------------"

cd $CURRENT_DIR

echo "--------------------------------- Installing lame ---------------------------------"

wget https://downloads.sourceforge.net/sourceforge/lame/lame-3.100.tar.gz
tar -xvf lame-3.100.tar.gz
cd lame-3.100

mkdir lame_prefix
export LAME_PREFIX=$(pwd)/lame_prefix

export CPU_COUNT=$(nproc)

# Get an updated config.sub and config.guess
#cp -r ${BUILD_PREFIX}/share/libtool/build-aux/config.* .

# remove libtool files
find $LAME_PREFIX -name '*.la' -delete

./configure --prefix=$LAME_PREFIX \
            --disable-dependency-tracking \
            --disable-debug \
            --enable-shared \
            --enable-static \
            --enable-nasm

make -j$CPU_COUNT
make install

echo "--------------------------------- lame Installed Successfully ---------------------------------"

cd $CURRENT_DIR

#setting opus-prefix path on .pc file
cd opus/opus_prefix/
OPUS_PREFIX=$(pwd)
sed -i "/^prefix=/c\prefix=${OPUS_PREFIX}" $OPUS_PREFIX/lib/pkgconfig/opus.pc

cd $CURRENT_DIR

echo "--------------------Installing x264---------------------------------"
git clone https://code.videolan.org/videolan/x264.git
cd x264
./configure --prefix=/install-deps/x264 --enable-shared --enable-pic --disable-asm
make
make install
export PKG_CONFIG_PATH=/install-deps/x264/lib/pkgconfig:$PKG_CONFIG_PATH
export LD_LIBRARY_PATH=/install-deps/x264/lib:$LD_LIBRARY_PATH
export CFLAGS="-I/install-deps/x264/include $CFLAGS"
export LDFLAGS="-L/install-deps/x264/lib $LDFLAGS"
pkg-config --modversion x264
cd $CURRENT_DIR


echo "---------------------------Installing FFmpeg------------------"

git clone https://github.com/FFmpeg/FFmpeg
cd FFmpeg
git checkout n7.1
git submodule update --init

mkdir ffmpeg_prefix

export FFMPEG_PREFIX=$(pwd)/ffmpeg_prefix

unset SUBDIR

export CPU_COUNT=$(nproc)

export CC=`which gcc`

export PKG_CONFIG_PATH=/install-deps/x264/lib/pkgconfig:$CURRENT_DIR/opus/opus_prefix/lib/pkgconfig
export LD_LIBRARY_PATH=/install-deps/x264/lib:$LD_LIBRARY_PATH
export PATH=/install-deps/x264/bin:$PATH
USE_NONFREE=no   #the options below are set for NO

./configure \
        --prefix="$FFMPEG_PREFIX" \
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
        --enable-decoder=h264 \
        --disable-decoder=libh264 \
        --enable-decoder=libx264 \
        --disable-decoder=libopenh264 \
        --disable-encoder=libopenh264 \
        --enable-encoder=libx264 \
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
        --disable-nonfree --enable-gpl --disable-gnutls --enable-openssl --disable-libopenh264 --enable-libx264    #"${_CONFIG_OPTS[@]}"

make -j$CPU_COUNT
make install -j$CPU_COUNT
echo "--------------------------------- ffmpeg Installed successfully ---------------------------------"

cd $CURRENT_DIR
mkdir -p local/ffmpeg
cp -r FFmpeg/ffmpeg_prefix/* local/ffmpeg/

export LD_LIBRARY_PATH=${LAME_PREFIX}/lib:${LIBVPX_PREFIX}/lib:${OPUS_PREFIX}/lib:${FFMPEG_PREFIX}/lib:${LD_LIBRARY_PATH}

cd ${FFMPEG_PREFIX}/bin/ && ./ffmpeg --help
cd ${FFMPEG_PREFIX}/bin/ && ./ffmpeg -loglevel panic -protocols | grep "https"
cd ${FFMPEG_PREFIX}/bin/ && ./ffmpeg -loglevel panic -codecs | grep "libmp3lame"
cd ${FFMPEG_PREFIX}/bin/ && ./ffmpeg -loglevel panic -codecs | grep "DEVI.S zlib"
cd ${FFMPEG_PREFIX}/bin/ && ./ffmpeg -loglevel panic -codecs

cd ${FFMPEG_PREFIX}/bin/ && ./ffmpeg -encoders
cd ${FFMPEG_PREFIX}/bin/ && ./ffmpeg -decoders
cd ${FFMPEG_PREFIX}/bin/ && ./ffmpeg -codecs >$CURRENT_DIR/ffmpeg-codecs.txt

if grep '\(h264\|aac\|hevc\|mpeg4\).*coders:' $HOME/ffmpeg-codecs.txt ; then
  echo >&2 -e "\nError: Forbidden codecs in ffmpeg, see lines above.\n"
  problem=true
else
  echo -e "OK, ffmpeg has no forbidden codecs."
fi

ffmpeg_libs="avcodec
        avdevice
        swresample
        avfilter
        avcodec
        avformat
        swscale"
for each_ffmpeg_lib in $ffmpeg_libs; do
  test -f $FFMPEG_PREFIX/lib/lib$each_ffmpeg_lib.so
done

export PKG_CONFIG_PATH=${FFMPEG_PREFIX}/lib/pkgconfig:${PKG_CONFIG_PATH}
export LD_LIBRARY_PATH=${FFMPEG_PREFIX}/lib:${LD_LIBRARY_PATH}
export PATH="/install-deps/ffmpeg/bin:$PATH"

cd $CURRENT_DIR

echo "------------------Building opencv-python-headless-----------------------"
cd $CURRENT_DIR

git clone $PACKAGE_URL
cd $PACKAGE_DIR
git checkout $PACKAGE_VERSION
git submodule update --init --recursive

sed -i "s/^[[:space:]]*name=package_name/name=\"${PACKAGE_NAME}\"/" setup.py

export PROTOBUF_PREFIX=$CURRENT_DIR/protobuf/local/libprotobuf
export OPENBLAS_PREFIX=$CURRENT_DIR/OpenBLAS

# Adjust these paths so CMake can find headers and libraries
export CMAKE_PREFIX_PATH="$PROTOBUF_PREFIX:$OPENBLAS_PREFIX:$CMAKE_PREFIX_PATH"
export LD_LIBRARY_PATH=$PROTOBUF_PREFIX/lib64:$OPENBLAS_PREFIX:$LD_LIBRARY_PATH
export LIBRARY_PATH=$PROTOBUF_PREFIX/lib64:$OPENBLAS_PREFIX:$LIBRARY_PATH

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
                   -DWITH_FFMPEG=1
                   -DFFMPEG_DIR=$FFMPEG_PREFIX
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
                   -DPROTOBUF_UPDATE_FILES=ON
                   -DProtobuf_LIBRARY=$PROTOBUF_PREFIX/lib64/libprotobuf.so
                   -DProtobuf_INCLUDE_DIR=$PROTOBUF_PREFIX/include
                   -DWITH_LAPACK=0
                   -DHAVE_LAPACK=0
                   -DLAPACK_LAPACKE_H=$OPENBLAS_PREFIX/lapack-netlib/LAPACKE/include/lapacke.h
                   -DLAPACK_CBLAS_H=$OPENBLAS_PREFIX/cblas.h
                   -DENABLE_SSE=OFF \
                   -DENABLE_SSE2=OFF \
                   -DENABLE_SSE3=OFF \
                   -DENABLE_SSSE3=OFF \
                   -DENABLE_SSE41=OFF \
                   -DENABLE_SSE42=OFF \
                   -DENABLE_AVX=OFF \
                   -DENABLE_AVX2=OFF \
                   -DENABLE_NEON=OFF \
                   -DENABLE_VSX=OFF \
                   -DCPU_BASELINE_DISABLE=ON \
                   -DCPU_DISPATCH=OFF"

export C_INCLUDE_PATH=$(python3.12 -c "import numpy; print(numpy.get_include())")
export CPLUS_INCLUDE_PATH=$C_INCLUDE_PATH
ln -sf $CURRENT_DIR/opencv-python/tests/SampleVideo_1280x720_1mb.mp4 SampleVideo_1280x720_1mb.mp4

pip3.12 install numpy==2.0.2 pytest scikit-build setuptools build wheel

if ! pip3.12 install -e . ; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

#During wheel creation for this package we need exported cmake-args. Once script get exit, and if we build wheel through wrapper script, then those are not applicable during wheel creation. So we are generating wheel for opencv-python-headless in script itself.
echo "---------------------------------------------------Building the wheel--------------------------------------------------"
python3.12 setup.py bdist_wheel --dist-dir $CURRENT_DIR

echo "----------------------------------------------Testing pkg-------------------------------------------------------"

#Test package
if ! (python3.12 -m unittest discover -s tests) ; then
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