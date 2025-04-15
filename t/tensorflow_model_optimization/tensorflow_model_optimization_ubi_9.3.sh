#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : tensorflow-model-optimization
# Version       : v0.8.0
# Source repo   : https://github.com/tensorflow/model-optimization
# Tested on     : UBI 9.3
# Language      : Python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Anumala-Rajesh <Anumala.Rajesh@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -ex

# Variables
PACKAGE_NAME="model-optimization"
PACKAGE_VERSION="v0.8.0"
PACKAGE_URL="https://github.com/tensorflow/model-optimization"
CURRENT_DIR=$(pwd)

# install core dependencies
yum install -y wget python312 python3.12-devel python3.12-pip unzip cmake binutils openssl \
    gcc  gcc-c++ gcc-toolset-13 gcc-toolset-13-binutils gcc-toolset-13-binutils-devel gcc-toolset-13-gcc-c++ atlas \
    libevent-devel libjpeg-turbo-devel bzip2-devel zlib-devel xz pkgconfig

yum install -y libffi-devel openssl-devel sqlite-devel zip rsync

export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH
gcc --version

export GCC_HOME=/opt/rh/gcc-toolset-13/root/usr
export CC=$GCC_HOME/bin/gcc
export CXX=$GCC_HOME/bin/g++

yum install -y git autoconf automake libtool make

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

python3.12 -m pip install --upgrade pip

INSTALL_ROOT="/install-deps"
mkdir -p $INSTALL_ROOT


for package in openblas hdf5 abseil tensorflow ; do
    mkdir -p ${INSTALL_ROOT}/${package}
    export "${package^^}_PREFIX=${INSTALL_ROOT}/${package}"
    echo "Exported ${package^^}_PREFIX=${INSTALL_ROOT}/${package}"
done

python3.12 -m pip install numpy==2.0.2 cython setuptools wheel ninja

yum install -y java-11-openjdk-devel
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-11.0.25.0.9-3.el9.ppc64le
export JAVA_HOME=/usr/lib/jvm/$(ls /usr/lib/jvm/ | grep -P '^(?=.*java-)(?=.*ppc64le)')
export PATH=$JAVA_HOME/bin:$PATH

cd $CURRENT_DIR

echo " --------------------------------------------- Installing openblas --------------------------------------------- "

#installing openblas from source
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

echo " --------------------------------------------- openblas Successfully Installed --------------------------------------------- "

cd $CURRENT_DIR

echo " --------------------------------------------- Installing hdf5 --------------------------------------------- "

#Installing hdf5 from source
git clone https://github.com/HDFGroup/hdf5
cd hdf5/
git checkout hdf5-1_12_1
git submodule update --init

yum install -y zlib zlib-devel

./configure --prefix=$HDF5_PREFIX --enable-cxx --enable-fortran  --with-pthread=yes --enable-threadsafe  --enable-build-mode=production --enable-unsupported  --enable-using-memchecker  --enable-clear-file-buffers --with-ssl
make
make install PREFIX="${HDF5_PREFIX}"
export LD_LIBRARY_PATH=${HDF5_PREFIX}/lib:$LD_LIBRARY_PATH

echo " --------------------------------------------- hdf5 Successfully Installed --------------------------------------------- "

cd $CURRENT_DIR

echo " --------------------------------------------- Installing h5py --------------------------------------------- "

#Installing h5py from source
git clone https://github.com/h5py/h5py.git
cd h5py/
git checkout 3.13.0

HDF5_DIR=/install-deps/hdf5 python3.12 -m pip install .
cd $CURRENT_DIR
python3.12 -c "import h5py; print(h5py.__version__)"
echo " --------------------------------------------- h5py Successfully Installed --------------------------------------------- "

echo " --------------------------------------------- Installing abseil-cpp --------------------------------------------- "

#Installing abseil-cpp from source
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

echo " --------------------------------------------- abseil-cpp Successfully Installed --------------------------------------------- "

cd $CURRENT_DIR

echo " --------------------------------------------- Installing bazel --------------------------------------------- "

#Installing bazel from source
mkdir bazel
cd bazel
wget https://github.com/bazelbuild/bazel/releases/download/6.5.0/bazel-6.5.0-dist.zip
unzip bazel-6.5.0-dist.zip
env EXTRA_BAZEL_ARGS="--tool_java_runtime_version=local_jdk" bash ./compile.sh
cp output/bazel /usr/local/bin
export PATH=/usr/local/bin:$PATH
bazel --version

echo " --------------------------------------------- bazel Successfully Installed --------------------------------------------- "

cd $CURRENT_DIR

echo " --------------------------------------------- Installing ml_dtypes --------------------------------------------- "

#Installing ml_dtypes from source
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
echo " --------------------------------------------- ml_dtypes Successfully Installed --------------------------------------------- "

echo " --------------------------------------------- Installing Patchelf --------------------------------------------- "

#installing patchelf from source
git clone https://github.com/NixOS/patchelf.git
cd patchelf
./bootstrap.sh
./configure
make
make install
ln -s /usr/local/bin/patchelf /usr/bin/patchelf

echo " --------------------------------------------- Patchelf Successfully Installed --------------------------------------------- "

cd $CURRENT_DIR

echo " --------------------------------------------- Installing Numpy --------------------------------------------- "

#Installing Numpy from source
git clone https://github.com/numpy/numpy.git
cd  numpy
git checkout v2.0.2
git submodule update --init

EXTRA_OPTS=""
export GCC_HOME=/opt/rh/gcc-toolset-13/root/usr
echo $GCC_HOME

export PATH=$GCC_HOME/bin:$PATH
export CC=$GCC_HOME/bin/gcc
export CXX=$GCC_HOME/bin/g++
export GCC=$CC
export GXX=$CXX
export AR=${GCC_HOME}/bin/ar
export LD=${GCC_HOME}/bin/ld
export NM=${GCC_HOME}/bin/nm
export OBJCOPY=${GCC_HOME}/bin/objcopy
export OBJDUMP=${GCC_HOME}/bin/objdump
export RANLIB=${GCC_HOME}/bin/ranlib
export STRIP=${GCC_HOME}/bin/strip
export READELF=${GCC_HOME}/bin/readelf
UNAME_M=$(uname -m)
case "$UNAME_M" in
    ppc64*)
        # Optimizations trigger compiler bug.
         export CXXFLAGS="$(echo ${CXXFLAGS} | sed -e 's/ -fno-plt//')"
         export CFLAGS="$(echo ${CFLAGS} | sed -e 's/ -fno-plt//')"
        ;;
    *)
        EXTRA_OPTS=""
        ;;
esac

python3.12 -m pip install .

echo " --------------------------------------------- Numpy Successfully Installed --------------------------------------------- "

cd $CURRENT_DIR

echo " --------------------------------------------- Installing Scipy --------------------------------------------- "

#Installing Scipy from source
git clone https://github.com/scipy/scipy
cd scipy
git checkout v1.15.2
git submodule update --init --recursive

export OpenBLAS_HOME="/usr/include/openblas"

python3.12 -m pip install .

echo " --------------------------------------------- Scipy Successfully Installed --------------------------------------------- "

cd $CURRENT_DIR

echo " --------------------------------------------- Installing dm-tree --------------------------------------------- "

#Installing dm-tree from source
git clone https://github.com/google-deepmind/tree
cd tree/
git checkout 0.1.9

pip3.12 install --upgrade pip setuptools wheel

# install scikit-learn dependencies and build dependencies
pip3.12 install pytest absl-py attr numpy wrapt attrs

#Download and apply the patch file
wget https://raw.githubusercontent.com/JeSh30/build-scripts/refs/heads/tfmo-dm-tree-patch/d/dm-tree/updated_abseil_version.patch
git apply updated_abseil_version.patch

python3.12 setup.py build_ext --inplace

echo " --------------------------------------------- dm-tree Successfully Installed --------------------------------------------- "

cd $CURRENT_DIR

echo " --------------------------------------------- Installing grpcio --------------------------------------------- "

#Installing grpcio from source
git clone https://github.com/grpc/grpc.git
cd grpc
git checkout v1.70.0
git submodule update --init --recursive

python3.12 -m pip install pytest hypothesis build six
python3.12 -m pip install -r requirements.txt

GRPC_PYTHON_BUILD_SYSTEM_OPENSSL=1 python3.12 -m pip install -e .

echo " --------------------------------------------- grpcio Successfully Installed --------------------------------------------- "

cd $CURRENT_DIR

echo " --------------------------------------------- Installing Tensorflow --------------------------------------------- "

# Set CPU optimization flags
export cpu_opt_arch="power9"
export cpu_opt_tune="power10"
export build_type="cpu"
echo "CPU Optimization Settings:"
echo "cpu_opt_arch=${cpu_opt_arch}"
echo "cpu_opt_tune=${cpu_opt_tune}"
echo "build_type=${build_type}"

SHLIB_EXT=".so"
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
git clone https://github.com/tensorflow/tensorflow
cd tensorflow
git checkout v2.18.1

wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/python-ecosystem/t/tensorflow/tf_2.18.1_fix.patch
git apply tf_2.18.1_fix.patch

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
echo " --------------------------------------------- Bazelrc dir : ${BAZEL_RC_DIR} --------------------------------------------- "
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

echo " --------------------------------------------- Created bazelrc --------------------------------------------- "

export BUILD_TARGET="//tensorflow/tools/pip_package:wheel //tensorflow/tools/lib_package:libtensorflow //tensorflow:libtensorflow_cc${SHLIB_EXT}"

echo " --------------------------------------------- Tensorflow Test and Install --------------------------------------------- "

#Install
if ! (bazel --bazelrc=$BAZEL_RC_DIR/tensorflow.bazelrc build --local_cpu_resources=HOST_CPUS*0.50 --local_ram_resources=HOST_RAM*0.50 --config=opt ${BUILD_TARGET}) ; then
    echo " ------------------------ Tensorflow:Install_fails ------------------------ "
    echo "https://github.com/tensorflow/tensorflow tensorflow"
    echo "tensorflow |  https://github.com/tensorflow/tensorflow | v2.18.1 | GitHub | Fail |  Install_Fails"
    exit 1
fi

echo " --------------------------------------------- Tensorflow Successfully Installed --------------------------------------------- "

cd $CURRENT_DIR

export OUTPUT_DIR=$CURRENT_DIR

pip config set global.find-links file://${OUTPUT_DIR}
ARCH=`uname -p`
if [[ $ARCH = "ppc64le" ]]; then
  # Install prerequisite wheels
  pip3.12 install setuptools wheel
  pip3.12 list

  export LD_LIBRARY_PATH="${OPENBLAS_PREFIX}/lib:${HDF5_PREFIX}/lib:${ABSEIL_PREFIX}/abseil-cpp/lib:$LD_LIBRARY_PATH"
  export PKG_CONFIG_PATH="$OPENBLAS_PREFIX/lib/pkgconfig:${PKG_CONFIG_PATH}"
else
  pip3.12 install numpy==2.0.2 setuptools wheel
fi

#Clone Source-code
git clone $PACKAGE_URL -b $PACKAGE_VERSION
cd $PACKAGE_NAME
sed -i "s/numpy~=1.23/numpy==2.0.2/g" setup.py
sed -i "s/numpy~=1.23.0/numpy==2.0.2/g" requirements.txt

echo " --------------------------------------------- Wheel Build Started --------------------------------------------- "

#Start building
echo "$PACKAGE build starts!!"
python3.12 setup.py bdist_wheel --release --dist-dir $OUTPUT_DIR

#wheel rename with arch
# update_platform_tag tensorflow_model_optimization    -----> getting error from here command not found error

if ! python3.12 setup.py install; then
    echo " ------------------------ $PACKAGE_NAME :wheel_built_fails ------------------------ "
    echo "$PACKAGE_VERSION $PACKAGE_NAME"
    echo " $PACKAGE_NAME | $PACKAGE_VERSION | $PACKAGE_URL | GitHub | Fail |  wheel_built_fails"
    exit 1
fi

echo " --------------------------------------------- Wheel Build Completed --------------------------------------------- "


ARCH=`uname -p`
if [ $ARCH = "ppc64le" ]; then
  # Install prerequisite wheels
  #  pip install keras
  pip3.12 install tf_keras
  pip3.12 install tensorflow_model_optimization==0.8.0
  pip3.12 install setuptools wheel
  pip3.12 list

  export LD_LIBRARY_PATH="${OPENBLAS_PREFIX}/lib:${HDF5_PREFIX}/lib"
  export LD_LIBRARY_PATH="${OPENBLAS_PREFIX}/lib:${HDF5_PREFIX}/lib:$LD_LIBRARY_PATH"
  export PKG_CONFIG_PATH="$OPENBLAS_PREFIX/lib/pkgconfig:${PKG_CONFIG_PATH}"
else
  pip3.12 install -r requirements_x86.txt
  pip3.12 install numpy==2.0.2 tensorflow_cpu==2.18.1 tf-keras==2.18.0
  pip3.12 install tensorflow_model_optimization
fi

#Import check
# python3.12 -c "import tensorflow_model_optimization; print(tensorflow_model_optimization.__version__)"

if [ $? == 0 ]; then
    echo " ------------------------ $PACKAGE_NAME:Both_Install_and_Test_Success ------------------------ "
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Pass |  Both_Install_and_Test_Success"
    exit 0
else
    echo " ------------------------ $PACKAGE_NAME:Install_success_but_test_Fails ------------------------ "
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Fail |  Install_success_but_test_Fails"
    exit 2
fi

cd $CURRENT_DIR
