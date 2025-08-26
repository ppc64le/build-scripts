#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : tensorflow
# Version       : v2.20.0
# Source repo   : https://github.com/tensorflow/tensorflow
# Tested on     : UBI 9.3
# Language      : C
# Travis-Check  : True
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

set -ex 

PACKAGE_NAME=tensorflow
PACKAGE_VERSION=${1:-v2.20.0}
PACKAGE_URL=https://github.com/tensorflow/tensorflow
CURRENT_DIR=$(pwd)
PACKAGE_DIR=tensorflow

# install core dependencies
yum install -y wget python3.12 python3.12-pip python3.12-devel  gcc-toolset-13 gcc-toolset-13-binutils gcc-toolset-13-binutils-devel gcc-toolset-13-gcc-c++ git make cmake binutils libjpeg-devel

yum install -y libffi-devel openssl-devel sqlite-devel zip rsync

export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH
gcc --version

export GCC_HOME=/opt/rh/gcc-toolset-13/root/usr
export CC=$GCC_HOME/bin/gcc
export CXX=$GCC_HOME/bin/g++


OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

python3.12 -m pip install --upgrade pip

INSTALL_ROOT="/install-deps"
mkdir -p $INSTALL_ROOT

for package in openblas hdf5 abseil tensorflow ; do
    mkdir -p ${INSTALL_ROOT}/${package}
    export "${package^^}_PREFIX=${INSTALL_ROOT}/${package}"
    echo "Exported ${package^^}_PREFIX=${INSTALL_ROOT}/${package}"
done

python3.12 -m pip install cython setuptools wheel ninja

yum install -y java-21-openjdk-devel java-21-openjdk java-21-openjdk-headless
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk
export PATH=$PATH:$JAVA_HOME/bin


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

echo "Installing Numpy"
python3.12 -m pip install numpy==2.0.2

#Build hdf5 from source
cd $CURRENT_DIR
git clone https://github.com/HDFGroup/hdf5
cd hdf5/
git checkout hdf5-1_12_1
git submodule update --init

yum install -y zlib zlib-devel

./configure --prefix=$HDF5_PREFIX --enable-cxx --enable-fortran  --with-pthread=yes --enable-threadsafe  --enable-build-mode=production --enable-unsupported  --enable-using-memchecker  --enable-clear-file-buffers --with-ssl
make 
make install PREFIX="${HDF5_PREFIX}"
export LD_LIBRARY_PATH=${HDF5_PREFIX}/lib:$LD_LIBRARY_PATH
echo "-----------------------------------------------------Installed hdf5-----------------------------------------------------"


#Build h5py from source
cd $CURRENT_DIR
git clone https://github.com/h5py/h5py.git
cd h5py/
git checkout 3.13.0

HDF5_DIR=/install-deps/hdf5 python3.12 -m pip install .
cd $CURRENT_DIR
python3.12 -c "import h5py; print(h5py.__version__)"
echo "-----------------------------------------------------Installed h5py-----------------------------------------------------"



#Build abseil-cpp from source
cd $CURRENT_DIR
git clone https://github.com/abseil/abseil-cpp
cd abseil-cpp
git checkout 20240116.2

mkdir build
cd build

cmake -G Ninja \
    ${CMAKE_ARGS} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_STANDARD=17 \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_INSTALL_PREFIX=${ABSEIL_PREFIX} \
    -DBUILD_SHARED_LIBS=ON \
    -DABSL_PROPAGATE_CXX_STD=ON \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
   ..

cmake --build .
cmake --install .
export LD_LIBRARY_PATH=${ABSEIL_PREFIX}/lib:$LD_LIBRARY_PATH
export PKG_CONFIG_PATH=${ABSEIL_PREFIX}/lib/pkgconfig:$PKG_CONFIG_PATH
echo "-----------------------------------------------------Installed abseil-cpp-----------------------------------------------------"



#Build bazel from source
cd $CURRENT_DIR
mkdir bazel
cd bazel
wget https://github.com/bazelbuild/bazel/releases/download/7.4.1/bazel-7.4.1-dist.zip
unzip bazel-7.4.1-dist.zip
env EXTRA_BAZEL_ARGS="--tool_java_runtime_version=local_jdk" bash ./compile.sh
cp output/bazel /usr/local/bin
export PATH=/usr/local/bin:$PATH
bazel --version
echo "-----------------------------------------------------Installed bazel-----------------------------------------------------"

#Build ml_dtypes from source
cd $CURRENT_DIR
git clone https://github.com/jax-ml/ml_dtypes.git
cd ml_dtypes
git checkout v0.4.1
git submodule update --init

export CFLAGS="-I${ML_DIR}/include"
export CXXFLAGS="-I${ML_DIR}/include"
export CC=/opt/rh/gcc-toolset-13/root/bin/gcc
export CXX=/opt/rh/gcc-toolset-13/root/bin/g++

python3.12 -m pip install .
cd $CURRENT_DIR
python3.12 -c "import ml_dtypes; print(ml_dtypes.__version__)"
echo "-----------------------------------------------------Installed ml_dtypes-----------------------------------------------------"


# Set CPU optimization flags
export cpu_opt_arch="power9"
export cpu_opt_tune="power10"
export build_type="cpu"
echo "CPU Optimization Settings:"
echo "cpu_opt_arch=${cpu_opt_arch}"
echo "cpu_opt_tune=${cpu_opt_tune}"
echo "build_type=${build_type}"

WORK_DIR=$(pwd)

export TF_PYTHON_VERSION=$(python3.12 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
export HERMETIC_PYTHON_VERSION=$(python3.12 --version | awk '{print $2}' | cut -d. -f1,2)
export GCC_HOST_COMPILER_PATH=$(which gcc)
export CC=$GCC_HOST_COMPILER_PATH

# set the variable, when grpcio fails to compile on the system. 
export GRPC_PYTHON_BUILD_SYSTEM_OPENSSL=true;  
export LDFLAGS="${LDFLAGS} -lrt"
export HDF5_DIR=/install-deps/hdf5
export CFLAGS="-I${HDF5_DIR}/include"
export LDFLAGS="-L${HDF5_DIR}/lib"

# clone source repository
cd $CURRENT_DIR
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
SRC_DIR=$(pwd)

wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/t/tensorflow/tf_2.20.0_fix.patch
git apply tf_2.20.0_fix.patch

# Pick up additional variables defined from the conda build environment
export PYTHON_BIN_PATH=$(which python3.12)
export USE_DEFAULT_PYTHON_LIB_PATH=1

# Build the bazelrc
BAZEL_RC_DIR=$(pwd)/tensorflow
ARCH=`uname -p`
XNNPACK_STATUS=false
NL=$'\n'
BUILD_COPT="build:opt --copt="
BUILD_HOST_COPT="build:opt --host_copt="
CPU_ARCH_FRAG="-mcpu=${cpu_opt_arch}"
CPU_ARCH_OPTION=${BUILD_COPT}${CPU_ARCH_FRAG}
CPU_ARCH_HOST_OPTION=${BUILD_HOST_COPT}${CPU_ARCH_FRAG}
CPU_TUNE_FRAG="-mtune=${cpu_opt_tune}";
CPU_TUNE_OPTION=${BUILD_COPT}${CPU_TUNE_FRAG}
CPU_TUNE_HOST_OPTION=${BUILD_HOST_COPT}${CPU_TUNE_FRAG}

USE_MMA=0
echo "--------------------------------Bazelrc dir : ${BAZEL_RC_DIR}----------------------------------"
TENSORFLOW_PREFIX=/install-deps/tensorflow

cat > $BAZEL_RC_DIR/python_configure.bazelrc << EOF
build --action_env PYTHON_BIN_PATH="$(which python3.12)"
build --action_env PYTHON_LIB_PATH="/usr/lib/python3.12/site-packages"
build --python_path="$(which python3.12)"
EOF

SYSTEM_LIBS_PREFIX=$TENSORFLOW_PREFIX
cat >> $BAZEL_RC_DIR/tensorflow.bazelrc << EOF
import %workspace%/tensorflow/python_configure.bazelrc
build:xla --define with_xla_support=true
build --config=xla
${CPU_ARCH_OPTION}
${CPU_ARCH_HOST_OPTION}
${CPU_TUNE_OPTION}
${CPU_TUNE_HOST_OPTION}
${VEC_OPTIONS}
build:opt --define with_default_optimizations=true

build --action_env TF_CONFIGURE_IOS="0"
build --action_env TF_SYSTEM_LIBS="org_sqlite"
build --action_env GCC_HOME="/opt/rh/gcc-toolset-13/root/usr"
build --action_env RULES_PYTHON_PIP_ISOLATED="0"
build --define=PREFIX="$SYSTEM_LIBS_PREFIX"
build --define=LIBDIR="$SYSTEM_LIBS_PREFIX/lib"
build --define=INCLUDEDIR="$SYSTEM_LIBS_PREFIX/include"
build --define=tflite_with_xnnpack="$XNNPACK_STATUS"
build --copt="-DEIGEN_ALTIVEC_ENABLE_MMA_DYNAMIC_DISPATCH=$USE_MMA"
build --strip=always
build --color=yes
build --verbose_failures
build --spawn_strategy=standalone
EOF

echo "----------------------------------Created bazelrc-----------------------------------"

export BUILD_TARGET="//tensorflow/tools/pip_package:wheel"

#Install
if ! (bazel --bazelrc=$BAZEL_RC_DIR/tensorflow.bazelrc build --local_cpu_resources=HOST_CPUS*0.50 --local_ram_resources=HOST_RAM*0.50 --config=opt ${BUILD_TARGET}) ; then  
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

echo "-------------------------------tensroflow installation successful-------------------------------------"


find ./bazel-bin/tensorflow/tools/pip_package/wheel_house -iname "*.whl" -exec cp {} $CURRENT_DIR  \;

# Run tests for the pip_package directory
if ! (bazel test  -k  //tensorflow/tools/pip_package/...); then
    # Check if the failure is specifically due to "No test targets were found"
    if bazel test  -k  //tensorflow/tools/pip_package/... 2>&1 | grep -q "No test targets were found"; then
        echo "------------------$PACKAGE_NAME:no_test_targets_found---------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Pass | No_Test_Targets_Found"
        exit 0  # Graceful exit for no test targets
    fi
    # Handle actual test errors
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_Success_But_Test_Fails"
    exit 2
else
    # Tests ran successfully
    echo "------------------$PACKAGE_NAME:install_&_test_both_success------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Pass | Both_Install_and_Test_Success"
    exit 0
fi
