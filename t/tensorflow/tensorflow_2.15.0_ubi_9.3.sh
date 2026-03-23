#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : tensorflow
# Version       : 2.15.0
# Source repo   : https://github.com/tensorflow/tensorflow
# Tested on     : UBI:9.3
# Language      : Python
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Shivansh Sharma <Shivansh.s1@ibm.com>
#
# Disclaimer: This script has been tested in root mode on the given
# platform using the mentioned version of the package.
# It may not work as expected with newer versions of the
# package and/or distribution. In such a case, please
# contact the "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

#variables
PACKAGE_NAME=tensorflow
PACKAGE_VERSION=v2.15.0
PACKAGE_URL=https://github.com/tensorflow/tensorflow
CURRENT_DIR=$(pwd)
WHEEL_DIR=$CURRENT_DIR/local_wheels

export LLVM_ENABLE_PDB=0
export BAZEL_FETCH_TIMEOUT=3600

echo "------------------------Installing dependencies-------------------"
yum install -y wget gcc-toolset-12-gcc.ppc64le gcc-toolset-12-gcc-c++
export PATH=/opt/rh/gcc-toolset-12/root/usr/bin:$PATH

yum install -y python3.11-devel python3.11-pip make cmake git openssl-devel \
    bzip2-devel libffi-devel zlib-devel libjpeg-devel freetype-devel \
    procps-ng meson ninja-build gcc-gfortran libomp-devel zip unzip \
    sqlite-devel autoconf automake libtool curl-devel atlas-devel patch \
    gcc-toolset-12 gcc-toolset-12-binutils gcc-toolset-12-binutils-devel \
    libxcrypt-compat rsync krb5-devel java-11-openjdk-devel

python3.11 -m pip install --upgrade pip
export GCC_HOME=/opt/rh/gcc-toolset-12/root/usr
export CC=$GCC_HOME/bin/gcc
export CXX=$GCC_HOME/bin/g++
export GCC=$CC
export GXX=$CXX

export PATH=$(echo $PATH | tr ':' '\n' | grep -v -e '/gcc-toolset' -e '/usr/bin/gcc' | tr '\n' ':')
export PATH=$GCC_HOME/bin:$PATH
export LD_LIBRARY_PATH=$(echo $LD_LIBRARY_PATH | tr ':' '\n' | grep -v -e '/gcc-toolset' | tr '\n' ':')
export LD_LIBRARY_PATH=$GCC_HOME/lib64:$LD_LIBRARY_PATH

ln -sf /opt/rh/gcc-toolset-12/root/usr/lib64/libctf.so.0 /usr/lib64/libctf.so.0

echo "-----------Installing OpenBLAS----------------"
cd $CURRENT_DIR
if [ ! -d "OpenBLAS" ]; then
    git clone https://github.com/OpenMathLib/OpenBLAS
    cd OpenBLAS
    git checkout v0.3.29
    git submodule update --init
    
    LDFLAGS=$(echo "${LDFLAGS}" | sed "s/-Wl,--gc-sections//g")
    export CF="${CFLAGS} -Wno-unused-parameter -Wno-old-style-declaration"
    unset CFLAGS
    export USE_OPENMP=1
    
    if [ ! -z "$FFLAGS" ]; then
        export FFLAGS="${FFLAGS/-fopenmp/ } -frecursive"
        export LAPACK_FFLAGS="${FFLAGS}"
    fi
    
    make USE_OPENMP=1 BINARY=64 DYNAMIC_ARCH=1 TARGET=POWER9 NO_LAPACK=0 USE_THREAD=1 NUM_THREADS=8 NO_AFFINITY=1 CFLAGS="${CF}" FFLAGS="${FFLAGS}" prefix=/usr/local/openblas
    make install PREFIX=/usr/local/openblas
fi
export OPENBLAS_PREFIX=/usr/local/openblas
export LD_LIBRARY_PATH=${OPENBLAS_PREFIX}/lib:$LD_LIBRARY_PATH
export PKG_CONFIG_PATH=${OPENBLAS_PREFIX}/lib/pkgconfig:$PKG_CONFIG_PATH

echo "---------------------Build HDF5 from source---------------------"
cd $CURRENT_DIR
if [ ! -d "hdf5" ]; then
    git clone https://github.com/HDFGroup/hdf5
    cd hdf5/
    git checkout hdf5-1_12_1
    ./configure --prefix=/usr/local/hdf5 --enable-cxx --enable-fortran --with-pthread=yes --enable-threadsafe --enable-build-mode=production --enable-unsupported --enable-using-memchecker --enable-clear-file-buffers --with-ssl
    make -j$(nproc)
    make install
fi
export HDF5_DIR=/usr/local/hdf5
export LD_LIBRARY_PATH=/usr/local/hdf5/lib:$LD_LIBRARY_PATH

echo "--------------Building Local Wheels for Bazel Sandbox----------------"
mkdir -p $WHEEL_DIR
cd $WHEEL_DIR
python3.11 -m pip install  --upgrade Cython numpy==1.26.4 wheel setuptools

# Build h5py wheel
python3.11 -m pip wheel h5py==3.10.0 numpy==1.26.4 --no-build-isolation --no-cache-dir

# Build grpcio wheel
export GRPC_PYTHON_BUILD_SYSTEM_OPENSSL=true
python3.11 -m pip wheel grpcio==1.59.3 --no-cache-dir --no-build-isolation

echo "------------------------Installing Bazel-------------------"
cd $CURRENT_DIR
if [ ! -f "/usr/local/bin/bazel" ]; then
    mkdir -p /bazel
    cd /bazel
    wget https://github.com/bazelbuild/bazel/releases/download/6.1.0/bazel-6.1.0-dist.zip
    unzip -q bazel-6.1.0-dist.zip
    export JAVA_HOME=/usr/lib/jvm/$(ls /usr/lib/jvm/ | grep -P '^(?=.*java-11)(?=.*ppc64le)')
    env EXTRA_BAZEL_ARGS="--tool_java_runtime_version=local_jdk" bash ./compile.sh
    cp output/bazel /usr/local/bin
fi
export PATH=/usr/local/bin:$PATH

echo "------------------------Installing System Python Deps-------------------"
python3.11 -m pip install --upgrade absl-py six==1.16.0 "urllib3<1.27" werkzeug
python3.11 -m pip install /local_wheels/h5py-*.whl /local_wheels/grpcio-*.whl

#installing patchelf from source
cd $CURRENT_DIR
yum install -y git autoconf automake libtool make
git clone https://github.com/NixOS/patchelf.git
cd patchelf
./bootstrap.sh
./configure
make
make install
ln -s /usr/local/bin/patchelf /usr/bin/patchelf
echo "-----------------------------------------------------Installed patchelf-----------------------------------------------------"


echo "------------------------Cloning TensorFlow-------------------"
cd $CURRENT_DIR
git clone $PACKAGE_URL
cd $PACKAGE_DIR
git checkout $PACKAGE_VERSION

bazel clean --expunge || true

mkdir -p $CURRENT_DIR/bazel-dist
cd $CURRENT_DIR/bazel-dist
wget -nc https://github.com/google/boringssl/archive/b9232f9e27e5668bc0414879dcdedb2a59ea75f2.tar.gz
cd $CURRENT_DIR/$PACKAGE_DIR

# Ensure environment vars are set before configure
export TF_PYTHON_VERSION="3.11"
export PYTHON_BIN_PATH=$(which python3.11)
export USE_DEFAULT_PYTHON_LIB_PATH=1
export TF_NEED_JEMALLOC=1
export TF_ENABLE_XLA=1
export TF_NEED_OPENCL=0
export TF_NEED_CUDA=0
export TF_NEED_MKL=0
export TF_NEED_VERBS=0
export TF_NEED_MPI=0
export TF_NEED_CLANG=0  # Forces configure to use our GCC 12 instead of Clang
export TF_NEED_ROCM=0   # Explicitly disables ROCm

yes "" | ./configure

sed -i "/python_aarch64/ s|! -path '\*python_aarch64\*'|! -path '*python_aarch64*' \\\n  ! -path '*python_ppc64le*'|" tensorflow/tools/pip_package/build_pip_package.sh
sed -i 's@cp -a external/ml_dtypes@cp -a external/ml_dtypes 2>/dev/null || true@g' tensorflow/tools/pip_package/build_pip_package.sh

#applying patch 
wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/t/tensorflow/tf_2.15.0_fix.patch
git apply tf_2.15.0_fix.patch

# Download the raw patch from the merged Pull Request
wget https://github.com/tensorflow/tensorflow/pull/62457.patch
# Apply the patch to your local source code
git apply 62457.patch

echo "------------------------Building TensorFlow-------------------"
if ! ( bazel build -s     --distdir=$CURRENT_DIR/bazel-dist     --config=opt     --define=llvm_enable_pdb=false    --action_env=HDF5_DIR=$HDF5_DIR     --action_env=HDF5_INCLUDEDIR=$HDF5_INCLUDEDIR     --action_env=HDF5_LIBDIR=$HDF5_LIBDIR   --copt="-Wno-stringop-overflow"  --host_copt="-Wno-stringop-overflow"  --local_ram_resources="HOST_RAM*.5" --jobs=4 //tensorflow/tools/pip_package:build_pip_package) ; then  
    echo "------------------$PACKAGE_NAME: Install Fails -------------------------------------"
    exit 1
fi

# 1. Create a directory to hold your shiny new wheel
mkdir -p ../tf_wheel_output

# 2. Run the Bazel-built script to generate the .whl file
./bazel-bin/tensorflow/tools/pip_package/build_pip_package ../tf_wheel_output

echo "----------wheel created----------------"

echo "---------------------------------Running tests----------------------------------------------"

# Create a temporary log file to capture output
TEST_LOG=$(mktemp)

bazel test --config=opt -k --jobs=$(nproc) //tensorflow/tools/pip_package/... 2>&1 | tee "$TEST_LOG"

# Capture actual Bazel exit code
TEST_EXIT_CODE=${PIPESTATUS[0]}

# Read full test output (if needed)
TEST_OUTPUT=$(cat "$TEST_LOG")

# Analyze test results
if echo "$TEST_OUTPUT" | grep -q "No test targets were found"; then
    echo "------------------$PACKAGE_NAME:no_test_targets_found---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Pass | No_Test_Targets_Found"
    exit 0
elif [ $TEST_EXIT_CODE -ne 0 ]; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_Success_But_Test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Pass | Both_Install_and_Test_Success"
    exit 0
fi
