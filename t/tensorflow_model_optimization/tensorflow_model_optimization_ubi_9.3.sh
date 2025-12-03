#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : tensorflow_model_optimization
# Version       : v0.8.0
# Source repo   : https://github.com/tensorflow/model-optimization
# Tested on     : UBI 9.3
# Language      : Python
# Ci-Check  : True
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
PACKAGE_NAME=tensorflow_model_optimization
PACKAGE_VERSION="v0.8.0"
PACKAGE_URL="https://github.com/tensorflow/model-optimization"
CURRENT_DIR=$(pwd)
PACKAGE_DIR=model-optimization

# install core dependencies
yum install -y wget python312 python3.12-devel python3.12-pip unzip cmake binutils openssl \
    gcc  gcc-c++ gcc-toolset-13 gcc-toolset-13-binutils gcc-toolset-13-binutils-devel gcc-toolset-13-gcc-c++ atlas \
    libevent-devel libjpeg-turbo-devel bzip2-devel zlib-devel xz pkgconfig

yum install -y libffi-devel openssl-devel sqlite-devel zip rsync

export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH
gcc --version

GCC_BIN_DIR=$(echo "$PATH" | cut -d':' -f1)
export GCC_HOME=$(dirname "$GCC_BIN_DIR")
export CC="$GCC_BIN_DIR/gcc"
export CXX="$GCC_BIN_DIR/g++"

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

python3.12 -m pip install cython setuptools wheel ninja

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

echo "Installing NumPy"
python3.12 -m pip install numpy==2.0.2

echo " --------------------------------------------- Installing hdf5 --------------------------------------------- "

#Installing hdf5 from source
echo "------HDF5 installing-----------------------"
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

python3.12 -m pip install .
cd $CURRENT_DIR
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
pip3.12 install scipy==1.15.2
echo " --------------------------------------------- Installing dm-tree --------------------------------------------- "

#Installing dm-tree from source
git clone https://github.com/google-deepmind/tree
cd tree/
git checkout 0.1.9
pip3.12 install --upgrade pip
# install scikit-learn dependencies and build dependencies
pip3.12 install pytest absl-py attr wrapt attrs

#Download and apply the patch file
wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/d/dm-tree/updated_abseil_version.patch
git apply updated_abseil_version.patch

python3.12 setup.py build_ext --inplace

echo " --------------------------------------------- dm-tree Successfully Installed --------------------------------------------- "

cd $CURRENT_DIR

echo " --------------------------------------------- Installing grpcio --------------------------------------------- "

git clone https://github.com/grpc/grpc.git
cd grpc
git checkout v1.70.0
git submodule update --init --recursive

python3.12 -m pip install pytest hypothesis build six

# Install requirements
python3.12 -m pip install "coverage>=4.0" "cython>=0.29.8,<3.0.0" "wheel>=0.29"

# Install the package
GRPC_PYTHON_BUILD_SYSTEM_OPENSSL=1 python3.12 -m pip install -e .
echo "-----------------------------------------------------Installed grpcio-----------------------------------------------------"

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

PYTHON_VERSION=$(python3.12 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
export TF_PYTHON_VERSION=$PYTHON_VERSION
export HERMETIC_PYTHON_VERSION=$PYTHON_VERSION
export GCC_HOST_COMPILER_PATH=$CC

# set the variable, when grpcio fails to compile on the system. 
export GRPC_PYTHON_BUILD_SYSTEM_OPENSSL=true;  
export LDFLAGS="${LDFLAGS} -lrt"
export HDF5_DIR=/install-deps/hdf5
export CFLAGS="-I${HDF5_DIR}/include"
export LDFLAGS="-L${HDF5_DIR}/lib"

# clone source repository
cd $CURRENT_DIR
git clone  https://github.com/tensorflow/tensorflow
cd tensorflow
git checkout v2.18.1
SRC_DIR=$(pwd)

wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/t/tensorflow/tf_2.18.1_fix.patch
git apply tf_2.18.1_fix.patch
rm -rf tensorflow/*.bazelrc

# Pick up additional variables defined from the conda build environment
export PYTHON_BIN_PATH="$(which python3.12)"
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

TENSORFLOW_PREFIX=/install-deps/tensorflow
PYTHON_LIB_PATH=$($PYTHON_BIN_PATH -c 'import site; print(site.getsitepackages()[0])')

cat > "$BAZEL_RC_DIR/python_configure.bazelrc" << EOF
build --action_env PYTHON_BIN_PATH="$PYTHON_BIN_PATH"
build --action_env PYTHON_LIB_PATH="$PYTHON_LIB_PATH"
build --python_path="$PYTHON_BIN_PATH"
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
build --action_env GCC_HOME=$GCC_HOME
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


export BUILD_TARGET="//tensorflow/tools/pip_package:wheel //tensorflow/tools/lib_package:libtensorflow //tensorflow:libtensorflow_cc${SHLIB_EXT}"

#Install
if ! (bazel --bazelrc=tensorflow/tensorflow.bazelrc build --local_cpu_resources=HOST_CPUS*0.50 --local_ram_resources=HOST_RAM*0.50 --config=opt ${BUILD_TARGET}) ; then  
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

#copying .so and .a files into local/tensorflow/lib
mkdir -p $SRC_DIR/tensorflow_pkg
mkdir -p $SRC_DIR/local
find ./bazel-bin/tensorflow/tools/pip_package/wheel_house -iname "*.whl" -exec cp {} $SRC_DIR/tensorflow_pkg  \;
unzip -n $SRC_DIR/tensorflow_pkg/*.whl -d ${SRC_DIR}/local
mkdir -p ${SRC_DIR}/local/tensorflow/lib
find  ${SRC_DIR}/local/tensorflow  -type f \( -name "*.so*" -o -name "*.a" \) -exec cp {} ${SRC_DIR}/local/tensorflow/lib \;

#Build libtensorflow and libtensorflow_cc artifacts
mkdir -p $SRC_DIR/libtensorflow_extracted
tar -xzf $SRC_DIR/bazel-bin/tensorflow/tools/lib_package/libtensorflow.tar.gz -C $SRC_DIR/libtensorflow_extracted
mkdir -p ${SRC_DIR}/local/tensorflow/include
rsync -a  $SRC_DIR/libtensorflow_extracted/lib/*.so*  ${SRC_DIR}/local/tensorflow/lib 
cp -d -r $SRC_DIR/libtensorflow_extracted/include/* ${SRC_DIR}/local/tensorflow/include

mkdir -p $SRC_DIR/libtensorflow_cc_output/lib
mkdir -p $SRC_DIR/libtensorflow_cc_output/include
cp -d  bazel-bin/tensorflow/libtensorflow_cc.so* $SRC_DIR/libtensorflow_cc_output/lib/
cp -d  bazel-bin/tensorflow/libtensorflow_framework.so* $SRC_DIR/libtensorflow_cc_output/lib/
cp -d  $SRC_DIR/libtensorflow_cc_output/lib/libtensorflow_framework.so.2 ./libtensorflow_cc_output/lib/libtensorflow_framework.so

chmod u+w $SRC_DIR/libtensorflow_cc_output/lib/libtensorflow*


mkdir -p $SRC_DIR/libtensorflow_cc_output/include/tensorflow
rsync -r --chmod=D777,F666 --exclude '_solib*' --exclude '_virtual_includes/' --exclude 'pip_package/' --exclude 'lib_package/' --include '*/' --include '*.h' --include '*.inc' --exclude '*' bazel-bin/ $SRC_DIR/libtensorflow_cc_output/include
rsync -r --chmod=D777,F666 --include '*/' --include '*.h' --include '*.inc' --exclude '*' tensorflow/cc $SRC_DIR/libtensorflow_cc_output/include/tensorflow/
rsync -r --chmod=D777,F666 --include '*/' --include '*.h' --include '*.inc' --exclude '*' tensorflow/core $SRC_DIR/libtensorflow_cc_output/include/tensorflow/
rsync -r --chmod=D777,F666 --include '*/' --include '*.h' --include '*.inc' --exclude '*' third_party/xla/third_party/tsl/ $SRC_DIR/libtensorflow_cc_output/include/
rsync -r --chmod=D777,F666 --include '*/' --include '*' --exclude '*.cc' third_party/ $SRC_DIR/libtensorflow_cc_output/include/tensorflow/third_party/
rsync -a $SRC_DIR/libtensorflow_cc_output/include/*  ${SRC_DIR}/local/tensorflow/include
rsync -a $SRC_DIR/libtensorflow_cc_output/lib/*.so ${SRC_DIR}/local/tensorflow/lib

mkdir -p repackged_wheel

# Pack the locally built TensorFlow files into a wheel
wheel pack local/ -d repackged_wheel
cp -a $SRC_DIR/repackged_wheel/*.whl $CURRENT_DIR
cd $CURRENT_DIR
pip3.12 install *.whl

echo " --------------------------------------------- Tensorflow Successfully Installed --------------------------------------------- "

cd $CURRENT_DIR

export OUTPUT_DIR=$CURRENT_DIR

#Clone Source-code
git clone $PACKAGE_URL -b $PACKAGE_VERSION
cd $PACKAGE_DIR
sed -i "s/numpy~=1.23/numpy==2.0.2/g" setup.py
sed -i "s/numpy~=1.23.0/numpy==2.0.2/g" requirements.txt
sed -i "s/absl-py~=1.2/absl-py~=2.3/g" setup.py
sed -i "s/absl-py~=1.2/absl-py~=2.3/g" requirements.txt
echo " --------------------------------------------- Wheel Build Started --------------------------------------------- "

#Start building
echo "$PACKAGE build starts!!"
python3.12 setup.py bdist_wheel --release --dist-dir $OUTPUT_DIR

if ! python3.12 setup.py install; then
    echo " ------------------------ $PACKAGE_NAME :wheel_built_fails ------------------------ "
    echo "$PACKAGE_VERSION $PACKAGE_NAME"
    echo " $PACKAGE_NAME | $PACKAGE_VERSION | $PACKAGE_URL | GitHub | Fail |  wheel_built_fails"
    exit 1
fi

echo " --------------------------------------------- Wheel Build Completed --------------------------------------------- "
echo "There are no test cases available. skipping the test cases"
python3.12 -m pip install tf_keras
python3.12 -c "import tensorflow_model_optimization; print(tensorflow_model_optimization.__version__)" 

if [ $? -eq 0 ]; then
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
