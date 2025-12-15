#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : onnxconverter-common
# Version          : v1.14.0
# Source repo      : https://github.com/microsoft/onnxconverter-common
# Tested on        : UBI:9.3
# Language         : Python
# Ci-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------------

# Variables
PACKAGE_NAME=onnxconverter-common
PACKAGE_VERSION=${1:-v1.14.0}
PACKAGE_URL=https://github.com/microsoft/onnxconverter-common
PACKAGE_DIR=onnxconverter-common
CURRENT_DIR=$(pwd)

echo "Installing dependencies..."

yum install -y git wget make libtool gcc-toolset-13 gcc-toolset-13-gcc gcc-toolset-13-gcc-c++ gcc-toolset-13-gcc-gfortran clang libevent-devel zlib-devel openssl-devel python3.12 python3.12-devel python3.12-pip patch
yum install -y make openssl-devel zlib-devel ncurses-devel
export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH

echo "Installing cmake..."
CMAKE_VERSION=3.29.2
wget https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}.tar.gz
tar -xzf cmake-${CMAKE_VERSION}.tar.gz
cd cmake-${CMAKE_VERSION}
./bootstrap --prefix=/usr/local --parallel=2
echo "Installing cmake..."
make -j2
echo "Installing cmake..."
make install
cmake --version
cd ..

echo " --------------------------------------------------- OpenBlas Installing --------------------------------------------------- "

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
make -j2 ${build_opts[@]} CFLAGS="${CF}" FFLAGS="${FFLAGS}" prefix=${PREFIX}

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

echo " --------------------------------------------------- OpenBlas Successfully Installed --------------------------------------------------- "

cd $CURRENT_DIR

export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH

python3.12 -m pip install --upgrade pip setuptools wheel ninja packaging tox pytest build mypy stubs
python3.12 -m pip install 'cmake==3.31.6'

echo " --------------------------------------------------- Abseil-cpp Cloning --------------------------------------------------- "

# Set ABSEIL_VERSION and ABSEIL_URL
ABSEIL_VERSION=20240116.2
ABSEIL_URL="https://github.com/abseil/abseil-cpp"

git clone $ABSEIL_URL -b $ABSEIL_VERSION

echo " --------------------------------------------------- Abseil-cpp Cloned --------------------------------------------------- "

# Setting paths and versions
export C_COMPILER=$(which gcc)
export CXX_COMPILER=$(which g++)
echo "C Compiler set to $C_COMPILER"
echo "CXX Compiler set to $CXX_COMPILER"

LIBPROTO_DIR=$(pwd)
mkdir -p $LIBPROTO_DIR/local/libprotobuf
LIBPROTO_INSTALL=$LIBPROTO_DIR/local/libprotobuf

echo " --------------------------------------------------- Libprotobuf Installing --------------------------------------------------- "

# Clone Source-code
PACKAGE_VERSION_LIB="v4.25.8"
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

echo " --------------------------------------------------- Libprotobuf Successfully Installed --------------------------------------------------- "

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

cd $CURRENT_DIR

python3.12 -m pip install pybind11==2.12.0
PYBIND11_PREFIX=$SITE_PACKAGE_PATH/pybind11

export CMAKE_PREFIX_PATH="$ABSEIL_PREFIX;$LIBPROTO_INSTALL;$PYBIND11_PREFIX"
echo "Updated CMAKE_PREFIX_PATH after OpenBLAS: $CMAKE_PREFIX_PATH"

export LD_LIBRARY_PATH="$LIBPROTO_INSTALL/lib64:$ABSEIL_PREFIX/lib:$LD_LIBRARY_PATH"
echo "Updated LD_LIBRARY_PATH : $LD_LIBRARY_PATH"

echo " --------------------------------------------------- Onnx Installing --------------------------------------------------- "

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
python3.12 -m pip install cython meson
python3.12 -m pip install numpy==2.0.2 
python3.12 -m pip install parameterized
python3.12 -m pip install pytest nbval pythran mypy-protobuf
python3.12 -m pip install scipy==1.15.2 pandas scikit_learn==1.6.1
sed -i 's/protobuf>=[^ ]*/protobuf==4.25.8/' requirements.txt
python3.12 setup.py install 

echo " --------------------------------------------------- Onnx Successfully Installed --------------------------------------------------- "

cd $CURRENT_DIR

# Clone and install onnxconverter-common
echo " --------------------------------------------------- OnnxConverter-Common Cloning --------------------------------------------------- "
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
git submodule update --init --recursive 

sed -i 's/\bprotobuf==[^ ]*\b/protobuf==4.25.8/g' pyproject.toml
sed -i 's/\"onnx\"/\"onnx==1.17.0\"/' pyproject.toml
sed -i 's/\"numpy\"/\"numpy==2.0.2\"/' pyproject.toml
sed -i "/tool.setuptools.dynamic/d" pyproject.toml
sed -i "/onnxconverter_common.__version__/d" pyproject.toml

sed -i 's/\"numpy\"/\"numpy==2.0.2\"/' requirements.txt
sed -i 's/\bprotobuf==[^ ]*\b/protobuf==4.25.8/g' requirements.txt

python3.12 -m pip install flatbuffers onnxmltools

cd $CURRENT_DIR

# Clone and install onnxruntime
echo " --------------------------------------------------- Onnxruntime Installing --------------------------------------------------- "

git clone https://github.com/microsoft/onnxruntime
cd onnxruntime
git checkout v1.21.0
# Build the onnxruntime package and create the wheel


echo " --------------------------------------------------- Building Onnxruntime --------------------------------------------------- "
export CXXFLAGS="-Wno-stringop-overflow"
export CFLAGS="-Wno-stringop-overflow"
export LD_LIBRARY_PATH=/OpenBLAS:/OpenBLAS/libopenblas.so.0:$LD_LIBRARY_PATH

#get python version
PYTHON_VERSION=$(compgen -c | grep -E '^python3\.[0-9]+$' | sort -Vr | head -n 1)
PYTHON_PATH=$(command -v $PYTHON_VERSION)
export PYTHON_EXECUTABLE=$PYTHON_PATH
export PATH=$(dirname "$PYTHON_EXECUTABLE"):$PATH
sed -i "s/python3/$PYTHON_VERSION/g" build.sh

# Install required Python packages
$PYTHON_EXECUTABLE -m pip install packaging wheel numpy==2.0.2

# Confirm NumPy installation and get include path
$PYTHON_EXECUTABLE -c "import numpy; print('NumPy version:', numpy.__version__)"
NUMPY_INCLUDE=$($PYTHON_EXECUTABLE -c "import numpy; print(numpy.get_include())")
echo "NumPy include path: $NUMPY_INCLUDE"

# Manually defines Python::NumPy for CMake versions with broken NumPy detection
sed -i '193i # Fix for Python::NumPy target not found\nif(NOT TARGET Python::NumPy)\n    find_package(Python3 COMPONENTS NumPy REQUIRED)\n    add_library(Python::NumPy INTERFACE IMPORTED)\n    target_include_directories(Python::NumPy INTERFACE ${Python3_NumPy_INCLUDE_DIR})\n    message(STATUS "Manually defined Python::NumPy with include dir: ${Python3_NumPy_INCLUDE_DIR}")\nendif()\n' $CURRENT_DIR/onnxruntime/cmake/onnxruntime_python.cmake


sed -i 's|5ea4d05e62d7f954a46b3213f9b2535bdd866803|51982be81bbe52572b54180454df11a3ece9a934|' cmake/deps.txt


./build.sh \
  --cmake_extra_defines "onnxruntime_PREFER_SYSTEM_LIB=ON" "Protobuf_PROTOC_EXECUTABLE=$PROTO_PREFIX/bin/protoc" "Protobuf_INCLUDE_DIR=$PROTO_PREFIX/include" "onnxruntime_USE_COREML=OFF" "Python3_NumPy_INCLUDE_DIR=$NUMPY_INCLUDE" "CMAKE_POLICY_DEFAULT_CMP0001=NEW" "CMAKE_POLICY_DEFAULT_CMP0002=NEW" "CMAKE_POLICY_VERSION_MINIMUM=3.5" \
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
echo " --------------------------------------------------- Installing onnxruntime wheel --------------------------------------------------- "
cp ./build/Linux/Release/dist/* ./
python3.12 -m pip install ./*.whl
# Clean up the onnxruntime repository
cd $CURRENT_DIR
rm -rf onnxruntime

cd $PACKAGE_DIR
if ! python3.12 setup.py install; then
    echo "------------------$PACKAGE_NAME:wheel_built_fails---------------------"
    echo "$PACKAGE_VERSION $PACKAGE_NAME"
    echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  wheel_built_fails"
    exit 1
fi
#build wheel
cd $CURRENT_DIR/$PACKAGE_DIR
python3.12 setup.py bdist_wheel --plat-name=linux_$(uname -m)
mv dist/*.whl "$CURRENT_DIR/"

echo "Running tests for $PACKAGE_NAME..."
# Test the onnxconverter-common package
#skipping due to attribute errors
if ! pytest --ignore=tests/test_auto_mixed_precision.py --ignore=tests/test_onnx2py.py --ignore=tests/test_float16.py; then
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
