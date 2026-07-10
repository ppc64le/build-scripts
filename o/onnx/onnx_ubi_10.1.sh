#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : onnx
# Version       : v1.21.0
# Source repo   : https://github.com/onnx/onnx
# Tested on     : UBI 10.1
# Language      : Python
# Travis-Check  : True
# Script License: Apache License 2.0
# Maintainer    : Sakshi Jain <sakshi.jain16@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -ex

PACKAGE_NAME=onnx
PACKAGE_VERSION=${1:-v1.21.0}
PACKAGE_URL=https://github.com/onnx/onnx
CURRENT_DIR=$(pwd)
PACKAGE_DIR=onnx

yum install -y git make cmake clang gcc-toolset-15-gcc gcc-toolset-15-gcc-c++ gcc-toolset-15-gcc-gfortran gcc-toolset-15-binutils python3.12 python3.12-devel python3.12-pip --exclude gstreamer1 --skip-broken

CURRENT_DIR=$(pwd)

# Use clang as the default compiler (overridden for OpenBLAS below)
export CC=/usr/bin/clang
export CXX=/usr/bin/clang++

INSTALL_ROOT="${CURRENT_DIR}/install-deps"
mkdir -p $INSTALL_ROOT

for package in openblas onnx ; do
    mkdir -p ${INSTALL_ROOT}/${package}
    export "${package^^}_PREFIX=${INSTALL_ROOT}/${package}"
    echo "Exported ${package^^}_PREFIX=${INSTALL_ROOT}/${package}"
done

echo " --------------------------------- Openblas Installing --------------------------------- "

git clone -b v0.3.33 https://github.com/xianyi/OpenBLAS
cd OpenBLAS
git submodule update --init
python3.12 -m pip install setuptools==82.0.1
LDFLAGS=$(echo "${LDFLAGS}" | sed "s/-Wl,--gc-sections//g")

# OpenBLAS on ppc64le requires GCC — clang cannot link dynamic_power.o
# (unresolvable R_PPC64_ADDR64 against __parse_hwcap_and_convert_at_platform).
# Use gcc-toolset-15 which fully supports POWER9.
GCC15_BIN=/opt/rh/gcc-toolset-15/root/usr/bin
export OPENBLAS_CC="${GCC15_BIN}/gcc"
export OPENBLAS_FC="${GCC15_BIN}/gfortran"

# See this workaround
# ( https://github.com/xianyi/OpenBLAS/issues/818#issuecomment-207365134 ).
export CF="${CFLAGS} -Wno-unused-parameter"
unset CFLAGS
export USE_OPENMP=1
#TODO: Pass path
build_opts+=(USE_OPENMP=${USE_OPENMP})
if [ ! -z "$FFLAGS" ]; then
    # Don't use GNU OpenMP, which is not fork-safe
    export FFLAGS="${FFLAGS/-fopenmp/ }"
    export FFLAGS="${FFLAGS} -frecursive"
    export LAPACK_FFLAGS="${FFLAGS}"
fi
build_opts+=(BINARY="64")
build_opts+=(DYNAMIC_ARCH=1)
# Set target platform-/CPU-specific options
build_opts+=(TARGET="POWER9")
# Placeholder for future builds that may include ILP64 variants.
build_opts+=(INTERFACE64=0)
build_opts+=(SYMBOLSUFFIX="")
# Build LAPACK.
build_opts+=(NO_LAPACK=0)
# Enable threading. This can be controlled to a certain number by
# setting OPENBLAS_NUM_THREADS before loading the library.
build_opts+=(USE_THREAD=1)
build_opts+=(NUM_THREADS=8)
# Disable CPU/memory affinity handling to avoid problems with NumPy and R
build_opts+=(NO_AFFINITY=1)
#Build:-
make -j8 ${build_opts[@]} \
     CC="${OPENBLAS_CC}" FC="${OPENBLAS_FC}" \
     CFLAGS="${CF}" FFLAGS="${FFLAGS}"

CFLAGS="${CF}" FFLAGS="${FFLAGS}" \
    make install PREFIX="${OPENBLAS_PREFIX}" ${build_opts[@]} \
    CC="${OPENBLAS_CC}" FC="${OPENBLAS_FC}"

echo " --------------------------------- OpenBLAS Successfully Installed --------------------------------- "

cd $CURRENT_DIR

echo " --------------------------------- Numpy Installing --------------------------------- "

# Clone numpy repository
git clone -b v2.2.6 https://github.com/numpy/numpy
cd numpy
git submodule update --init

# Use clang as the compiler (consistent with the rest of the build)
export CC=/usr/bin/clang
export CXX=/usr/bin/clang++
export AR=/usr/bin/ar
export LD=/usr/bin/ld
export NM=/usr/bin/nm
export OBJCOPY=/usr/bin/objcopy
export OBJDUMP=/usr/bin/objdump
export RANLIB=/usr/bin/ranlib
export STRIP=/usr/bin/strip

# Set OpenBLAS paths for numpy
export PKG_CONFIG_PATH="${OPENBLAS_PREFIX}/lib/pkgconfig:${PKG_CONFIG_PATH}"
export LD_LIBRARY_PATH="${OPENBLAS_PREFIX}/lib:${LD_LIBRARY_PATH}"

# Install numpy build dependencies
python3.12 -m pip install build==1.5.0 meson==1.11.1 meson-python==0.19.0

# Build numpy wheel
python3.12 -m build --wheel

# Install the built numpy wheel
python3.12 -m pip install dist/numpy-2.2.6-cp312-cp312-linux_ppc64le.whl

# Verify numpy installation (change directory to avoid importing from source)
cd $CURRENT_DIR
python3.12 -c "import numpy; print(f'NumPy version: {numpy.__version__}')"

echo " --------------------------------- Numpy Successfully Installed --------------------------------- "


echo " --------------------------------- Libprotobuf Installing --------------------------------- "

# Export library paths for consistent compiler usage across the build
python3.12 -m pip install --upgrade pip==26.1.2 setuptools==82.0.1 wheel==0.47.0 ninja==1.13.0 packaging==26.2 tox==4.55.1 pytest==9.0.3 build==1.5.0 mypy==2.1.0 stubs==1.0.0

export C_COMPILER=$(which clang) CXX_COMPILER=$(which clang++)
echo "C Compiler set to $C_COMPILER"
echo "CXX Compiler set to $CXX_COMPILER"

mkdir -p $(pwd)/local/libprotobuf
LIBPROTO_INSTALL=$(pwd)/local/libprotobuf
echo "LIBPROTO_INSTALL set to $LIBPROTO_INSTALL"

# Clone Source-code

PACKAGE_VERSION_LIB="v6.31.1"
PACKAGE_GIT_URL="https://github.com/protocolbuffers/protobuf"
git clone $PACKAGE_GIT_URL -b $PACKAGE_VERSION_LIB

# Build libprotobuf
echo "protobuf build starts!!"
cd protobuf
git submodule update --init --recursive
rm -rf ./third_party/googletest | true

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
    -Dprotobuf_BUILD_LIBUPB=ON \
    -Dprotobuf_BUILD_SHARED_LIBS=ON \
    -Dprotobuf_ABSL_PROVIDER="module" \
    -Dprotobuf_JSONCPP_PROVIDER="package" \
    -Dprotobuf_USE_EXTERNAL_GTEST=OFF \
    ..

cmake --build . --verbose
cmake --install .

echo " --------------------------------- Libprotobuf Successfully Installed --------------------------------- "

cd $CURRENT_DIR

echo " --------------------------------- Protobuf Installing --------------------------------- "

export PROTOC="$LIBPROTO_INSTALL/bin/protoc"
export LD_LIBRARY_PATH="$LIBPROTO_INSTALL/lib64:$LD_LIBRARY_PATH"
export LIBRARY_PATH="$LIBPROTO_INSTALL/lib64:$LD_LIBRARY_PATH"
export PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION=cpp
export PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION_VERSION=2

python3.12 -m pip install protobuf==6.31.1

python3.12 -m pip install pybind11==3.0.4
PYBIND11_PREFIX=${VIRTUAL_ENV}/lib/python3.12/site-packages/pybind11

export CMAKE_PREFIX_PATH="$LIBPROTO_INSTALL;$PYBIND11_PREFIX"
echo "Updated CMAKE_PREFIX_PATH after OpenBLAS: $CMAKE_PREFIX_PATH"
export LD_LIBRARY_PATH="$LIBPROTO_INSTALL/lib64:$LD_LIBRARY_PATH"
echo "Updated LD_LIBRARY_PATH : $LD_LIBRARY_PATH"
export LD_LIBRARY_PATH="$(pwd)/../build:$LD_LIBRARY_PATH"

echo " --------------------------------- Protobuf Successfully Installed --------------------------------- "

cd $CURRENT_DIR

#Build ml_dtypes from source
echo " --------------------------------- ML-Dtypes Installing --------------------------------- "

git clone https://github.com/jax-ml/ml_dtypes.git
cd ml_dtypes
git checkout v0.5.1
git submodule update --init

python3.12 setup.py bdist_wheel
cp dist/ml_dtypes-0.5.1-cp312-cp312-linux_ppc64le.whl ../wheels

echo " --------------------------------- ML-Dtypes Successfully Installed --------------------------------- "


cd $CURRENT_DIR

echo " --------------------------------- Onnx Installing --------------------------------- "

git clone https://github.com/onnx/onnx
cd onnx
git checkout v1.21.0
git submodule update --init --recursive

#Apply patch
wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/o/onnx/onnx_1.21.0_fix.patch
git apply onnx_1.21.0_fix.patch

export ONNX_ML=1

AR=/usr/bin/ar
LD=/usr/bin/ld
NM=/usr/bin/nm
OBJCOPY=/usr/bin/objcopy
OBJDUMP=/usr/bin/objdump
RANLIB=/usr/bin/ranlib
STRIP=/usr/bin/strip

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
export CMAKE_ARGS="${CMAKE_ARGS} -DProtobuf_PROTOC_EXECUTABLE=$PROTOC -DProtobuf_LIBRARY=$LIBPROTO_INSTALL/lib64/libprotobuf.so"
export CMAKE_PREFIX_PATH="$LIBPROTO_INSTALL;$LIBPROTO_INSTALL/lib64/cmake/absl;$CMAKE_PREFIX_PATH"
export CMAKE_ARGS="${CMAKE_ARGS} -DCMAKE_PREFIX_PATH=$CMAKE_PREFIX_PATH"
export CMAKE_ARGS="${CMAKE_ARGS} -Dabsl_DIR=$LIBPROTO_INSTALL/lib64/cmake/absl"
export CMAKE_ARGS="${CMAKE_ARGS} -DProtobuf_DIR=$LIBPROTO_INSTALL/lib64/cmake/protobuf"

python3.12 -m pip install meson==1.11.1
python3.12 -m pip install parameterized==0.9.0
python3.12 -m pip install pytest==9.0.3 nbval==0.11.0 pythran==0.18.1 mypy-protobuf==5.1.0
python3.12 -m pip install pandas==3.0.3
python3.12 -m pip install setuptools==82.0.1

sed -i 's/protobuf>=[^ ]*/protobuf==6.31.1/' requirements.txt

# Install ONNX with CMake to generate config files for ONNXRuntime
mkdir -p build_onnx
cd build_onnx
cmake -G Ninja \
    -DCMAKE_INSTALL_PREFIX=$ONNX_PREFIX \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_C_COMPILER=/usr/bin/clang \
    -DCMAKE_CXX_COMPILER=/usr/bin/clang++ \
    -DONNX_ML=1 \
    -DONNX_USE_PROTOBUF_SHARED_LIBS=OFF \
    -DProtobuf_PROTOC_EXECUTABLE=$PROTOC \
    -DProtobuf_LIBRARY=$LIBPROTO_INSTALL/lib64/libprotobuf.so \
    -DProtobuf_INCLUDE_DIR=$LIBPROTO_INSTALL/include \
    -Dabsl_DIR=$LIBPROTO_INSTALL/lib64/cmake/absl \
    -DProtobuf_DIR=$LIBPROTO_INSTALL/lib64/cmake/protobuf \
    -DCMAKE_PREFIX_PATH="$LIBPROTO_INSTALL/lib64/cmake/absl;$LIBPROTO_INSTALL" \
    ..
cmake --build . --parallel $(nproc)
cmake --install .

# Build the package
cd ..
python3.12 setup.py bdist_wheel

#Install package
if ! (python3.12 -m pip install dist/onnx-*.whl) ; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

echo "-------------------------------Onnx installation successful-------------------------------------"
 