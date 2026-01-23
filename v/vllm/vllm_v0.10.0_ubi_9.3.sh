#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : vllm
# Version       : v0.10.0
# Source repo   : https://github.com/vllm-project/vllm
# Tested on     : UBI:9.3
# Language      : Python
# Ci-Check  : True
# Script License: Apache License 2.0
# Maintainer    : Ramnath Nayak <Ramnath.Nayak@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------


PACKAGE_NAME=vllm
PACKAGE_VERSION=${1:-v0.10.0}
PACKAGE_URL=https://github.com/vllm-project/vllm.git
CURRENT_DIR=$(pwd)
PACKAGE_DIR=vllm

yum install -y openblas-devel git make libtool wget gcc-toolset-13 cmake python3.12 python3.12-devel python3.12-pip gcc-toolset-13 gcc-toolset-13-binutils gcc-toolset-13-binutils-devel gcc-toolset-13-gcc-c++ binutils meson ninja-build openssl-devel libjpeg-devel bzip2-devel libffi-devel zlib-devel libtiff-devel freetype-devel  autoconf procps-ng glibc-static libstdc++-static kmod automake gmp-devel gmp-devel.ppc64le libjpeg-turbo-devel mpfr-devel.ppc64le libmpc-devel.ppc64le java-11-openjdk java-11-openjdk-devel gzip tar xz yum-utils bzip2 zip unzip cargo pkgconf-pkg-config.ppc64le info.ppc64le fontconfig.ppc64le fontconfig-devel.ppc64le sqlite-devel gcc-toolset-13-gcc-gfortran pkgconfig atlas libevent-devel patch pkg-config llvm-devel clang clang-devel


source /opt/rh/gcc-toolset-13/enable
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
build_opts+=(NUM_THREADS=120)
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

sed -i -E -e 's/"setuptools.+",/"setuptools",/g' pyproject.toml
sed -i -E -e 's/"numpy.+",/"numpy",/g' pyproject.toml


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
python3.12 -m build --wheel --no-isolation --outdir="$(pwd)"
python3.12 -m pip install *.whl

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
#python3.12 -m pip install requests ruamel-yaml 'meson-python<0.13.0,>=0.11.0'  setuptools==76.0.0 scipy==1.15.2 Cython==3.0.12 nbformat  testfixtures mock nbconvert
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
wget https://github.com/qhull/qhull/archive/refs/tags/v8.0.2.tar.gz -O qhull-8.0.2.tar.gz
tar -xzf qhull-8.0.2.tar.gz
mv qhull-8.0.2 build/qhull-2020.2
echo "qhull downloaded and prepared."
python3.12 -m pip install  hypothesis build meson pybind11 meson-python
python3.12 -m pip install 'numpy<2' fontTools setuptools-scm contourpy kiwisolver python-dateutil cycler pyparsing pillow certifi
ln -sf /usr/bin/python3.12 /usr/bin/python3

# Build and Install the package (This is dependent on numpy, pillow)
python3.12 -m pip install -e .
echo "----------------------------- Installed matplotlib ----------------------------"


cd $CURRENT_DIR
echo "----------------------------- Installing torchvision ----------------------------"
OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)
MAX_JOBS=${MAX_JOBS:-$(nproc)}

yum install -y gcc-toolset-13-libatomic-devel

cd $CURRENT_DIR
echo "--------------------scipy installing-------------------------------"
#Building scipy
python3.12 -m pip install beniget==0.4.2.post1 Cython==3.0.11 gast==0.6.0 meson==1.6.0 meson-python==0.17.1 packaging pybind11 pyproject-metadata pythran==0.17.0 setuptools==75.3.0 pooch  build hypothesis patchelf
git clone https://github.com/scipy/scipy
cd scipy/
git checkout v1.15.2
git submodule update --init
echo "instaling scipy......."
python3.12 -m pip install .
cd $CURRENT_DIR
export C_COMPILER=$(which gcc)
export CXX_COMPILER=$(which g++)
cd $CURRENT_DIR
git clone https://github.com/pytorch/vision.git
cd vision
git checkout v0.22.0
export LD_LIBRARY_PATH=/home/protobuf/local/libprotobuf/lib64:$LD_LIBRARY_PATH
python3.12 -m pip install -v -e . --no-build-isolation
echo "----------------------------- Installed torchvision ----------------------------"



cd $CURRENT_DIR
echo "--------------------pyarrow installing-------------------------------"
echo "Install dependencies and tools."
yum install -y brotli-devel.ppc64le bzip2-devel lz4-devel 
# Installing flex bison c-ares gflags rapidjson xsimd snappy libzstd
echo "-----------flex installing------------------"
wget https://github.com/westes/flex/releases/download/v2.6.4/flex-2.6.4.tar.gz
tar -xvf flex-2.6.4.tar.gz
cd flex-2.6.4
echo "Configuring flex installation..."
./configure --prefix=/usr/local
echo "Compiling the source code for flex..."
make -j$(nproc)
echo "Installing flex..."
make install
export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH
cd $CURRENT_DIR 

echo "-------bison installing----------------------"
wget https://ftp.gnu.org/gnu/bison/bison-3.8.2.tar.gz
tar -xvf bison-3.8.2.tar.gz
cd bison-3.8.2
echo "Configuring bison installation..."
./configure --prefix=/usr/local
echo "Compiling the source code bison..."
make -j$(nproc)
echo "Installing bison..."
make install
cd $CURRENT_DIR

echo "------------ gflags installing-------------------"
git clone https://github.com/gflags/gflags.git
cd gflags
mkdir build && cd build
echo "Running cmake to configure the build..."
cmake ..
echo "Compiling the source code gflags..."
make -j$(nproc)
echo "Installing gflags..."
make install
cd $CURRENT_DIR 

echo "----------Installing c-ares----------------"
#Building c-areas
git clone https://github.com/c-ares/c-ares.git
cd c-ares
git checkout cares-1_19_1


target_platform=$(uname)-$(uname -m)
AR=$(which ar)
PKG_NAME=c-ares

mkdir -p c_ares_prefix
export C_ARES_PREFIX=$(pwd)/c_ares_prefix

echo "Building ${PKG_NAME}."

# Isolate the build.
mkdir build && cd build

if [[ "$PKG_NAME" == *static ]]; then
  CARES_STATIC=ON
  CARES_SHARED=OFF
else
  CARES_STATIC=OFF
  CARES_SHARED=ON
fi

if [[ "${target_platform}" == Linux-* ]]; then
  CMAKE_ARGS="${CMAKE_ARGS} -DCMAKE_AR=${AR}"
fi


# Generate the build files.
echo "Generating the build files..."
cmake ${CMAKE_ARGS} .. \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX="$C_ARES_PREFIX" \
      -DCARES_STATIC=${CARES_STATIC} \
      -DCARES_SHARED=${CARES_SHARED} \
      -DCARES_INSTALL=ON \
      -DCMAKE_INSTALL_LIBDIR=lib \
      -GNinja
      #${SRC_DIR}

# Build.
echo "Building c-areas..."
ninja || exit 1

# Installing
echo "Installing c-areas..."
ninja install || exit 1

cd $CURRENT_DIR

echo "----------c-areas installed-----------------------"

echo "----------------rapidjson installing------------------"
git clone https://github.com/Tencent/rapidjson.git
cd rapidjson
mkdir build && cd build
echo "Running cmake to configure the build..."
cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local
echo "Compiling the source code for rapidjson..."
make -j$(nproc)
echo "Installing rapidjson"
make install
cd $CURRENT_DIR 

echo "--------------xsimd installing-------------------------"
git clone https://github.com/xtensor-stack/xsimd.git
cd xsimd
mkdir build && cd build
echo "Running cmake to configure the build for xsimd.."
cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local
echo "Compiling the source code for xsimd..."
make -j$(nproc)
echo "Installing xsimd..."
make install
cd $CURRENT_DIR 


echo "-----------------snappy installing----------------"
git clone https://github.com/google/snappy.git
cd snappy
git submodule update --init --recursive

mkdir -p local/snappy
export SNAPPY_PREFIX=$(pwd)/local/snappy
mkdir build
cd build
echo "Running cmake to configure the build for snappy..."
cmake -DCMAKE_INSTALL_PREFIX=$SNAPPY_PREFIX \
      -DBUILD_SHARED_LIBS=ON \
      -DCMAKE_INSTALL_LIBDIR=lib \
      ..
echo "Compiling the source code for snappy..."
make -j$(nproc)
echo "Installing snappy..."
make install
export LD_LIBRARY_PATH=$SNAPPY_PREFIX/lib:$LD_LIBRARY_PATH
cd ..
cd $CURRENT_DIR 


echo "------------libzstd installing-------------------------"
git clone https://github.com/facebook/zstd.git
cd zstd

echo "Compiling the source code for libzstd..."
make
echo "Installing libzstd..."
make install
export ZSTD_HOME=/usr/local
export CMAKE_PREFIX_PATH=$ZSTD_HOME
export LD_LIBRARY_PATH=$ZSTD_HOME/lib64:$LD_LIBRARY_PATH
cd $CURRENT_DIR

echo "------------ re2 installing-------------------"

git clone http://github.com/google/re2
cd re2
git checkout 2022-04-01

git submodule update --init

mkdir re2-prefix

export RE2_PREFIX=$(pwd)/re2-prefix

export CPU_COUNT=`nproc`

mkdir build-cmake
pushd build-cmake

echo "Running cmake to configure the build for re2..."
cmake ${CMAKE_ARGS} -GNinja \
  -DCMAKE_PREFIX_PATH=$RE2_PREFIX \
  -DCMAKE_INSTALL_PREFIX="${RE2_PREFIX}" \
  -DCMAKE_INSTALL_LIBDIR=lib \
  -DENABLE_TESTING=OFF \
  -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_SHARED_LIBS=ON \
  ..
echo "Installing re2..."
  ninja -v install
  popd
echo "Running make shared-install......"
make -j "${CPU_COUNT}" prefix=${RE2_PREFIX} shared-install
export LD_LIBRARY_PATH=$RE2_PREFIX/lib:$LD_LIBRARY_PATH
cd $CURRENT_DIR 

echo "------------ utf8proc installing-------------------"

git clone https://github.com/JuliaStrings/utf8proc.git
cd utf8proc
git submodule update --init
git checkout v2.6.1

mkdir utf8proc_prefix
export UTF8PROC_PREFIX=$(pwd)/utf8proc_prefix

# Create build directory
mkdir build
cd build
echo "Running cmake to configure the build for utf8proc..."
# Run cmake to configure the build
cmake -G "Unix Makefiles" \
  -DCMAKE_BUILD_TYPE="Release" \
  -DCMAKE_INSTALL_PREFIX="${UTF8PROC_PREFIX}" \
  -DCMAKE_POSITION_INDEPENDENT_CODE=1 \
  -DBUILD_SHARED_LIBS=1 \
  ..
echo  "Build and install utf8proc"
cmake --build .

echo "Installing utf8proc ..."
cmake --build . --target install
export LD_LIBRARY_PATH=$UTF8PROC_PREFIX/lib:$LD_LIBRARY_PATH
cd $CURRENT_DIR 

echo "------------ orc installing-------------------"

git clone https://github.com/apache/orc
cd orc
git checkout v2.0.3
wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/o/orc/orc.patch
git apply orc.patch
mkdir orc_prefix
export ORC_PREFIX=$(pwd)/orc_prefix
mkdir -p build
cd build
export PROTOBUF_PREFIX=$LIBPROTO_INSTALL
export CMAKE_PREFIX_PATH=$LIBPROTO_INSTALL
export GCC=$CC
export GXX=$CXX
export HOST=$(uname)-$(uname -m)
export HOST=$(uname)-$(uname -m)

CPPFLAGS="${CPPFLAGS} -Wl,-rpath,$VIRTUAL_ENV_PATH/**/lib"


declare -a _CMAKE_EXTRA_CONFIG
if [[ "$CONDA_BUILD_CROSS_COMPILATION" == 1 ]]; then
    _CMAKE_EXTRA_CONFIG+=(-DHAS_PRE_1970_EXITCODE=0)
    _CMAKE_EXTRA_CONFIG+=(-DHAS_PRE_1970_EXITCODE__TRYRUN_OUTPUT=)
    _CMAKE_EXTRA_CONFIG+=(-DHAS_POST_2038_EXITCODE=0)
    _CMAKE_EXTRA_CONFIG+=(-DHAS_POST_2038_EXITCODE__TRYRUN_OUTPUT=)
fi
if [[ ${HOST} =~ .*darwin.* ]]; then
    _CMAKE_EXTRA_CONFIG+=(-DCMAKE_AR=${AR})
    _CMAKE_EXTRA_CONFIG+=(-DCMAKE_RANLIB=${RANLIB})
    _CMAKE_EXTRA_CONFIG+=(-DCMAKE_LINKER=${LD})
fi
if [[ ${HOST} =~ .*Linux.* ]]; then
    CXXFLAGS="${CXXFLAGS//-std=c++17/-std=c++11}"
    LIBPTHREAD=$(find ${PREFIX} -name "libpthread.so")
    _CMAKE_EXTRA_CONFIG+=(-DPTHREAD_LIBRARY=${LIBPTHREAD})
fi

CPPFLAGS="${CPPFLAGS} -Wl,-rpath,$VIRTUAL_ENV_PATH/**/lib"
echo "Running cmake to configure the build for orc..."
source /opt/rh/gcc-toolset-13/enable
cmake ${CMAKE_ARGS} \
    -DCMAKE_PREFIX_PATH=$ORC_PREFIX \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DBUILD_JAVA=False \
    -DLZ4_HOME=/usr \
    -DZLIB_HOME=/usr \
    -DZSTD_HOME=/usr/local \
    -DCMAKE_POLICY_DEFAULT_CMP0074=NEW \
    -DProtobuf_ROOT=$PROTOBUF_PREFIX \
    -DPROTOBUF_HOME=$PROTOBUF_PREFIX \
    -DPROTOBUF_EXECUTABLE=$PROTOBUF_PREFIX/bin/protoc \
    -DSNAPPY_HOME=$SNAPPY_PREFIX \
    -DBUILD_LIBHDFSPP=NO \
    -DBUILD_CPP_TESTS=OFF \
    -DCMAKE_INSTALL_PREFIX=$ORC_PREFIX \
    -DCMAKE_C_COMPILER=$(type -p ${CC})     \
    -DCMAKE_CXX_COMPILER=$(type -p ${CXX})  \
    -DCMAKE_C_FLAGS="$CFLAGS"  \
    -DCMAKE_CXX_FLAGS="$CXXFLAGS -Wno-unused-parameter" \
    "${_CMAKE_EXTRA_CONFIG[@]}" \
    -GNinja ..

ninja
echo  "Installing orc..."
ninja install
export LD_LIBRARY_PATH=$ORC_PREFIX/lib:$LD_LIBRARY_PATH
cd $CURRENT_DIR

echo "-----------------boost_cpp installing-----------------------"

git clone https://github.com/boostorg/boost
cd boost
git checkout boost-1.81.0
git submodule update --init

mkdir Boost_prefix
export BOOST_PREFIX=$(pwd)/Boost_prefix

INCLUDE_PATH="${BOOST_PREFIX}/include"
LIBRARY_PATH="${BOOST_PREFIX}/lib"

export target_platform=$(uname)-$(uname -m)
CXXFLAGS="${CXXFLAGS} -fPIC"
TOOLSET=gcc

 # http://www.boost.org/build/doc/html/bbv2/tasks/crosscompile.html
cat <<EOF > tools/build/example/site-config.jam
using ${TOOLSET} : : ${CXX} ;
EOF

LINKFLAGS="${LINKFLAGS} -L${LIBRARY_PATH}"

CXXFLAGS="$(echo ${CXXFLAGS} | sed 's/ -march=[^ ]*//g' | sed 's/ -mcpu=[^ ]*//g' |sed 's/ -mtune=[^ ]*//g')" \
CFLAGS="$(echo ${CFLAGS} | sed 's/ -march=[^ ]*//g' | sed 's/ -mcpu=[^ ]*//g' |sed 's/ -mtune=[^ ]*//g')" \
    CXX=${CXX_FOR_BUILD:-${CXX}} CC=${CC_FOR_BUILD:-${CC}} ./bootstrap.sh \
    --prefix="${BOOST_PREFIX}" \
    --without-libraries=python \
    --with-toolset=${TOOLSET} \
    --with-icu="${BOOST_PREFIX}" || (cat bootstrap.log; exit 1)
	 ADDRESS_MODEL=64
    ARCHITECTURE=power
	ABI="sysv"
	 BINARY_FORMAT="elf"

	 export CPU_COUNT=$(nproc)

echo " Building and installing Boost...."
./b2 -q \
    variant=release \
    address-model="${ADDRESS_MODEL}" \
    architecture="${ARCHITECTURE}" \
    binary-format="${BINARY_FORMAT}" \
    abi="${ABI}" \
    debug-symbols=off \
    threading=multi \
    runtime-link=shared \
    link=shared \
    toolset=${TOOLSET} \
    include="${INCLUDE_PATH}" \
    cxxflags="${CXXFLAGS} -Wno-deprecated-declarations" \
    linkflags="${LINKFLAGS}" \
    --layout=system \
    -j"${CPU_COUNT}" \
    install

# Remove Python headers as we don't build Boost.Python.
rm "${BOOST_PREFIX}/include/boost/python.hpp"
rm -r "${BOOST_PREFIX}/include/boost/python"
export LD_LIBRARY_PATH=$BOOST_PREFIX/lib:$LD_LIBRARY_PATH
cd $CURRENT_DIR 

echo "------------thrift_cpp  installing-------------------"
git clone https://github.com/apache/thrift
cd thrift
git checkout 0.21.0
mkdir thrift-prefix
export THRIFT_PREFIX=/thrift/thrift-prefix

export BOOST_ROOT=${BOOST_PREFIX}
export ZLIB_ROOT=/usr
export LIBEVENT_ROOT=/usr

export _ROOT=/usr
export _ROOT_DIR=/usr

./bootstrap.sh
echo "Configuring thrift-cpp installation..."
./configure --prefix=$THRIFT_PREFIX \
    --with-python=no \
    --with-py3=no \
    --with-ruby=no \
    --with-java=no \
    --with-kotlin=no \
    --with-erlang=no \
    --with-nodejs=no \
    --with-c_glib=no \
    --with-haxe=no \
    --with-rs=no \
    --with-cpp=yes \
    --with-PACKAGE=yes \
    --with-zlib=$ZLIB_ROOT \
    --with-libevent=$LIBEVENT_ROOT \
    --with-boost=$BOOST_ROOT \
    --with-=$_ROOT \
    --enable-tests=no \
    --enable-tutorial=no 

make -j$(nproc)
make install PREFIX="${THRIFT_PREFIX}"

export PATH="$THRIFT_PREFIX/bin:$PATH"
export LD_LIBRARY_PATH=/thrift/thrift-prefix/lib:$LD_LIBRARY_PATH
export PKG_CONFIG_PATH=/thrift/thrift-prefix/lib/pkgconfig:$PKG_CONFIG_PATH

#export CPLUS_INCLUDE_PATH="$THRIFT_PREFIX/include:$CPLUS_INCLUDE_PATH"
#export LIBRARY_PATH="$THRIFT_PREFIX/lib:$LIBRARY_PATH"
#export CMAKE_PREFIX_PATH="$THRIFT_PREFIX:$CMAKE_PREFIX_PATH"
cd $CURRENT_DIR 

echo "------------ grpc_cpp installing-------------------"
git clone https://github.com/grpc/grpc
cd grpc
git checkout v1.68.0
git submodule update --init
mkdir grpc-prefix
export GRPC_PREFIX=$(pwd)/grpc-prefix
AR=`which ar`
RANLIB=`which ranlib`

PROTOC_BIN=$LIBPROTO_INSTALL/bin/protoc
PROTOBUF_SRC=$LIBPROTO_INSTALL

export CMAKE_PREFIX_PATH="$C_ARES_PREFIX;$RE2_PREFIX;$LIBPROTO_INSTALL"

target_platform=$(uname)-$(uname -m)

if [[ "${target_platform}" == osx* ]]; then
  export CMAKE_ARGS="${CMAKE_ARGS} -DCMAKE_CXX_STANDARD=14"
else
  export CMAKE_ARGS="${CMAKE_ARGS} -DCMAKE_CXX_STANDARD=17"
fi


mkdir -p build-cpp
pushd build-cpp
echo "Running cmake to configure the build for grpc-cpp...."
cmake ${CMAKE_ARGS} ..  \
      -GNinja \
      -DBUILD_SHARED_LIBS=ON \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=$GRPC_PREFIX \
      -DgRPC_CARES_PROVIDER="package" \
      -DgRPC_GFLAGS_PROVIDER="package" \
      -DgRPC_PROTOBUF_PROVIDER="package" \
      -DProtobuf_ROOT=$PROTOBUF_SRC \
      -DgRPC_SSL_PROVIDER="package" \
      -DgRPC_ZLIB_PROVIDER="package" \
      -DgRPC_ABSL_PROVIDER="package" \
      -DgRPC_RE2_PROVIDER="package" \
      -DCMAKE_PREFIX_PATH=$CMAKE_PREFIX_PATH \
      -DCMAKE_AR=${AR} \
      -DCMAKE_RANLIB=${RANLIB} \
      -DCMAKE_VERBOSE_MAKEFILE=ON \
      -DProtobuf_PROTOC_EXECUTABLE=$PROTOC_BIN
echo  "Installing grpc_cpp..."
ninja install -v
popd
python3.12 -m pip install coverage  
export GRPC_PYTHON_BUILD_SYSTEM_=true
export GRPC_PYTHON_BUILD_WITH_CYTHON=1
export PATH="/opt/rh/gcc-toolset-13/root/usr/bin:${PATH}"
python3.12 -m pip install -r requirements.txt
GRPC_PYTHON_BUILD_SYSTEM_OPENSSL=1 python3.12 -m pip install -e .
export LD_LIBRARY_PATH=$GRPC_PREFIX/lib:$LD_LIBRARY_PATH
echo "Installed grpcio"

cd $CURRENT_DIR
echo "-----------------installing pyarrow----------------------"
#cloning pyarrow
git clone  https://github.com/apache/arrow
cd arrow
git checkout apache-arrow-19.0.0
git submodule update --init
mkdir pyarrow_prefix
export PYARROW_PREFIX=$(pwd)/pyarrow_prefix
export ARROW_HOME=$PYARROW_PREFIX
export target_platform=$(uname)-$(uname -m)
export CXX=$(which g++)
export CMAKE_PREFIX_PATH=$C_ARES_PREFIX:$LIBPROTO_INSTALL:$RE2_PREFIX:$GRPC_PREFIX:$ORC_PREFIX:$BOOST_PREFIX:${UTF8PROC_PREFIX}:$THRIFT_PREFIX:$SNAPPY_PREFIX:/usr
export LD_LIBRARY_PATH=$GRPC_PREFIX/lib:$LIBPROTO_INSTALL/lib64:$LD_LIBRARY_PATH
mkdir cpp/build
pushd cpp/build
EXTRA_CMAKE_ARGS=""

# Include g++'s system headers
if [ "$(uname)" == "Linux" ]; then
  SYSTEM_INCLUDES=$(echo | ${CXX} -E -Wp,-v -xc++ - 2>&1 | grep '^ ' | awk '{print "-isystem;" substr($1, 1)}' | tr '\n' ';')
  EXTRA_CMAKE_ARGS=" -DARROW_GANDIVA_PC_CXX_FLAGS=${SYSTEM_INCLUDES}"
  sed -ie 's;"--with-jemalloc-prefix\=je_arrow_";"--with-jemalloc-prefix\=je_arrow_" "--with-lg-page\=16";g' ../cmake_modules/ThirdpartyToolchain.cmake
fi

# Enable CUDA support
if [ "${build_type}" = "cuda" ]; then
  if [[ -z "${CUDA_HOME+x}" ]]
    then
        echo "cuda version=${cudatoolkit} CUDA_HOME=$CUDA_HOME"
        CUDA_GDB_EXECUTABLE=$(which cuda-gdb || exit 0)
        if [[ -n "$CUDA_GDB_EXECUTABLE" ]]
        then
            CUDA_HOME=$(dirname $(dirname $CUDA_GDB_EXECUTABLE))
        else
            echo "Cannot determine CUDA_HOME: cuda-gdb not in PATH"
            return 1
        fi
    fi
  EXTRA_CMAKE_ARGS=" ${EXTRA_CMAKE_ARGS} -DARROW_CUDA=ON -DCUDA_TOOLKIT_ROOT_DIR=${CUDA_HOME} -DCMAKE_LIBRARY_PATH=${CUDA_HOME}/lib64/stubs"
else
  EXTRA_CMAKE_ARGS=" ${EXTRA_CMAKE_ARGS} -DARROW_CUDA=OFF"
fi
# Disable Gandiva
EXTRA_CMAKE_ARGS=" ${EXTRA_CMAKE_ARGS} -DARROW_GANDIVA=OFF"

export BOOST_ROOT="${BOOST_PREFIX}"
export Boost_ROOT="${BOOST_PREFIX}"

export CXXFLAGS="-I$${BOOST_PREFIX}/include -I${THRIFT_PREFIX}/include"

#SIMD Settings
if [[ "${target_platform}" == "Linux-x86_64" ]]; then
  EXTRA_CMAKE_ARGS=" ${EXTRA_CMAKE_ARGS} -DARROW_SIMD_LEVEL=SSE4_2"
fi
if [[ "${target_platform}" == "Linux-ppc64le" ]]; then
  EXTRA_CMAKE_ARGS=" ${EXTRA_CMAKE_ARGS} -DARROW_ALTIVEC=ON"
fi
if [[ "${target_platform}" != "Linux-s390x" ]]; then
  EXTRA_CMAKE_ARGS=" ${EXTRA_CMAKE_ARGS} -DARROW_USE_LD_GOLD=ON"
fi

export AR=$(which ar)
export RANLIB=$(which ranlib)
echo "Running cmake to configure the build for pyarrow..."
cmake \
    -DCMAKE_PREFIX_PATH=$CMAKE_PREFIX_PATH \
    -DARROW_BOOST_USE_SHARED=ON \
    -DARROW_BUILD_BENCHMARKS=OFF \
    -DARROW_BUILD_STATIC=OFF \
    -DARROW_BUILD_TESTS=OFF \
    -DARROW_BUILD_UTILITIES=OFF \
    -DBUILD_SHARED_LIBS=ON \
    -DARROW_DATASET=ON \
    -DARROW_DEPENDENCY_SOURCE=SYSTEM \
    -DARROW_FLIGHT=ON \
    -DARROW_HDFS=ON \
    -DARROW_JEMALLOC=ON \
    -DARROW_MIMALLOC=ON \
    -DARROW_ORC=ON \
    -DARROW_PACKAGE_PREFIX=$PYARROW_PREFIX \
    -DARROW_PARQUET=ON \
    -DARROW_PYTHON=ON \
    -DARROW_S3=OFF \
    -DARROW_WITH_BROTLI=ON \
    -DARROW_WITH_BZ2=ON \
    -DARROW_WITH_LZ4=ON \
    -DARROW_WITH_SNAPPY=ON \
    -DARROW_WITH_ZLIB=ON \
    -DARROW_WITH_ZSTD=ON \
    -DARROW_WITH_THRIFT=ON \
    -DCMAKE_BUILD_TYPE=release \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_INSTALL_PREFIX=$ARROW_HOME \
    -DPYTHON_EXECUTABLE=$(which python3.12) \
    -DPython3_EXECUTABLE=$(which python3.12) \
    -DProtobuf_PROTOC_EXECUTABLE=${LIBPROTO_INSTALL}/bin/protoc \
    -DORC_INCLUDE_DIR=${ORC_PREFIX}/include \
    -DgRPC_DIR=${GRPC_PREFIX} \
    -DBoost_DIR=${BOOST_PREFIX} \
    -DBoost_INCLUDE_DIR=${BOOST_PREFIX}/include/ \
    -Dutf8proc_LIB=${UTF8PROC_PREFIX}/lib/libutf8proc.so ${UTF8PROC_PREFIX}/lib/libutf8proc.so.2 ${UTF8PROC_PREFIX}/lib/libutf8proc.so.2.4.1 \
    -Dutf8proc_INCLUDE_DIR=${UTF8PROC_PREFIX}/include \
    -DCMAKE_AR=${AR} \
    -DCMAKE_RANLIB=${RANLIB} \
    -GNinja \
    ${EXTRA_CMAKE_ARGS} \
    ..

echo "Installing pyarrow...."
ninja install
popd

cd $CURRENT_DIR
echo "Installing prerequisite for arrow..."
python3.12 -m pip install setuptools-scm 

export PYARROW_BUNDLE_ARROW_CPP=1
export LD_LIBRARY_PATH=${ARROW_HOME}/lib:${LD_LIBRARY_PATH}
export build_type=cpu
cd arrow
export CMAKE_PREFIX_PATH=$ARROW_HOME
# Build dependencies
export PARQUET_HOME=$ARROW_HOME
export SETUPTOOLS_SCM_PRETEND_VERSION=19.0.0
export PYARROW_BUILD_TYPE=release
export PYARROW_BUNDLE_ARROW_CPP_HEADERS=1
export PYARROW_WITH_DATASET=1
export PYARROW_WITH_FLIGHT=1
# Disable Gandiva
export PYARROW_WITH_GANDIVA=0
export PYARROW_WITH_HDFS=1
export PYARROW_WITH_ORC=1
export PYARROW_WITH_PARQUET=1
export PYARROW_WITH_PLASMA=1
export PYARROW_WITH_S3=0
export PYARROW_CMAKE_GENERATOR=Ninja
BUILD_EXT_FLAGS=""

# Enable CUDA support
if [ "${build_type}" = "cuda" ]; then
    export PYARROW_WITH_CUDA=1
else
    export PYARROW_WITH_CUDA=0
fi
cd python
export PATH=/usr/bin:$PATH
python3.12 -m pip install .


cd $CURRENT_DIR
# Clone the repository
git clone https://github.com/numactl/numactl
cd numactl
git checkout v2.0.19
./autogen.sh
./configure
make
make install

cd $CURRENT_DIR
git clone https://github.com/openai/tiktoken
cd tiktoken
git checkout 0.7.0
python3.12 -m pip install -e .

cd $CURRENT_DIR
git clone https://github.com/dottxt-ai/outlines-core
cd outlines-core
git checkout 0.1.26
rustup update stable
export PATH=$HOME/.cargo/bin:$PATH
python3.12 -m pip install -e .

cd $CURRENT_DIR
git clone https://github.com/wjakob/nanobind.git
cd nanobind
git submodule update --init --recursive
mkdir build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local
make -j
make install
export CMAKE_PREFIX_PATH=/usr/local:$CMAKE_PREFIX_PATH

python3.12 -m pip install --prefer-binary  soxr --extra-index-url=https://wheels.developerfirst.ibm.com/ppc64le/linux

cd $CURRENT_DIR
git clone $PACKAGE_URL
cd $PACKAGE_DIR
git checkout $PACKAGE_VERSION

python3.12 -m pip install setuptools-rust maturin setuptools_scm pytest pytest-asyncio uv

export LD_LIBRARY_PATH=/protobuf/local/libprotobuf/lib64:$LD_LIBRARY_PATH
export CMAKE_PREFIX_PATH=/protobuf/local/libprotobuf
export RANK=0
export WORLD_SIZE=1

export SETUPTOOLS_SCM_PRETEND_VERSION=0.10.0
export UV_LINK_MODE=copy
export _GLIBCXX_USE_CXX11_ABI=1
export GRPC_PYTHON_BUILD_SYSTEM_OPENSSL=1
export VLLM_TARGET_DEVICE=cpu
export MAX_JOBS=$(nproc)
sed -i -e 's/.*torch.*//g' pyproject.toml requirements/*.txt

uv pip install -r requirements/common.txt -r requirements/cpu.txt -r requirements/build.txt --system
uv pip install pandas pythran pybind11 --system

if ! (uv pip install -v . --no-build-isolation --system); then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
    exit 1
fi

python3.12 setup.py bdist_wheel --dist-dir=${CURRENT_DIR}

if ! pytest; then
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
