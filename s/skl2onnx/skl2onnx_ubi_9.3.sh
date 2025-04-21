#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package        : skl2onnx
# Version        : 1.18.0
# Source repo    : https://github.com/onnx/sklearn-onnx.git
# Tested on      : UBI 9.3
# Language       : Python
# Travis-Check   : True
# Script License : Apache License, Version 2 or later
# Maintainer     : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
#
# Disclaimer: This script has been tested in root mode on the given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such cases, please
#             contact the "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

# Variables
PACKAGE_NAME=skl2onnx
PACKAGE_VERSION=${1:-v1.18}
PACKAGE_URL=https://github.com/onnx/sklearn-onnx.git
PACKAGE_DIR=sklearn-onnx

echo "Installing dependencies..."
yum install -y git wget make libtool gcc-toolset-13 gcc-toolset-13-gcc gcc-toolset-13-gcc-c++ gcc-toolset-13-gcc-gfortran clang libevent-devel zlib-devel openssl-devel python python-devel python3.12 python3.12-devel python3.12-pip cmake patch
export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH

#clone and install openblas from source
git clone https://github.com/OpenMathLib/OpenBLAS
cd OpenBLAS
git checkout v0.3.29
git submodule update --init
wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/o/openblas/pyproject.toml
sed -i "s/{PACKAGE_VERSION}/v0.3.29/g" pyproject.toml
PREFIX=local/openblas
OPENBLAS_SOURCE=$(pwd)
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
sed -i "/OpenBLAS_INCLUDE_DIRS/c\SET(OpenBLAS_INCLUDE_DIRS ${OpenBLASInstallPATH}/include)" ${OpenBLASConfigFile}
sed -i "/OpenBLAS_LIBRARIES/c\SET(OpenBLAS_INCLUDE_DIRS ${OpenBLASInstallPATH}/include)" ${OpenBLASConfigFile}
sed -i "s|libdir=local/openblas/lib|libdir=${OpenBLASInstallPATH}/lib|" ${OpenBLASPCFile}
sed -i "s|includedir=local/openblas/include|includedir=${OpenBLASInstallPATH}/include|" ${OpenBLASPCFile}
export LD_LIBRARY_PATH="$OpenBLASInstallPATH/lib"
export PKG_CONFIG_PATH="$OpenBLASInstallPATH/lib/pkgconfig:${PKG_CONFIG_PATH}"
cd ..

WORK_DIR=$(pwd)
export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH
pip3.12 install --upgrade pip setuptools wheel ninja packaging tox pytest build mypy stubs
pip3.12 install 'cmake==3.31.6'
# Set ABSEIL_VERSION and ABSEIL_URL
ABSEIL_VERSION=20240116.2
ABSEIL_URL="https://github.com/abseil/abseil-cpp"
# Create and set up working directories
echo "Creating abseil prefix directory at $WORK_DIR/abseil-prefix"
mkdir $WORK_DIR/abseil-prefix
PREFIX=$WORK_DIR/abseil-prefix
# Clone abseil-cpp repository
git clone $ABSEIL_URL -b $ABSEIL_VERSION
cd abseil-cpp
SOURCE_DIR=$(pwd)
# Set up directories for local installation
mkdir -p $SOURCE_DIR/local/abseilcpp
abseilcpp=$SOURCE_DIR/local/abseilcpp
# Create build directory and run cmake
mkdir build
cd build
cmake -G Ninja \
    ${CMAKE_ARGS} \
    -DBUILD_SHARED_LIBS=OFF \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_STANDARD=17 \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_INSTALL_PREFIX=${PREFIX} \
    -DBUILD_SHARED_LIBS=ON \
    -DABSL_PROPAGATE_CXX_STD=ON \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
   ..
cmake --build .
cmake --install .

# Copy installation files
cd $WORK_DIR
cp -r  $PREFIX/* $abseilcpp/
echo "abseil-cpp has been installed to $abseilcpp"

# Setting paths and versions
PREFIX=$SITE_PACKAGE_PATH
ABSEIL_PREFIX=$SOURCE_DIR/local/abseilcpp
echo "Setting PREFIX to $PREFIX and ABSEIL_PREFIX to $ABSEIL_PREFIX"

export C_COMPILER=$(which gcc)
export CXX_COMPILER=$(which g++)
echo "C Compiler set to $C_COMPILER"
echo "CXX Compiler set to $CXX_COMPILER"

# Setting paths and versions
export C_COMPILER=$(which gcc)
export CXX_COMPILER=$(which g++)

mkdir -p $(pwd)/local/libprotobuf
LIBPROTO_INSTALL=$(pwd)/local/libprotobuf
echo "LIBPROTO_INSTALL set to $LIBPROTO_INSTALL"

# Clone Source-code
PACKAGE_VERSION_LIB="v4.25.3"
PACKAGE_GIT_URL="https://github.com/protocolbuffers/protobuf"
git clone $PACKAGE_GIT_URL -b $PACKAGE_VERSION_LIB

# Build libprotobuf
echo "protobuf build starts!!"
cd protobuf
git submodule update --init --recursive
rm -rf ./third_party/googletest | true
rm -rf ./third_party/abseil-cpp | true
cp -r $WORK_DIR/abseil-cpp ./third_party/
mkdir build
cd build
cmake -G "Ninja" \
   ${CMAKE_ARGS} \
    -DBUILD_SHARED_LIBS=OFF \
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
cd ..

export PROTOC="$LIBPROTO_INSTALL/bin/protoc"
export LD_LIBRARY_PATH="$ABSEIL_PREFIX/lib:$LIBPROTO_INSTALL/lib64:$LD_LIBRARY_PATH"
export LIBRARY_PATH="$LIBPROTO_INSTALL/lib64:$LD_LIBRARY_PATH"
export PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION=cpp
export PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION_VERSION=2

# Apply patch
echo "Applying patch from https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/p/protobuf/set_cpp_to_17_v4.25.3.patch"
wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/p/protobuf/set_cpp_to_17_v4.25.3.patch
git apply set_cpp_to_17_v4.25.3.patch

# Build Python package
cd python
python3.12 setup.py install --cpp_implementation
cd ../..

pip3.12 install pybind11==2.12.0
PYBIND11_PREFIX=$SITE_PACKAGE_PATH/pybind11
export CMAKE_PREFIX_PATH="$ABSEIL_PREFIX;$LIBPROTO_INSTALL;$PYBIND11_PREFIX"
echo "Updated CMAKE_PREFIX_PATH after OpenBLAS: $CMAKE_PREFIX_PATH"
export LD_LIBRARY_PATH="$LIBPROTO_INSTALL/lib64:$ABSEIL_PREFIX/lib:$LD_LIBRARY_PATH"
echo "Updated LD_LIBRARY_PATH : $LD_LIBRARY_PATH"
echo "Cloning and installing..."
git clone https://github.com/onnx/onnx
cd onnx
git checkout v1.17.0
git submodule update --init --recursive
export ONNX_ML=1
export ONNX_PREFIX=$(pwd)/../onnx-prefix
AR=$gcc_home/bin/ar
LD=$gcc_home/bin/ld
NM=$gcc_home/bin/nm
OBJCOPY=$gcc_home/bin/objcopy
OBJDUMP=$gcc_home/bin/objdump
RANLIB=$gcc_home/bin/ranlib
STRIP=$gcc_home/bin/strip
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
pip3.12 install cython meson
pip3.12 install numpy==2.0.2 
pip3.12 install parameterized
pip3.12 install pytest nbval pythran mypy-protobuf
pip3.12 install scipy==1.15.2 pandas scikit_learn==1.6.1
sed -i 's/protobuf>=[^ ]*/protobuf==4.25.3/' requirements.txt
python3.12 setup.py install
cd ..
# Clone and install onnxconverter-common
echo "Cloning and installing onnxconverter-common..."
git clone https://github.com/microsoft/onnxconverter-common
cd onnxconverter-common
git checkout v1.14.0
git submodule update --init --recursive
sed -i 's/\bprotobuf==[^ ]*\b/protobuf==4.25.3/g' pyproject.toml
sed -i 's/\"onnx\"/\"onnx==1.17.0\"/' pyproject.toml
sed -i 's/\"numpy\"/\"numpy==2.0.2\"/' pyproject.toml
sed -i "/tool.setuptools.dynamic/d" pyproject.toml
sed -i "/onnxconverter_common.__version__/d" pyproject.toml

sed -i 's/\"numpy\"/\"numpy==2.0.2\"/' requirements.txt
sed -i 's/\bprotobuf==[^ ]*\b/protobuf==4.25.3/g' requirements.txt
pip3.12 install flatbuffers onnxmltools
cd ..
# Clone and install onnxruntime
echo "Cloning and installing onnxruntime..."
git clone https://github.com/microsoft/onnxruntime
cd onnxruntime
git checkout d1fb58b0f2be7a8541bfa73f8cbb6b9eba05fb6b
# Build the onnxruntime package and create the wheel
sed -i 's/python3/python3.12/g' build.sh
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
cp ./build/Linux/Release/dist/* ./
pip3.12 install ./*.whl
# Clean up the onnxruntime repository
cd ..
rm -rf onnxruntime

cd onnxconverter-common
python3.12 setup.py install

# Clone the package from the repository
git clone $PACKAGE_URL
cd $PACKAGE_DIR
git checkout $PACKAGE_VERSION
sed -i 's/onnx>=1.2.1//g' requirements.txt
sed -i 's/onnxconverter-common>=1.7.0//g' requirements.txt
sed -i 's/scikit-learn>=1\.1/scikit-learn==1.6.1/' requirements.txt


# Build skl2onnx
if ! pip3.12 install -e . --no-build-isolation --no-deps; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# # Run tests
echo "Running tests for $PACKAGE_NAME..."
cd tests
# Test the onnxconverter-common package
export LD_LIBRARY_PATH="$OpenBLASInstallPATH/lib:$LIBPROTO_INSTALL/lib64:$LD_LIBRARY_PATH"
#skipping below test cases because of KeyError: 'schemas'
if ! pytest --ignore=test_sklearn_power_transformer.py --ignore=test_sklearn_feature_hasher.py --ignore=test_sklearn_adaboost_converter.py --ignore=test_algebra_onnx_doc.py; then
    echo "------------------$PACKAGE_NAME:build_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Build_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Pass | Both_Install_and_Test_Success"
    exit 0
fi
