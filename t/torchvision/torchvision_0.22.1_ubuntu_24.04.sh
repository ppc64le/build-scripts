#!/bin/bash -e
#
# -----------------------------------------------------------------------------
#
# Package           : vision
# Version           : v0.22.1
# Source repo       : https://github.com/pytorch/vision.git
# Tested on         : ubuntu:24.04
# Language          : Python
# Ci-Check      : False
# Script License    : Apache License, Version 2.0
# Maintainer        : Prerna Kumbhar <Prerna.Kumbhar@ibm.com>
#
# Disclaimer        : This script has been tested in root mode on given
# ==========          platform using the mentioned version of the package.
#                     It may not work as expected with newer versions of the
#                     package and/or distribution. In such case, please
#                     contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -ex
export DEBIAN_FRONTEND=noninteractive
export PIP_BREAK_SYSTEM_PACKAGES=1
PACKAGE_NAME=vision
PACKAGE_VERSION=${1:-v0.22.1}
PACKAGE_URL=https://github.com/pytorch/vision.git
OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)
MAX_JOBS=${MAX_JOBS:-$(nproc)}
VERSION=${PACKAGE_VERSION#v}
PYTORCH_VERSION=${2:-v2.9.0}
CURRENT_DIR=/opt

apt update -y && apt install -y curl git wget python3-dev python3-pip pkg-config gfortran ninja-build build-essential libblas-dev liblapack-dev patchelf  libopenblas-dev autoconf  autoconf automake libtool libgmp-dev libssl-dev libjpeg-dev libfreetype6-dev protobuf-compiler libprotobuf-dev libmp3lame-dev libjpeg62
pip install cmake 

echo "---------------------openblas installing---------------------"
#install openblas
#clone and install openblas from source
cd $CURRENT_DIR
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

#Building scipy
python3 -m pip install beniget==0.4.2.post1 Cython gast==0.6.0 meson==1.6.0 meson-python==0.17.1 numpy==2.0.2 packaging pybind11 pyproject-metadata pythran==0.17.0 setuptools==75.3.0 pooch pytest build wheel hypothesis ninja patchelf 
git clone https://github.com/scipy/scipy
cd scipy/
git checkout v1.15.2
git submodule update --init
echo "instaling scipy......."
apt install -y gfortran
python3 -m pip install .
cd $CURRENT_DIR

echo "--------------------abseil-cpp installing-------------------------------"

#cloning abseil-cpp
ABSEIL_VERSION=20240116.2
ABSEIL_URL="https://github.com/abseil/abseil-cpp"

git clone $ABSEIL_URL -b $ABSEIL_VERSION

echo "------------abseil-cpp cloned--------------"

#building libprotobuf
export C_COMPILER=$(which gcc)
export CXX_COMPILER=$(which g++)

echo "----------------protobuf installing-------------------"
git clone https://github.com/protocolbuffers/protobuf
cd protobuf
git checkout v4.25.8

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
# Build protobuf python bindings
export PROTOC=$LIBPROTO_DIR/build/protoc
export LD_LIBRARY_PATH=$LIBPROTO_INSTALL/lib:$LD_LIBRARY_PATH
export LIBRARY_PATH=$LIBPROTO_INSTALL/lib:$LIBRARY_PATH
export PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION=cpp
export PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION_VERSION=2

wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/p/protobuf/set_cpp_to_17_v4.25.3.patch
git apply set_cpp_to_17_v4.25.3.patch

echo "Installing protobuf...."
cd python
python3 -m pip install .
cd $CURRENT_DIR


echo "------------ libprotobuf,protobuf installed--------------"

echo "----Installing rust------"
curl https://sh.rustup.rs -sSf | sh -s -- -y
source "$HOME/.cargo/env"
mkdir pytorch
cd pytorch
PYTORCH_DIR=/opt/pytorch
echo "--------------------------Installing pytorch------------------------------------------"
cd $PYTORCH_DIR
git clone https://github.com/pytorch/pytorch.git
cd pytorch
git checkout $PYTORCH_VERSION
git submodule sync
git submodule update --init --recursive

ARCH=$(uname -p)
BUILD_NUM="1"
# Optional overrides for tuning
export CPU_COUNT=$(nproc)
export CXXFLAGS="${CXXFLAGS} -D__STDC_FORMAT_MACROS"
export LDFLAGS="${LDFLAGS} -Wl,-rpath-link,${VIRTUAL_ENV}/lib"
export USE_FBGEMM=0
export BLAS=OpenBLAS
export USE_OPENMP=1
export USE_NINJA=1
export USE_SYSTEM_NCCL=1
export USE_MKLDNN=0
export USE_NNPACK=0
export USE_QNNPACK=0
export USE_XNNPACK=0
export USE_PYTORCH_QNNPACK=0
export USE_MPI=0
export USE_TBB=0
export BUILD_CUSTOM_PROTOBUF=OFF
export BUILD_CAFFE2=1
export PYTORCH_BUILD_VERSION=${PYTORCH_VERSION#v}
export PYTORCH_BUILD_NUMBER=${BUILD_NUM}
export USE_CUDA=0
export USE_CUDNN=0
export USE_TENSORRT=0
export Protobuf_INCLUDE_DIR=${LIBPROTO_INSTALL}/include
export Protobuf_LIBRARIES=${LIBPROTO_INSTALL}/lib
export Protobuf_LIBRARY=${LIBPROTO_INSTALL}/lib/libprotobuf.so
export Protobuf_LITE_LIBRARY=${LIBPROTO_INSTALL}/lib/libprotobuf-lite.so
export Protobuf_PROTOC_EXECUTABLE=${LIBPROTO_INSTALL}/bin/protoc
export LD_LIBRARY_PATH="/opt/protobuf/local/libprotobuf/lib:${LD_LIBRARY_PATH}"
export LD_LIBRARY_PATH="${LIBPROTO_INSTALL}/lib:$LD_LIBRARY_PATH"
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/opt/protobuf/third_party/abseil-cpp/local/abseilcpp/lib"
export CXXFLAGS="${CXXFLAGS} -fplt"
export CFLAGS="${CFLAGS} -fplt"

python3 -m pip install -r requirements.txt 
MAX_JOBS=$(nproc) python3 setup.py install
MAX_JOBS=$(nproc) python3 setup.py bdist_wheel --dist-dir $CURRENT_DIR
cd $CURRENT_DIR

echo "--------------------------------- Installing Opus ---------------------------------"

git clone https://github.com/xiph/opus
cd opus
git checkout v1.3.1
mkdir opus_prefix
export OPUS_PREFIX=$(pwd)/opus_prefix
JOBS=$(nproc)
./autogen.sh
./configure --prefix=$OPUS_PREFIX && make -j$JOBS && make install
make check
echo "--------------------------------- Opus Installed Successfully ---------------------------------"

cd $CURRENT_DIR
echo "--------------------------------- Installing libvpx ---------------------------------"

git clone https://github.com/webmproject/libvpx
cd libvpx
git checkout v1.13.1

mkdir libvpx_prefix
export LIBVPX_PREFIX=$(pwd)/libvpx_prefix
export CC=$(which gcc)
export CXX=$(which g++)
export LDFLAGS="$LDFLAGS -pthread"
CPU_DETECT="--enable-runtime-cpu-detect"

./configure --prefix="$LIBVPX_PREFIX" \
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
            $CPU_DETECT || { cat config.log; exit 1; }

make -j"$(nproc)"
make install
echo "--------------------------------- libvpx Installed Successfully ---------------------------------"

cd $CURRENT_DIR

# Clone the libvpx package
echo "--------------------------------- Installing lame ---------------------------------"
wget https://downloads.sourceforge.net/sourceforge/lame/lame-3.100.tar.gz
tar -xvf lame-3.100.tar.gz
cd lame-3.100
# Create install prefix directory
mkdir lame_prefix
export LAME_PREFIX=$(pwd)/lame_prefix
export CPU_COUNT=$(nproc)
# Configure the build
./configure --prefix=$LAME_PREFIX \
            --disable-dependency-tracking \
            --disable-debug \
            --enable-shared \
            --enable-static \
            --enable-nasm
#Build and install
make -j$CPU_COUNT
make install
echo "--------------------------------- lame Installed Successfully ---------------------------------"

cd $CURRENT_DIR
export OPUS_PREFIX="$CURRENT_DIR/opus/opus_prefix"
export LAME_PREFIX="$CURRENT_DIR/lame-3.100/lame_prefix"
export LIBVPX_PREFIX="$CURRENT_DIR/libvpx/libvpx_prefix"
cd "$OPUS_PREFIX"
sed -i "/^prefix=/c\prefix=${OPUS_PREFIX}" "$OPUS_PREFIX/lib/pkgconfig/opus.pc"
cd "$CURRENT_DIR"

echo "---------------------------Installing FFmpeg------------------"
#Cloning Source Code
FFMPEG_PACKAGE_VERSION=${3:-n7.1}

git clone https://github.com/FFmpeg/FFmpeg
cd FFmpeg
git checkout $FFMPEG_PACKAGE_VERSION
git submodule update --init
mkdir ffmpeg_prefix
export FFMPEG_PREFIX=$(pwd)/ffmpeg_prefix
export CPU_COUNT=$(nproc)
export CC=$(which gcc)
export PKG_CONFIG_PATH="$OPUS_PREFIX/lib/pkgconfig:$LAME_PREFIX/lib/pkgconfig:$LIBVPX_PREFIX/lib/pkgconfig"
export FFMPEG_PREFIX=$(pwd)/ffmpeg_prefix
export CPU_COUNT=$(nproc)
export CC=$(which gcc)
export PKG_CONFIG_PATH=$CURRENT_DIR/opus/opus_prefix/lib/pkgconfig:$PKG_CONFIG_PATH
export PKG_CONFIG_PATH=$CURRENT_DIR/libvpx/libvpx_prefix/lib/pkgconfig:$PKG_CONFIG_PATH
export PKG_CONFIG_PATH=$CURRENT_DIR/lame-3.100/lame_prefix/lib/pkgconfig:$PKG_CONFIG_PATH
./configure --prefix="$FFMPEG_PREFIX" \
            --cc=${CC} \
            --disable-doc \
            --enable-gmp \
            --enable-hardcoded-tables \
            --enable-libfreetype \
            --enable-pthreads \
            --enable-postproc \
            --enable-pic \
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
	        --disable-decoder=hevc  \
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
            --disable-decoder=mpeg1_v4l2m2m  \
            --disable-decoder=mpeg2video \
            --disable-decoder=mpeg2_v4l2m2m \
            --disable-decoder=mpeg4 \
            --disable-decoder=msmpeg4 \
            --disable-decoder=mpeg4_v4l2m2m \
            --disable-decoder=msmpeg4v1 \
            --disable-decoder=msmpeg4v2 \
            --disable-decoder=msmpeg4v3  \
            --disable-encoder=h264_v4l2m2m \
            --disable-decoder=h264_v4l2m2m \
            --disable-encoder=hevc_v4l2m2m \
            --disable-decoder=hevc_v4l2m2m  \
            --disable-nonfree \
            --disable-gpl \
            --disable-gnutls \
            --enable-openssl \
            --disable-libopenh264 \
            --disable-libx264
make -j$CPU_COUNT
make install -j$CPU_COUNT
cd "$CURRENT_DIR"
mkdir -p local/ffmpeg
cp -r FFmpeg/ffmpeg_prefix/* local/ffmpeg/
FFMPEG_PACKAGE_VERSION=$(echo "$FFMPEG_PACKAGE_VERSION" | sed 's/[^0-9.]//g')
# Set library paths
export LD_LIBRARY_PATH="$LAME_PREFIX/lib:$LIBVPX_PREFIX/lib:$OPUS_PREFIX/lib:$FFMPEG_PREFIX/lib:$LD_LIBRARY_PATH"

echo "------------------------------------------- FFmpeg Validation -------------------------------------------"
cd "$FFMPEG_PREFIX/bin"
# Basic help output as a quick sanity check
./ffmpeg --help
# Check for protocol support (e.g., HTTPS)
./ffmpeg -loglevel panic -protocols | grep https || echo "https not supported"
# Confirm MP3 support
./ffmpeg -loglevel panic -codecs | grep libmp3lame || echo "libmp3lame not available"
 # Check for zlib support
./ffmpeg -loglevel panic -codecs | grep DEVI.S\ zlib || echo "zlib codec absent"
# List codecs
./ffmpeg -loglevel panic -codecs | tee "$CURRENT_DIR/ffmpeg-codecs.txt"
# Make sure forbidden codecs like h264, aac, hevc, mpeg4 are disabled
if grep -E '(h264|aac|hevc|mpeg4).*coders:' "$CURRENT_DIR/ffmpeg-codecs.txt"; then   >&2 echo -e "\nError: Forbidden codecs detected. Check above.\n";   problem=true; else   echo "OK, no forbidden codecs detected."; fi
# Ensure shared libraries exist for key FFmpeg components
for lib in avcodec avdevice swresample avfilter avformat swscale; do   test -f "$FFMPEG_PREFIX/lib/lib${lib}.so" || echo "Missing library: lib${lib}.so"; done
# Set up environment for future usage
export PKG_CONFIG_PATH="$FFMPEG_PREFIX/lib/pkgconfig:$PKG_CONFIG_PATH"
export LD_LIBRARY_PATH="$FFMPEG_PREFIX/lib:$LD_LIBRARY_PATH"
export PATH="$FFMPEG_PREFIX/bin:$PATH"

cd "$CURRENT_DIR"

echo "--------------------------Installing pillow-----------------------------"
git clone https://github.com/python-pillow/Pillow
cd Pillow
git checkout 11.1.0
# Install dependencies on Ubuntu
git submodule update --init
python3 -m pip install .
cd $CURRENT_DIR

echo "--------------------Installing pyav----------------------------"
git clone https://github.com/PyAV-Org/PyAV
cd PyAV
# This command prints both versions, one per line, then sorts them using version-aware sort (-V)
# The smallest version will appear first
# If the smallest version is not 0.22.0, then VERSION must be less than 0.22.0

if [ "$(printf '%s\n' "$VERSION" "0.22.0" | sort -V | head -n1)" != "0.22.0" ]; then
    # VERSION is less than 0.22.0
    git checkout v13.1.0
else
    # VERSION is greater than or equal to 0.22.0
    # This PyAV version must match the runtime PyAV version.
    git checkout v14.4.0
    sed -i 's/license = "BSD-3-Clause"/license = {text = "BSD-3-Clause"}/' pyproject.toml
fi
git submodule update --init
export CFLAGS="${CFLAGS} -I/usr/include"
export LDFLAGS="${LDFLAGS} -L/usr/lib"
python3 setup.py build_ext --inplace
cd $CURRENT_DIR

echo "------------------Building torchvision------------------------"
cd $PYTORCH_DIR
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/t/torchvision/0001-Exclude-source-that-has-commercial-license_${PACKAGE_VERSION}.patch
# Below patch is needed to exclude the models that come under SWAG license (CC-BY-NC-4.0)
git apply ./0001-Exclude-source-that-has-commercial-license_${PACKAGE_VERSION}.patch
sed -i '/elif sha != "Unknown":/,+1d' setup.py

if ! python3 setup.py bdist_wheel --dist-dir $CURRENT_DIR; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
    exit 1
fi

cd $PYTORCH_DIR

cd vision
cd build
export CMAKE_PREFIX_PATH=/usr/local/lib/python3.12/dist-packages/torch/share/cmake/Torch:$LIBPROTO_INSTALL
cmake ..
make install
cp libtorchvision.so /usr/local/lib/python3.12/dist-packages/torch/share/cmake/Torch
cp libtorchvision.so /usr/local/lib
ln -s /usr/local/lib/libtorchvision.so /usr/local/lib/python3.12/dist-packages/torch/lib/libtorchvision.so.1
ln -s /usr/local/lib/libtorchvision.so /usr/local/lib/libtorchvision.so.1
cp /usr/lib/powerpc64le-linux-gnu/libjpeg.so.62 /usr/local/lib/
cd $CURRENT_DIR

python3 -m pip install ./torchvision*.whl 

python3 -m pip install pytest pytest-xdist 

if ! pytest $PYTORCH_DIR/$PACKAGE_NAME/test/common_extended_utils.py $PYTORCH_DIR/$PACKAGE_NAME/test/common_utils.py $PYTORCH_DIR/$PACKAGE_NAME/test/smoke_test.py $PYTORCH_DIR/$PACKAGE_NAME/test/test_architecture_ops.py $PYTORCH_DIR/$PACKAGE_NAME/test/test_datasets_video_utils_opt.py ; then
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


