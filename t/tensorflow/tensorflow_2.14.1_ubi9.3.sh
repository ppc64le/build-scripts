#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : tensorflow
# Version       : 2.14.1
# Source repo   : https://github.com/tensorflow/tensorflow
# Tested on     : UBI:9.3
# Language      : Python
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Stuti Wali <Stuti.Wali@ibm.com>
#
# Disclaimer: This script has been tested in root mode on the given
# platform using the mentioned version of the package.
# It may not work as expected with newer versions of the
# package and/or distribution. In such a case, please
# contact the "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

# Exit immediately if a command exits with a non-zero status
set -e

# Variables
PACKAGE_NAME=tensorflow
PACKAGE_VERSION=${1:-v2.14.1}
PACKAGE_URL=https://github.com/tensorflow/tensorflow
CURRENT_DIR=$(pwd)
PACKAGE_DIR=tensorflow

export LLVM_ENABLE_PDB=0


echo "------------------------Installing dependencies-------------------"
yum install -y wget
yum install -y gcc-toolset-12-gcc.ppc64le gcc-toolset-12-gcc-c++
export PATH=/opt/rh/gcc-toolset-12/root/usr/bin:$PATH

yum install -y python3.11-devel python3.11-pip make cmake wget git openssl-devel bzip2-devel libffi-devel zlib-devel  libjpeg-devel zlib-devel freetype-devel procps-ng meson ninja-build gcc-gfortran  libomp-devel zip unzip sqlite-devel sqlite 

yum install -y gcc-toolset-12 gcc-toolset-12-binutils gcc-toolset-12-binutils-devel
yum install -y libxcrypt-compat rsync
python3.11 -m pip install --upgrade pip



yum install -y  autoconf automake libtool curl-devel  atlas-devel patch 

echo "-----------installing openblas................"
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

echo "---------------------Build HDF5 from source---------------------"
cd $CURRENT_DIR
git clone https://github.com/HDFGroup/hdf5
cd hdf5/
git checkout hdf5-1_12_1
git submodule update --init
yum install -y zlib zlib-devel
./configure --prefix=/usr/local/hdf5 --enable-cxx --enable-fortran  --with-pthread=yes --enable-threadsafe  --enable-build-mode=production --enable-unsupported  --enable-using-memchecker  --enable-clear-file-buffers --with-ssl
make 
make install

export LD_LIBRARY_PATH=/usr/local/hdf5/:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=/usr/local/hdf5/lib/:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=/usr/local/hdf5/include:$LD_LIBRARY_PATH
export HDF5_DIR=/usr/local/hdf5
echo "-----------------------------------------------------Installed HDF5 to /usr/local-----------------------------------------------------"


echo "--------------Build and install h5py from source-----------------------"
cd $CURRENT_DIR
git clone https://github.com/h5py/h5py.git
cd h5py/
git checkout 3.13.0
python3.11 -m pip install --ignore-installed --force-reinstall "numpy<2"
python3.11 -m pip install .  

cd $CURRENT_DIR
python3.11 -c "import h5py; print(h5py.__version__)"
echo "-----------------------------------------------------Installed h5py-----------------------------------------------------"


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


echo "------------installing patchelf from source-----------"
cd $CURRENT_DIR
git clone https://github.com/alisw/libtirpc
cd libtirpc
yum install -y krb5-devel
./bootstrap
./configure --prefix=/usr/local
make -j$(nproc)
make install
ldconfig
export CPATH=/usr/local/include:$CPATH
export LIBRARY_PATH=/usr/local/lib:$LIBRARY_PATH
export CPATH=/usr/local/include:$CPATH
export LIBRARY_PATH=/usr/local/lib:$LIBRARY_PATH
ls /usr/local/include/tirpc/rpc/types.h

cd $CURRENT_DIR
#Set JAVA_HOME
echo "------------------------Installing java-------------------"
yum install -y java-11-openjdk-devel
export JAVA_HOME=/usr/lib/jvm/$(ls /usr/lib/jvm/ | grep -P '^(?=.*java-11)(?=.*ppc64le)')
export PATH=$JAVA_HOME/bin:$PATH

# Build Bazel dependency
echo "------------------------Installing bazel-------------------"
cd $CURRENT_DIR
mkdir -p /bazel
cd /bazel
wget https://github.com/bazelbuild/bazel/releases/download/6.1.0/bazel-6.1.0-dist.zip
unzip bazel-6.1.0-dist.zip
echo "------------------------Installing bazel-------------------"
env EXTRA_BAZEL_ARGS="--tool_java_runtime_version=local_jdk" bash ./compile.sh
cp output/bazel /usr/local/bin
export PATH=/usr/local/bin:$PATH
bazel --version
cd $CURRENT_DIR

# Install six.
echo "------------------------Installing dependencies-------------------"
python3.11 -m pip install --upgrade absl-py
python3.11 -m pip install --upgrade six==1.16.0
python3.11 -m pip install "numpy<2" "urllib3<1.27" wheel==0.38.4 werkzeug


# Install numpy, scipy and scikit-learn required by the builds
ln -s /usr/include/locale.h /usr/include/xlocale.h

#Build tensorflow
echo "------------------------Cloning tensorflow-------------------"
cd $CURRENT_DIR
git clone $PACKAGE_URL
cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION

echo "------------------------Exporting variable-------------------"
cpu_model=$(lscpu | grep "Model name:" | awk -F: '{print $2}' | tr '[:upper:]' '[:lower:]' | cut -d '(' -f1 | cut -d ',' -f1 | xargs)
export CC_OPT_FLAGS="-mcpu=${cpu_model} -mtune=${cpu_model}"
echo "CC_OPT_FLAGS set to: ${CC_OPT_FLAGS}"

export CC_OPT_FLAGS="-mcpu=${cpu_model} -mtune=${cpu_model}"
export TF_PYTHON_VERSION=$(python3.11 --version | awk '{print $2}' | cut -d. -f1,2)
export HERMETIC_PYTHON_VERSION=$(python3.11 --version | awk '{print $2}' | cut -d. -f1,2)
export PYTHON_BIN_PATH=$(which python3.11)
export GCC_HOST_COMPILER_PATH=$(which gcc)
export CC=$GCC_HOST_COMPILER_PATH
export PYTHON=$(which python3.11)
export SP_DIR=/root/tensorflow/tfenv/lib/python$(python3.11 --version | awk '{print $2}' | cut -d. -f1,2)/site-packages/
export USE_DEFAULT_PYTHON_LIB_PATH=1
export TF_NEED_JEMALLOC=1
export TF_ENABLE_XLA=1
export TF_NEED_OPENCL=0
export TF_NEED_CUDA=0
export TF_NEED_MKL=0
export TF_NEED_VERBS=0
export TF_NEED_MPI=0
export TF_CUDA_CLANG=0
export TFCI_WHL_NUMPY_VERSION=1
export CXXFLAGS="$(echo ${CXXFLAGS} | sed -e 's/ -fno-plt//')"
export CFLAGS="$(echo ${CFLAGS} | sed -e 's/ -fno-plt//')"

# Apply the patch
echo "------------------------Applying patch-------------------"
wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/t/tensorflow/tf_2.14.1_fix.patch
git apply tf_2.14.1_fix.patch
echo "------------Applied patch successfully---------------------"

yes n | ./configure

echo "------------------------Bazel query-------------------"
bazel query "//tensorflow/tools/pip_package:*"

#Install
if ! (bazel build -s //tensorflow/tools/pip_package:build_pip_package --config=opt) ; then  
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

echo "------------building the wheel----------"
bazel-bin/tensorflow/tools/pip_package/build_pip_package $CURRENT_DIR
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
