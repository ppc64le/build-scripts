#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : vllm
# Version       : v0.10.0
# Source repo   : https://github.com/vllm-project/vllm
# Tested on     : UBI:9.3
# Language      : C
# Travis-Check  : True
# Script License: Apache License 2.0
# Maintainer    : 
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#set -e 

PACKAGE_NAME=vllm
PACKAGE_VERSION=${1:-v0.10.0}
PACKAGE_URL=https://github.com/vllm-project/vllm.git
CURRENT_DIR=$(pwd)
PACKAGE_DIR=vllm

yum install -y openblas-devel git make libtool wget gcc-toolset-13 cmake python3.12 python3.12-devel python3.12-pip gcc-toolset-13 gcc-toolset-13-binutils gcc-toolset-13-binutils-devel gcc-toolset-13-gcc-c++ binutils meson ninja-build openssl-devel libjpeg-devel bzip2-devel libffi-devel zlib-devel libtiff-devel freetype-devel  autoconf procps-ng glibc-static libstdc++-static kmod automake gmp-devel gmp-devel.ppc64le libjpeg-turbo-devel mpfr-devel.ppc64le libmpc-devel.ppc64le java-11-openjdk java-11-openjdk-devel gzip tar xz yum-utils bzip2 zip unzip cargo pkgconf-pkg-config.ppc64le info.ppc64le fontconfig.ppc64le fontconfig-devel.ppc64le sqlite-devel gcc-toolset-13-gcc-gfortran pkgconfig atlas libevent-devel patch pkg-config llvm-devel clang clang-devel


export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH
gcc --version

export GCC_HOME=/opt/rh/gcc-toolset-13/root/usr
export CC=$GCC_HOME/bin/gcc
export CXX=$GCC_HOME/bin/g++

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)
python3.12 -m pip install --upgrade pip build

INSTALL_ROOT="/install-deps"
mkdir -p $INSTALL_ROOT
for package in openblas lame opus libvpx ffmpeg hdf5 x264; do
    mkdir -p ${INSTALL_ROOT}/${package}
    export "${package^^}_PREFIX=${INSTALL_ROOT}/${package}"
    echo "Exported ${package^^}_PREFIX=${INSTALL_ROOT}/${package}"
done

python3.12 -m pip install numpy==2.0.2 cython  bottleneck==1.4.2 brotli==1.1.0 pyyaml==6.0.2 aiohttp==3.9.0 argon2_cffi_bindings==21.2.0
python3.12 -m pip install cassandra_driver==3.29.2 contourpy==1.3.1 cx_oracle==8.3.0 cytoolz==1.0.1 ibm_db==3.2.6 ijson==3.3.0 jenkspy==0.4.1 markupsafe==3.0.2
python3.12 -m pip install zstd==1.5.6.1 yarl==1.18.3 unicodedata2==15.1.0 pandas==2.2.3 ninja

#installing openblas  
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
make ${build_opts[@]} CFLAGS="${CF}" FFLAGS="${FFLAGS}" prefix=${OPENBLAS_PREFIX}
# Install OpenBLAS
CFLAGS="${CF}" FFLAGS="${FFLAGS}" make install PREFIX="${OPENBLAS_PREFIX}" ${build_opts[@]}
export LD_LIBRARY_PATH=${OPENBLAS_PREFIX}/lib:$LD_LIBRARY_PATH
export PKG_CONFIG_PATH=${OPENBLAS_PREFIX}/lib/pkgconfig:$PKG_CONFIG_PATH
pkg-config --modversion openblas
echo "-----------------------------------------------------Installed openblas-----------------------------------------------------"

#installing lame
cd $CURRENT_DIR
wget https://downloads.sourceforge.net/sourceforge/lame/lame-3.100.tar.gz
tar -xvf lame-3.100.tar.gz
cd lame-3.100
# remove libtool files
find $LAME_PREFIX -name '*.la' -delete

./configure --prefix=$LAME_PREFIX \
            --disable-dependency-tracking \
            --disable-debug \
            --enable-shared \
            --enable-static \
            --enable-nasm

make 
make install PREFIX="${LAME_PREFIX}"
export LD_LIBRARY_PATH="$LAME_PREFIX/lib:$LD_LIBRARY_PATH"
export PATH="$LAME_PREFIX/bin:$PATH"
lame --version 
echo "-----------------------------------------------------Installed lame------------------------------------------------"


#installing opus
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
pkg-config --modversion opus
echo "-----------------------------------------------------Installed opus------------------------------------------------"

#installing libvpx
cd $CURRENT_DIR
git clone https://github.com/webmproject/libvpx.git
cd libvpx
git checkout v1.13.1
export target_platform=$(uname)-$(uname -m)
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH
if [[ ${target_platform} == Linux-* ]]; then
    LDFLAGS="$LDFLAGS -pthread"
fi
CPU_DETECT="${CPU_DETECT} --enable-runtime-cpu-detect"

./configure --prefix=$LIBVPX_PREFIX \
    --as=yasm                    \
    --enable-shared              \
    --disable-static             \
    --disable-install-docs       \
    --disable-install-srcs       \
    --enable-vp8                 \
    --enable-postproc            \
    --enable-vp9                 \
    --enable-vp9-highbitdepth    \
    --enable-pic                 \
    ${CPU_DETECT}                \
    --enable-experimental || { cat config.log; exit 1; }

make 
make install PREFIX="${LIBVPX_PREFIX}"
export LD_LIBRARY_PATH=${LIBVPX_PREFIX}/lib:$LD_LIBRARY_PATH
export PKG_CONFIG_PATH=${LIBVPX_PREFIX}/lib/pkgconfig:$PKG_CONFIG_PATH
pkg-config --modversion vpx
echo "-----------------------------------------------------Installed libvpx------------------------------------------------"

#installing ffmpeg
cd $CURRENT_DIR
git clone https://github.com/FFmpeg/FFmpeg
cd FFmpeg
git checkout n7.1
git submodule update --init



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
		
export CPU_COUNT=$(nproc)
make -j$CPU_COUNT
make install -j$CPU_COUNT
		
export LD_LIBRARY_PATH=${FFMPEG_PREFIX}/lib:${LD_LIBRARY_PATH}
export PKG_CONFIG_PATH="/install-deps/ffmpeg/lib/pkgconfig:$PKG_CONFIG_PATH"

		
cd $CURRENT_DIR
echo "------------ abseil_cpp cloning-------------------"

ABSEIL_VERSION=20240116.2
ABSEIL_URL="https://github.com/abseil/abseil-cpp"
git clone $ABSEIL_URL -b $ABSEIL_VERSION
echo "------------ libprotobuf installing-------------------"
export C_COMPILER=$(which gcc)
export CXX_COMPILER=$(which g++)
#Build libprotobuf
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

cmake --build . --verbose
cmake --install .
cd .. 

export PROTOC="$LIBPROTO_INSTALL/bin/protoc"
export LD_LIBRARY_PATH="/abseil-cpp/abseilcpp/lib:$LIBPROTO_INSTALL/lib64:$LD_LIBRARY_PATH"
export LIBRARY_PATH="$LIBPROTO_INSTALL/lib64:$LD_LIBRARY_PATH"
export PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION=cpp
export PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION_VERSION=2

# echo "----Installing rust------"
curl https://sh.rustup.rs -sSf | sh -s -- -y
source "$HOME/.cargo/env"

# echo "------------cloning pytorch----------------"
cd $CURRENT_DIR
git clone https://github.com/pytorch/pytorch.git
cd pytorch
git checkout v2.7.0
git submodule sync
git submodule update --init --recursive

echo "------------applying patch----------------"
wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/p/pytorch/pytorch_v2.7.1.patch
git apply pytorch_v2.7.1.patch

ARCH=`uname -p`
BUILD_NUM="1"
export OPENBLAS_INCLUDE="${OPENBLAS_PREFIX}/include"
export OpenBLAS_HOME="${OPENBLAS_PREFIX}"
export build_type="cpu"
export cpu_opt_arch="power9"
export cpu_opt_tune="power10"
export CPU_COUNT=$(nproc --all)
export CXXFLAGS="${CXXFLAGS} -D__STDC_FORMAT_MACROS"
export LDFLAGS="$(echo ${LDFLAGS} | sed -e 's/-Wl\,--as-needed//')"
export LDFLAGS="${LDFLAGS} -Wl,-rpath-link,${LIBPROTO_INSTALL}/lib64"
export CXXFLAGS="${CXXFLAGS} -fplt"
export CFLAGS="${CFLAGS} -fplt"
export BLAS=OpenBLAS
export USE_FBGEMM=0
export USE_SYSTEM_NCCL=1
export USE_MKLDNN=0
export USE_NNPACK=0
export USE_QNNPACK=0
export USE_XNNPACK=0
export USE_PYTORCH_QNNPACK=0
export TH_BINARY_BUILD=1
export USE_LMDB=1
export USE_LEVELDB=1
export USE_NINJA=0
export USE_MPI=0
export USE_OPENMP=1
export USE_TBB=0
export BUILD_CUSTOM_PROTOBUF=OFF
export BUILD_CAFFE2=1
export PYTORCH_BUILD_VERSION=2.7.0
export PYTORCH_BUILD_NUMBER=${BUILD_NUM}
export USE_CUDA=0
export USE_CUDNN=0
export USE_TENSORRT=0
export Protobuf_INCLUDE_DIR=${LIBPROTO_INSTALL}/include
export Protobuf_LIBRARIES=${LIBPROTO_INSTALL}/lib64
export Protobuf_LIBRARY=${LIBPROTO_INSTALL}/lib64/libprotobuf.so
export Protobuf_LITE_LIBRARY=${LIBPROTO_INSTALL}/lib64/libprotobuf-lite.so
export Protobuf_PROTOC_EXECUTABLE=${LIBPROTO_INSTALL}/bin/protoc
export PATH="/protobuf/local/libprotobuf/bin/protoc:${PATH}"
export LD_LIBRARY_PATH="/protobuf/local/libprotobuf/lib64:${LD_LIBRARY_PATH}"
export LD_LIBRARY_PATH="/protobuf/third_party/abseil-cpp/local/abseilcpp/lib:${LD_LIBRARY_PATH}"
export CXXFLAGS="${CXXFLAGS} -mcpu=${cpu_opt_arch} -mtune=${cpu_opt_tune}"
export CFLAGS="${CFLAGS} -mcpu=${cpu_opt_arch} -mtune=${cpu_opt_tune}"
export SETUPTOOLS_SCM_PRETEND_VERSION=2.7.0
sed -i "s/cmake/cmake==3.*/g" requirements.txt

python3.12 -m pip install -r requirements.txt
MAX_JOBS=$(nproc) python3.12 setup.py install
cd $CURRENT_DIR

echo "------------------------clone and build torchaudio-------------------"
git clone https://github.com/pytorch/audio.git
cd audio
git checkout v2.7.0

# Apply the patch
echo "------------------------Applying patch-------------------"
wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/t/torchaudio/torchaudio_v2.7.1.patch
git apply torchaudio_v2.7.1.patch
echo "-----------------------Applied patch successfully---------------------------------------"

export USE_FFMPEG=OFF
export BUILD_SOX=OFF
export USE_OPENMP=OFF
export BUILD_TORCHAUDIO_PYTHON_EXTENSION=ON
export LIBPROTO_INSTALL=/protobuf/local/libprotobuf
export LD_LIBRARY_PATH=/pytorch/torch/lib64/libprotobuf.so.3.13.0.0:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=/pytorch/build/lib/libprotobuf.so.3.13.0.0:$LD_LIBRARY_PATH
sed -i 's/2\.7\.0a0/2.7.0/' version.txt
mv .git .git.bak
echo "Installing torchaudio..."
python3.12 -m pip install --no-build-isolation . 

echo "--------------------Installing x264---------------------------------"
cd $CURRENT_DIR
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

echo "------------------Building opencv-python-headless-----------------------"
cd $CURRENT_DIR

git clone https://github.com/opencv/opencv-python
cd opencv-python
git checkout 86
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
python3.12 -m pip install scikit-build setuptools wheel
python3.12 -m pip install -e . 

#installing pillow
cd $CURRENT_DIR
git clone https://github.com/python-pillow/Pillow
cd Pillow
git checkout 11.1.0
git submodule update --init
python3.12 -m pip install . 
echo "-----------------------------------------------------Installed pillow------------------------------------------------"

echo "-----------------------------------------------------Installing pyav------------------------------------------------"
# clone source repository
cd $CURRENT_DIR
git clone https://github.com/PyAV-Org/PyAV
cd PyAV
git checkout v13.1.0
git submodule update --init
export CFLAGS="${CFLAGS} -I/install-deps/ffmpeg/include"
export LDFLAGS="${LDFLAGS} -L/install-deps/ffmpeg/lib"
#Build package
python3.12 setup.py build_ext --inplace
echo "-----------------------------------------------------Installed Pyav------------------------------------------------"

echo "-----------------------------------------------------Installing gensim ------------------------------------------------"
cd $CURRENT_DIR
echo "Installing required Python packages..."
python3.12 -m pip install requests ruamel-yaml 'meson-python<0.13.0,>=0.11.0'  setuptools==76.0.0 scipy==1.15.2 Cython==3.0.12 nbformat  testfixtures mock nbconvert
# Clone the repository
git clone https://github.com/RaRe-Technologies/gensim
cd gensim
git checkout 4.3.3
echo "Building the package using setup.py..."
#Compiled extensions are unavailable.
python3.12 -m pip install scipy
python3.12 setup.py build_ext --inplace
# Build package
python3.12 -m pip install .
echo "-----------------------------------------------------Installed gensim ------------------------------------------------"


echo "------HDF5 installing-----------------------"
cd $CURRENT_DIR
git clone https://github.com/HDFGroup/hdf5
cd hdf5/
git checkout hdf5-1_12_1
git submodule update --init
export HDF5_PREFIX=/install-deps/hdf5
./configure --prefix=$HDF5_PREFIX --enable-cxx --enable-fortran --with-pthread=yes \
            --enable-threadsafe --enable-build-mode=production --enable-unsupported \
            --enable-using-memchecker --enable-clear-file-buffers --with-ssl
make -j$(nproc)
make install
export LD_LIBRARY_PATH=${HDF5_PREFIX}/lib:$LD_LIBRARY_PATH
export HDF5_DIR=${HDF5_PREFIX}
cd $CURRENT_DIR

echo "----------h5py installing--------------------"
git clone https://github.com/h5py/h5py.git
cd h5py/
git checkout 3.13.0
HDF5_DIR=${HDF5_PREFIX} python3.12 -m pip install .
cd $CURRENT_DIR

echo "--------------ml_dtypes installing---------------"
git clone https://github.com/jax-ml/ml_dtypes.git
cd ml_dtypes
git checkout v0.4.1
git submodule update --init
export CFLAGS="-I${ML_DIR}/include"
export CXXFLAGS="-I${ML_DIR}/include"
export CC=/opt/rh/gcc-toolset-13/root/bin/gcc
export CXX=/opt/rh/gcc-toolset-13/root/bin/g++
python3.12 -m pip install .
echo "--------------ml_dtypes installed---------------"

cd $CURRENT_DIR
git clone https://github.com/statsmodels/statsmodels.git
cd statsmodels
git checkout v0.14.4
python3.12 -m pip install .
echo "--------------statsmodels installed---------------"

cd $CURRENT_DIR
echo "------------------------installing dm_tree-------------------------"
export SITE_PACKAGE_PATH="/lib/python3.12/site-packages"
git clone https://github.com/deepmind/tree
cd tree/
git checkout 0.1.8
python3.12 -m pip install --upgrade pip 
python3.12 -m pip install  absl-py attr numpy wrapt attrs
wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/d/dm-tree/update_abseil_version_and_linking_fix.patch
git apply update_abseil_version_and_linking_fix.patch
python3.12 setup.py build_ext --inplace
echo "------------------------installed dm_tree-------------------------"

cd $CURRENT_DIR
echo "------------------------installing gmpy2-------------------------"
git clone https://github.com/aleaxit/gmpy.git
cd  gmpy
git checkout v2.2.1
python3.12 -m pip --verbose install --editable .[docs,tests]
python3.12 -m pip install .
echo "------------------------installed gmpy2-------------------------"

cd $CURRENT_DIR
echo "------------------------installing jpype-------------------------"
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk
export PATH=$JAVA_HOME/bin:$PATH
git clone https://github.com/jpype-project/jpype.git
cd jpype
git checkout v1.5.2
wget https://repo1.maven.org/maven2/org/xerial/sqlite-jdbc/3.42.0.0/sqlite-jdbc-3.42.0.0.jar -O sqlite-jdbc.jar
wget https://repo1.maven.org/maven2/org/hsqldb/hsqldb/2.7.2/hsqldb-2.7.2.jar -O hsqldb.jar
wget https://repo1.maven.org/maven2/com/h2database/h2/2.2.224/h2-2.2.224.jar -O h2.jar
export CLASSPATH=$CLASSPATH:$(pwd)/sqlite-jdbc.jar:$(pwd)/hsqldb.jar:$(pwd)/h2.jar
python3.12 -m pip install numpy tox
python3.12 -m pip install .
echo "------------------------installed jpype-------------------------"


cd $CURRENT_DIR
echo "------------------------installing llvmlite-------------------------"
LLVM_PROJECT_GIT_TAG="llvmorg-15.0.7"
WORKING_DIR="$(pwd)"
export GCC_HOME=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
echo "enabling gcc13-toolset"
source /opt/rh/gcc-toolset-13/enable
git clone https://github.com/llvm/llvm-project.git
cd "$WORKING_DIR/llvm-project"
git checkout $LLVM_PROJECT_GIT_TAG
cd "$WORKING_DIR"
git clone https://github.com/numba/llvmlite
cd llvmlite
git checkout v0.44.0rc1
export LLVM_CONFIG="/llvm-project/build/bin/llvm-config"
cd "$WORKING_DIR/llvm-project"
git apply "$WORKING_DIR/llvmlite/conda-recipes/llvm15-clear-gotoffsetmap.patch"
git apply "$WORKING_DIR/llvmlite/conda-recipes/llvm15-remove-use-of-clonefile.patch"
cp "$WORKING_DIR/llvmlite/conda-recipes/llvmdev/build.sh" .
chmod 777 "$WORKING_DIR/llvm-project/build.sh" && "$WORKING_DIR/llvm-project/build.sh"
LLVM_CONFIG_PATH=$(which llvm-config)
if [ -z "$LLVM_CONFIG_PATH" ]; then
    echo "llvm-config not found in PATH, using local path."
    export LLVM_CONFIG="$WORKING_DIR/llvm-project/build/bin/llvm-config"
else
    echo "llvm-config found at: $LLVM_CONFIG_PATH"
    export LLVM_CONFIG="$LLVM_CONFIG_PATH"
fi
echo "Checking for llvm-config.h in: $WORKING_DIR/llvm-project/build/include/llvm/Config"
ls "$WORKING_DIR/llvm-project/build/include/llvm/Config/llvm-config.h" || { echo "llvm-config.h not found. Exiting."; exit 1; }
cd "$WORKING_DIR/llvmlite"
export CXXFLAGS="-I$WORKING_DIR/llvm-project/build/include"
export LLVM_CONFIG="$WORKING_DIR/llvm-project/build/bin/llvm-config"
python3.12 -m pip install .
echo "------------------------installed llvmlite-------------------------"


cd $CURRENT_DIR
echo "------------------------installing zfp-------------------------"
# export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH
echo "Cloning and installing..."
git clone https://github.com/LLNL/zfp
cd zfp
git checkout 1.0.1
echo "Checking Python version..."
PYTHON_VERSION=$(python3.12 -c "import sys; print('.'.join(map(str, sys.version_info[:2])))")
IFS='.' read -r MAJOR MINOR <<< "$PYTHON_VERSION"
if [[ "$MAJOR" -gt 3 ]] || { [[ "$MAJOR" -eq 3 ]] && [[ "$MINOR" -ge 12 ]]; }; then
    echo "Python version is >= 3.12, installing numpy 2.2.2..."
    python3.12 -m pip install numpy==2.2.2 
else
    echo "Python version is < 3.12, installing numpy 1.23.5..."
    python3.12 -m pip install cython==0.29.36 numpy==1.23.5 
fi

NUMPY_INCLUDE_DIR=$(python3.12 -c "import numpy; print(numpy.get_include())")

echo "Creating build directory..."
mkdir -p build
cd build
export CFLAGS="-fPIC -fopenmp"
export LDFLAGS="-fPIC -static-libgcc -static-libstdc++ -fopenmp -Wl,--whole-archive -lgomp -Wl,--no-whole-archive"
echo "Running CMake..."
echo "Running CMake with static linking..."
cmake .. -DCMAKE_BUILD_TYPE=Release -DBUILD_ZFPY=ON -DBUILD_SHARED_LIBS=OFF \
    -DCMAKE_INSTALL_PREFIX=$(pwd)/install \
    -DPYTHON_EXECUTABLE=$(which python3.12) \
    -DPYTHON_INCLUDE_DIR=$(python3.12 -c "import sysconfig; print(sysconfig.get_path('include'))") \
    -DPYTHON_LIBRARY=$(python3.12 -c "import sysconfig; print(sysconfig.get_config_var('LIBDIR'))") \
    -DNUMPY_INCLUDE_DIR=$NUMPY_INCLUDE_DIR \
    -DCMAKE_C_FLAGS="-fopenmp" \
    -DCMAKE_CXX_FLAGS="-fopenmp" \
    -DCMAKE_EXE_LINKER_FLAGS="-static-libgcc -static-libstdc++ -fopenmp"

echo "Building zfp..."
make -j$(nproc)
make install 
export CMAKE_PREFIX_PATH=$(pwd)/install
cd ..
sed -i 's/), language_level = "3"]/)]/' setup.py
python3.12 -m pip install .
echo "------------------------installed zfp-------------------------"


cd $CURRENT_DIR
echo "------------------------installing numba-------------------------"
#clone repository
git clone https://github.com/numba/numba
cd numba
git checkout 0.62.0dev0
export CXXFLAGS=-I/usr/include
PYTHON_VERSION=$(python3.12 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
sed -i '/#include "dynamic_annotations.h".*\/\*/d' /usr/include/python${PYTHON_VERSION}/internal/pycore_atomic.h
sed -i '1i#include "dynamic_annotations.h"   /* _Py_ANNOTATE_MEMORY_ORDER */' /usr/include/python${PYTHON_VERSION}/internal/pycore_atomic.h
python3.12 -m pip install .
echo "------------------------installed numba-------------------------"

cd $CURRENT_DIR
echo "------------------------installing numexpr-------------------------"
#clone repository
git clone https://github.com/pydata/numexpr.git
cd  numexpr
git checkout v2.8.4
python3.12 -m pip install 
python3.12 -m pip install numpy==1.26.3
python3.12 -m pip install -e .
python3.12 setup.py install
echo "------------------------installed numexpr-------------------------"

cd $CURRENT_DIR
echo "------------------------installing psycopg2-------------------------"
yum install -y  sqlite sqlite-devel xz xz-devel postgresql-devel --nobest
# Clone the package repository
git clone https://github.com/psycopg/psycopg2 
cd psycopg2
git checkout 2.9.10
python3.12 setup.py install
echo "------------------------installed psycopg2-------------------------"

cd $CURRENT_DIR
echo "------------------------installing pyodbc-------------------------"
yum install -y unixODBC-devel
git clone https://github.com/mkleehammer/pyodbc pyodbc
cd pyodbc
git checkout 5.2.0
python3.12 -m pip install 
python3.12 -m pip install "chardet<5,>=3.0.2" --force-reinstall
python3.12 -m pip install psutil
python3.12 setup.py install
echo "------------------------installed pyodbc-------------------------"

cd $CURRENT_DIR
echo "------------------------installing pyzmq-------------------------"
git clone https://github.com/zeromq/pyzmq.git
cd pyzmq
git checkout v26.4.0
python3.12 -m pip install cython==3.0.12 packaging==24.2 pathspec==0.12.1 scikit-build-core==0.11.1 ninja==1.11.1.4 build
python3.12 -m pip install -e .
echo "------------------------installed pyzmq-------------------------"

cd $CURRENT_DIR
echo "------------------------installing scikit_image-------------------------"
git clone https://github.com/scikit-image/scikit-image
cd scikit-image
git checkout v0.25.2
python3.12 -m pip install -r requirements.txt
python3.12  -m pip install -r requirements/build.txt
python3.12 -m pip install --upgrade pip
ln -s $(which python3.12) /usr/bin/python
python3.12 -m pip install -e .
echo "------------------------installed scikit_image-------------------------"

echo " ------------------------------ Installing Swig ------------------------------ "
cd $CURRENT_DIR
git clone https://github.com/nightlark/swig-pypi.git
cd swig-pypi
python3.12 -m pip install .
echo " ------------------------------ Swig Installed Successfully ------------------------------ "

cd $CURRENT_DIR
# Installing hwloc from source
echo " ------------------------------ Installing hwloc ------------------------------ "
git clone https://github.com/open-mpi/hwloc
cd hwloc 
./autogen.sh   
./configure
make
make install
echo " ------------------------------ hwloc Installed Successfully ------------------------------ "

echo " -------------------------- Installing onetbb -------------------------- "
cd $CURRENT_DIR
git clone  https://github.com/uxlfoundation/oneTBB
cd oneTBB
git checkout v2021.8.0
mkdir build
cd build/
pwd
cmake -DCMAKE_INSTALL_PREFIX=/tmp/my_installed_onetbb -DTBB_TEST=OFF -DBUILD_SHARED_LIBS=OFF -DBUILD_STATIC=ON -DCMAKE_CXX_FLAGS="-static-libgcc -static-libstdc++" -DCMAKE_EXE_LINKER_FLAGS="-static" -DTBB_BUILD=ON -DTBB4PY_BUILD=ON ..
echo "------------Building the package------------"
make -j4 python_build
echo "------------Export statements------------"
export TBBROOT=/tmp/my_installed_onetbb/
export CMAKE_PREFIX_PATH=$TBBROOT
make install

####################do thi again
echo " -------------------------- Installed onetbb -------------------------- "

cd $CURRENT_DIR
echo "----------------------------- Installing matplotlib ----------------------------"
# Clone the matplotlib package.
git clone https://github.com/matplotlib/matplotlib.git
cd matplotlib/
git checkout v3.10.1
git submodule update --init
 
echo "Downloading and preparing qhull..."
# Download qhull
mkdir -p build
wget 'http://www.qhull.org/download/qhull-2020-src-8.0.2.tgz'
gunzip qhull-2020-src-8.0.2.tgz
tar -xvf qhull-2020-src-8.0.2.tar --no-same-owner
mv qhull-2020.2 build/
rm -f qhull-2020-src-8.0.2.tar
echo "qhull downloaded and prepared."
python3.12 -m pip install  hypothesis build meson pybind11 meson-python
python3.12 -m pip install 'numpy<2' fontTools setuptools-scm contourpy kiwisolver python-dateutil cycler pyparsing pillow certifi
ln -sf /usr/bin/python3.12 /usr/bin/python3

# Build and Install the package (This is dependent on numpy, pillow)
python3.12 -m pip install -e .
echo "----------------------------- Installed matplotlib ----------------------------"
