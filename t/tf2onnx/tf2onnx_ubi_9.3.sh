#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : tf2onnx
# Version       : v1.16.1
# Source repo   : https://github.com/onnx/tensorflow-onnx
# Tested on     : UBI 9.3
# Language      : c
# Travis-Check  : True
# Script License: Apache License 2.0
# Maintainer    : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
set -ex 

PACKAGE_NAME=tf2onnx
PACKAGE_VERSION=${1:-v1.16.1}
PACKAGE_URL=https://github.com/onnx/tensorflow-onnx
CURRENT_DIR=$(pwd)
PACKAGE_DIR=tensorflow-onnx

# install core dependencies
yum install -y wget gcc-toolset-13 gcc-toolset-13-binutils gcc-toolset-13-binutils-devel gcc-toolset-13-gcc-c++ git make binutils  openssl openssl-devel clang libevent-devel zlib-devel openssl-devel python3.12 python3.12-devel python3.12-pip patch tar
yum install -y libffi-devel openssl-devel sqlite-devel zip rsync

export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH
GCC_BIN_DIR=$(echo "$PATH" | cut -d':' -f1)
export GCC_HOME=$(dirname "$GCC_BIN_DIR")
export CC="$GCC_BIN_DIR/gcc"
export CXX="$GCC_BIN_DIR/g++"

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

python3.12 -m pip install --upgrade pip

INSTALL_ROOT="/install-deps"
mkdir -p $INSTALL_ROOT


for package in openblas hdf5 tensorflow ; do
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

# Patchelf Installing from source
echo " --------------------------------- Installing patchelf from source --------------------------------- "
yum install -y git autoconf automake libtool make
 
git clone https://github.com/NixOS/patchelf.git
cd patchelf
./bootstrap.sh
./configure
make -j$(nproc)
make install
ln -s /usr/local/bin/patchelf /usr/bin/patchelf

echo " --------------------------------- Patchelf Successfully Installed --------------------------------- "

cd $CURRENT_DIR

# Installing Cmake from source
echo " --------------------------------- Installing Cmake --------------------------------- "

wget https://cmake.org/files/v3.28/cmake-3.28.0.tar.gz
tar -zxvf cmake-3.28.0.tar.gz
cd cmake-3.28.0
./bootstrap
make
make install

echo " --------------------------------- Cmake Successfully Installed --------------------------------- "

cd $CURRENT_DIR

#Installing OpenBlas
echo " --------------------------------- OpenBlas Installing --------------------------------- "

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

echo " --------------------------------- OpenBlas Successfully Installed  --------------------------------- "

cd $CURRENT_DIR 

# Installing Hdf5 from source
echo " --------------------------------- Hdf5 Installing --------------------------------- "

git clone https://github.com/HDFGroup/hdf5
cd hdf5/
git checkout hdf5-1_12_1
git submodule update --init

yum install -y zlib zlib-devel

./configure --prefix=$HDF5_PREFIX --enable-cxx --enable-fortran  --with-pthread=yes --enable-threadsafe  --enable-build-mode=production --enable-unsupported  --enable-using-memchecker  --enable-clear-file-buffers --with-ssl
make 
make install PREFIX="${HDF5_PREFIX}"
export LD_LIBRARY_PATH=${HDF5_PREFIX}/lib:$LD_LIBRARY_PATH

echo " --------------------------------- Hdf5 Successfully Installed --------------------------------- "

cd $CURRENT_DIR

#Build h5py from source
echo " --------------------------------- H5py Installing --------------------------------- "

git clone https://github.com/h5py/h5py.git
cd h5py/
git checkout 3.13.0

HDF5_DIR=/install-deps/hdf5 python3.12 -m pip install .

cd $CURRENT_DIR

python3.12 -c "import h5py; print(h5py.__version__)"
echo " --------------------------------- H5py Successfully Installed --------------------------------- "

export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH
python3.12 -m pip install --upgrade pip setuptools wheel ninja packaging tox pytest build mypy stubs

#Build abseil-cpp from source
echo " --------------------------------- Abseil-Cpp Cloning --------------------------------- "

# Set ABSEIL_VERSION and ABSEIL_URL
ABSEIL_VERSION=20240116.2
ABSEIL_URL="https://github.com/abseil/abseil-cpp"

git clone $ABSEIL_URL -b $ABSEIL_VERSION 

echo " --------------------------------- Abseil-Cpp Cloned --------------------------------- "

cd $CURRENT_DIR

export C_COMPILER=$(which gcc) CXX_COMPILER=$(which g++)
echo "C Compiler set to $C_COMPILER"
echo "CXX Compiler set to $CXX_COMPILER"

mkdir -p $(pwd)/local/libprotobuf
LIBPROTO_INSTALL=$(pwd)/local/libprotobuf
echo "LIBPROTO_INSTALL set to $LIBPROTO_INSTALL"

# Clone Source-code 
echo " --------------------------------- Libprotobuf Installing --------------------------------- "

PACKAGE_VERSION_LIB="v4.25.3"
PACKAGE_GIT_URL="https://github.com/protocolbuffers/protobuf"
git clone $PACKAGE_GIT_URL -b $PACKAGE_VERSION_LIB

# Build libprotobuf
echo "protobuf build starts!!"
cd protobuf
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
    -DCMAKE_PREFIX_PATH=$ABSEIL_PREFIX \
    -Dprotobuf_JSONCPP_PROVIDER="package" \
    -Dprotobuf_USE_EXTERNAL_GTEST=OFF \
    ..

cmake --build . --verbose
cmake --install .

echo " --------------------------------- Libprotobuf Successfully Installed --------------------------------- "

cd ..

export PROTOC="$LIBPROTO_INSTALL/bin/protoc"
export LD_LIBRARY_PATH="$ABSEIL_PREFIX/lib:$LIBPROTO_INSTALL/lib64:$LD_LIBRARY_PATH"
export LIBRARY_PATH="$LIBPROTO_INSTALL/lib64:$LD_LIBRARY_PATH"
export PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION=cpp
export PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION_VERSION=2

# Apply patch
wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/p/protobuf/set_cpp_to_17_v4.25.3.patch
git apply set_cpp_to_17_v4.25.3.patch

# Build Python package
cd python
python3.12 setup.py install --cpp_implementation

cd $CURRENT_DIR

python3.12 -m pip install pybind11==2.12.0
PYBIND11_PREFIX=$SITE_PACKAGE_PATH/pybind11

export CMAKE_PREFIX_PATH="$ABSEIL_PREFIX;$LIBPROTO_INSTALL;$PYBIND11_PREFIX"
echo "Updated CMAKE_PREFIX_PATH after OpenBLAS: $CMAKE_PREFIX_PATH"
export LD_LIBRARY_PATH="$LIBPROTO_INSTALL/lib64:$ABSEIL_PREFIX/lib:$LD_LIBRARY_PATH"
echo "Updated LD_LIBRARY_PATH : $LD_LIBRARY_PATH"

# Installing Onnx
echo " --------------------------------- Onnx Installing --------------------------------- "

git clone https://github.com/onnx/onnx
cd onnx
git checkout v1.17.0
git submodule update --init --recursive

export ONNX_ML=1
export ONNX_PREFIX=$(pwd)/../onnx-prefix 

AR=$GCC_HOME/bin/ar
LD=$GCC_HOME/bin/ld
NM=$GCC_HOME/bin/nm
OBJCOPY=$GCC_HOME/bin/objcopy
OBJDUMP=$GCC_HOME/bin/objdump
RANLIB=$GCC_HOME/bin/ranlib
STRIP=$GCC_HOME/bin/strip 

export CMAKE_ARGS=""
export CMAKE_ARGS="${CMAKE_ARGS} -DCMAKE_INSTALL_PREFIX=$ONNX_PREFIX"
export CMAKE_ARGS="${CMAKE_ARGS} -DCMAKE_AR=${AR}"
export CMAKE_ARGS="${CMAKE_ARGS} -DCMAKE_LINKER=${LD}"
export CMAKE_ARGS="${CMAKE_ARGS} -DCMAKE_NM=${NM}"
export CMAKE_ARGS="${CMAKE_ARGS} -DCMAKE_OBJCOPY=${OBJCOPY}"
export CMAKE_ARGS="${CMAKE_ARGS} -DCMAKE_OBJDUMP=${OBJDUMP}"
export CMAKE_ARGS="${CMAKE_ARGS} -DCMAKE_RANLIB=${RANLIB}"
export CMAKE_ARGS="${CMAKE_ARGS} -DCMAKE_STRIP=${STRIP}"
export CMAKE_ARGS="${CMAKE_ARGS} -DCMAKE_CXX_STANDARD=17"
export CMAKE_ARGS="${CMAKE_ARGS} -DProtobuf_PROTOC_EXECUTABLE="$PROTOC" -DProtobuf_LIBRARY="$LIBPROTO_INSTALL/lib64/libprotobuf.so""
export CMAKE_ARGS="${CMAKE_ARGS} -DCMAKE_PREFIX_PATH=$CMAKE_PREFIX_PATH"

# Adding this source due to - (Unable to detect linker for compiler `cc -Wl,--version`)
source /opt/rh/gcc-toolset-13/enable
python3.12 -m pip install meson
python3.12 -m pip install parameterized
python3.12 -m pip install pytest nbval pythran mypy-protobuf
python3.12 -m pip install scipy==1.15.2 pandas scikit_learn==1.6.1
sed -i 's/protobuf>=[^ ]*/protobuf==4.25.3/' requirements.txt
python3.12 setup.py install

echo " --------------------------------- Onnx Successfully Installed --------------------------------- "

cd $CURRENT_DIR

#Build bazel from source
echo " --------------------------------- Bazel Installing --------------------------------- "

mkdir bazel
cd bazel
wget https://github.com/bazelbuild/bazel/releases/download/6.5.0/bazel-6.5.0-dist.zip
unzip bazel-6.5.0-dist.zip
env EXTRA_BAZEL_ARGS="--tool_java_runtime_version=local_jdk" bash ./compile.sh
cp output/bazel /usr/local/bin
export PATH=/usr/local/bin:$PATH
bazel --version

echo " --------------------------------- Bazel Successfully Installed --------------------------------- "

cd $CURRENT_DIR

#Build ml_dtypes from source
echo " --------------------------------- ML-Dtypes Installing --------------------------------- "

git clone https://github.com/jax-ml/ml_dtypes.git
cd ml_dtypes
git checkout v0.4.1
git submodule update --init

export CFLAGS="-I${ML_DIR}/include"
export CXXFLAGS="-I${ML_DIR}/include"
python3.12 setup.py bdist_wheel

echo " --------------------------------- ML-Dtypes Successfully Installed --------------------------------- "

cd $CURRENT_DIR

# Installing Grpc from source
echo " --------------------------------- GRPC Installing --------------------------------- "

git clone https://github.com/grpc/grpc.git
cd grpc
git checkout v1.70.0
git submodule update --init --recursive

python3.12 -m pip install pytest hypothesis build six

# Install requirements
python3.12 -m pip install "coverage>=4.0" "cython>=0.29.8,<3.0.0" "wheel>=0.29"

# Install the package
GRPC_PYTHON_BUILD_SYSTEM_OPENSSL=1 python3.12 -m pip install -e .

echo " --------------------------------- GRPC Successfully Installed --------------------------------- "

cd $CURRENT_DIR

# Set CPU optimization flags
export cpu_opt_arch="power9"
export cpu_opt_tune="power10"
export build_type="cpu"
echo "CPU Optimization Settings:"
echo "cpu_opt_arch=${cpu_opt_arch}"
echo "cpu_opt_tune=${cpu_opt_tune}"
echo "build_type=${build_type}"

SHLIB_EXT=".so"
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
echo " --------------------------------- Tensorflow Installing --------------------------------- "

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

echo " --------------------------------- Tensorflow Successfully Installed --------------------------------- "

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

python3.12 -m pip install *.whl

# Clone and install onnxruntime
echo " --------------------------------- Onnxruntime Installing --------------------------------- "

git clone https://github.com/microsoft/onnxruntime
cd onnxruntime
git checkout d1fb58b0f2be7a8541bfa73f8cbb6b9eba05fb6b

# Build the onnxruntime package and create the wheel
sed -i "s/python3/python${PYTHON_VERSION}/g" build.sh

echo "Building onnxruntime..."
./build.sh \
  --cmake_extra_defines "onnxruntime_PREFER_SYSTEM_LIB=ON" \
  --cmake_generator Ninja \
  --build_shared_lib \
  --config Release \
  --update \
  --build \
  --skip_submodule_sync \
  --allow_running_as_root \
  --compile_no_warning_as_error \
  --build_wheel

# Install the built onnxruntime wheel
echo "Installing onnxruntime wheel..."
python3.12 -m pip install build/Linux/Release/dist/*.whl

echo " --------------------------------- Onnxruntime Successfully Installed --------------------------------- "

cd $CURRENT_DIR 

echo " --------------------------------- Tf2Onnx Installing --------------------------------- "

git clone $PACKAGE_URL
cd $PACKAGE_DIR
git checkout $PACKAGE_VERSION 

sed -i "s/protobuf~=[.0-9]\+/protobuf==4.25.3/g" setup.py
sed -i "s/numpy>=1.14.1/numpy==2.0.2/g" setup.py

python3.12 -m pip install setuptools wheel build pytest parameterized timeout-decorator pytest-cov graphviz pytest-runner

if ! python3.12 setup.py install; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

echo " --------------------------------- Tf2Onnx Wheel Build --------------------------------- "

# Build wheel 
python3.12 -m build --wheel --no-isolation --outdir="$CURRENT_DIR"

echo " --------------------------------- Tf2Onnx Wheel Built Success --------------------------------- "

echo " --------------------------------- Running Tests --------------------------------- "

cd tests
if ! pytest -k "not test_cudnn_compatible_gru and not test_custom_rnncell and not test_gru and not test_grublock and not test_lstm and not test_lstmblock and not test_seq2seq and not test_stacked_lstm"; then    
    echo "------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
