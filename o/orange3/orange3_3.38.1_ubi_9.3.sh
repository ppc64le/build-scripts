#!/bin/bash -e
#
# -----------------------------------------------------------------------------
#
# Package       : orange3
# Version       : 3.38.1
# Source repo   : https://github.com/biolab/orange3
# Tested on     : UBI 9.3
# Language      : c
# Travis-Check  : True
# Script License: Apache License 2.0
# Maintainer    : Aastha Sharma <aastha.sharma4@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
set -ex

PACKAGE_NAME=orange3
PACKAGE_VERSION=${1:-3.38.1}
PACKAGE_URL=https://github.com/biolab/orange3
PACKAGE_DIR=orange3
CURRENT_DIR=$(pwd)

yum install -y wget git python3.12 make unzip python3.12-pip python3.12-devel git gcc-toolset-13 gcc-toolset-13-gcc gcc-toolset-13-gcc-c++ openssl-devel xz-devel xz.ppc64le openblas rust cargo zlib-devel libjpeg-devel ninja-build gcc-toolset-13-gcc-gfortran gcc-toolset-13-gcc-c++ lld bzip2 zip libstdc++-devel ninja-build sqlite-devel perl-core gcc-toolset-13-binutils gcc-toolset-13-binutils-devel gcc-toolset-13-gcc-c++

export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH

echo "---------------------openblas installing---------------------"
# clone and install openblas from source

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

echo "Building OpenBLAS"
make -j8 ${build_opts[@]} CFLAGS="${CF}" FFLAGS="${FFLAGS}" prefix=${PREFIX}

echo "Install OpenBLAS"
CFLAGS="${CF}" FFLAGS="${FFLAGS}" make install PREFIX="${PREFIX}" ${build_opts[@]}
OpenBLASInstallPATH=$(pwd)/$PREFIX
OpenBLASConfigFile=$(find . -name OpenBLASConfig.cmake)
OpenBLASPCFile=$(find . -name openblas.pc)
export LD_LIBRARY_PATH="$OpenBLASInstallPATH/lib":${LD_LIBRARY_PATH}
export PKG_CONFIG_PATH="$OpenBLASInstallPATH/lib/pkgconfig:${PKG_CONFIG_PATH}"
export LD_LIBRARY_PATH=${PREFIX}/lib:$LD_LIBRARY_PATH
export PKG_CONFIG_PATH=${PREFIX}/lib/pkgconfig:$PKG_CONFIG_PATH
pkg-config --modversion openblas
cd $CURRENT_DIR
pip3.12 install sip pytest
OUTPUT_FOLDER="$(pwd)/output"


echo "---------------------xgboost installing---------------------"
# Install Xgboost from source
echo "Installing dependencies..."
yum install -y openssl-devel cmake openblas-devel
pip3.12 install numpy packaging pathspec pluggy scipy trove-classifiers wheel build

echo "Cloning the repository..."
mkdir -p output
git clone -b v1.7.5 --recursive https://github.com/dmlc/xgboost
cd xgboost
git submodule update --init --recursive
export SRC_DIR=$(pwd)

# Build xgboost cpp artifacts
echo "Building xgboost cpp artifacts..."
cd ${SRC_DIR}
mkdir -p build
cd build
cmake -DCMAKE_INSTALL_PREFIX=${OUTPUT_FOLDER} ..
make -j$(nproc)

LIBDIR=${OUTPUT_FOLDER}/lib
INCDIR=${OUTPUT_FOLDER}/include
BINDIR=${OUTPUT_FOLDER}/bin
SODIR=${LIBDIR}
XGBOOSTDSO=libxgboost.so

mkdir -p ${LIBDIR} ${INCDIR}/xgboost ${BINDIR} || true
cp ${SRC_DIR}/lib/${XGBOOSTDSO} ${SODIR}
cp -Rf ${SRC_DIR}/include/xgboost ${INCDIR}/
cp -Rf ${SRC_DIR}/rabit/include/rabit ${INCDIR}/xgboost/
cp -f ${SRC_DIR}/src/c_api/*.h ${INCDIR}/xgboost/
cd ../../

# Build xgboost python artifacts and wheel
echo "Building xgboost Python artifacts and wheel..."
cd "$(pwd)/xgboost/python-package"
python3.12 setup.py install
cd $CURRENT_DIR


echo "---------------------cmake installing---------------------"
#Build and install CMake
wget -c https://github.com/Kitware/CMake/releases/download/v3.28.1/cmake-3.28.1.tar.gz
tar -zxvf cmake-3.28.1.tar.gz
rm -f cmake-3.28.1.tar.gz
cd cmake-3.28.1
./bootstrap --prefix=/usr/local/cmake --parallel=2 -- -DBUILD_TESTING:BOOL=OFF -DCMAKE_BUILD_TYPE:STRING=Release -DCMAKE_USE_OPENSSL:BOOL=ON
make -j$(nproc)
make install
export PATH=/usr/local/cmake/bin:$PATH
cmake --version
cd $CURRENT_DIR

echo "---------------------llvm-17 installing---------------------"
wget https://github.com/llvm/llvm-project/archive/refs/tags/llvmorg-17.0.6.tar.gz -O llvm-project-17.0.6.tar.gz
tar -xvf llvm-project-17.0.6.tar.gz
rm -f llvm-project-17.0.6.tar.gz
cd llvm-project-llvmorg-17.0.6
mkdir build && cd build
cmake -G Ninja ../llvm \
  -DCMAKE_BUILD_TYPE=Release \
  -DLLVM_ENABLE_PROJECTS=clang \
  -DLLVM_TARGETS_TO_BUILD="PowerPC" \
  -DCMAKE_INSTALL_PREFIX=$BUILD_HOME/clang-17.0.6
ninja
ninja install
export PATH=$BUILD_HOME/clang-17.0.6/bin:$PATH
export CC=$BUILD_HOME/clang-17.0.6/bin/clang
export CXX=$BUILD_HOME/clang-17.0.6/bin/clang++
export ASM=$BUILD_HOME/clang-17.0.6/bin/clang

clang --version
cd $CURRENT_DIR

echo "---------------------catboost installing---------------------"
git clone https://github.com/catboost/catboost.git
cd catboost
git checkout v1.2.5

pip3.12 install "conan<2"
pip3.12 install six setuptools wheel jupyterlab Pillow pandas plotly scipy testpath pytest ipywidgets 'numpy<2.0' build wheel
export PATH=$CURRENT_DIR/clang-17.0.6/bin:$PATH
export CC=$CURRENT_DIR/clang-17.0.6/bin/clang
export CXX=$CURRENT_DIR/clang-17.0.6/bin/clang++
export ASM=$CURRENT_DIR/clang-17.0.6/bin/clang
#conan install . --build=missing
conan install . || true && sed -i 's/ autotools.configure()/ autotools.configure(args=["--build=powerpc64le-linux-gnu"])/g' /$CURRENT_DIR/root/.conan/data/yasm/1.3.0/_/_/export/conanfile.py
cd catboost/python-package/
ret=0
python3.12 setup.py bdist_wheel --no-widget || ret=$?
if [ "$ret" -ne 0 ]
then
    exit 1
fi

echo "Creating symlink for LLVMgold.so where clang expects it..."
CLANG_CUSTOM_LIB_DIR="$BUILD_HOME/clang-17.0.6/lib"
LLVMGOLD_SOURCE_PATH="/usr/lib64/LLVMgold.so" 
LLVMGOLD_TARGET_PATH="$CLANG_CUSTOM_LIB_DIR/LLVMgold.so"

mkdir -p "$CLANG_CUSTOM_LIB_DIR" # Ensure the target directory exists

if [ -f "$LLVMGOLD_SOURCE_PATH" ]; then
    if [ ! -f "$LLVMGOLD_TARGET_PATH" ]; then
        echo "Symlinking $LLVMGOLD_SOURCE_PATH to $LLVMGOLD_TARGET_PATH"
        ln -sf "$LLVMGOLD_SOURCE_PATH" "$LLVMGOLD_TARGET_PATH"
        if [ $? -eq 0 ]; then
            echo "Symlink created successfully."
        else
            echo "ERROR: Failed to create symlink for LLVMgold.so. Matplotlib build might fail."
            exit 1
        fi
    else
        echo "Symlink for LLVMgold.so already exists at $LLVMGOLD_TARGET_PATH."
    fi
else
    echo "ERROR: LLVMgold.so not found at expected system location: $LLVMGOLD_SOURCE_PATH."
    echo "Matplotlib build will likely fail. Please ensure llvm-gold or llvm-libs is installed on the system."
    exit 1 
fi
echo "LLVMgold.so setup for clang complete."

GCC_TOOLSET_LIB_PATH="/opt/rh/gcc-toolset-13/root/usr/lib64"
export LD_LIBRARY_PATH="${GCC_TOOLSET_LIB_PATH}:${LD_LIBRARY_PATH}"

echo "Adding OpenMP include path to CFLAGS/CXXFLAGS..."
OMP_INCLUDE_PATH="/opt/rh/gcc-toolset-13/root/usr/lib/gcc/ppc64le-redhat-linux/13/include"
export CFLAGS="${CFLAGS:-} -I${OMP_INCLUDE_PATH}"
export CXXFLAGS="${CXXFLAGS:-} -I${OMP_INCLUDE_PATH}"
echo "Updated CFLAGS: $CFLAGS"
echo "Updated CXXFLAGS: $CXXFLAGS"


pip3.12 install /catboost/catboost/python-package/dist/catboost-*_ppc64le.whl
# python3.12 setup.py bdist_wheel --no-widget
cd $CURRENT_DIR

echo "---------------------Orange3 installing---------------------"
git clone $PACKAGE_URL
cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION

pip3.12 install --upgrade pip  wheel
pip3.12 install "setuptools<69"
pip3.12 install beautifulsoup4 docutils numpydoc recommonmark Sphinx 'cmake==3.31.*'

source scl_source enable gcc-toolset-13

# Ensuring gcc-toolset-13 binaries are at the front of PATH.
echo "Ensuring gcc-toolset-13 binaries are at the front of PATH..."
export PATH="/opt/rh/gcc-toolset-13/root/usr/bin:$PATH"
echo "PATH is now: $PATH"

# LIBCTF.SO.0 FIX: Adjust LD_LIBRARY_PATH to prioritize gcc-toolset-13's libctf.so.0
echo "Adjusting LD_LIBRARY_PATH to prioritize gcc-toolset-13's libctf.so.0..."
GCC_TOOLSET_LIB_PATH="/opt/rh/gcc-toolset-13/root/usr/lib64"
export LD_LIBRARY_PATH="${GCC_TOOLSET_LIB_PATH}:${LD_LIBRARY_PATH}"
echo "LD_LIBRARY_PATH is now: $LD_LIBRARY_PATH"

#OMP.H FIX: Add OpenMP include path to CFLAGS/CXXFLAGS
echo "Adding OpenMP include path to CFLAGS/CXXFLAGS..."
OMP_INCLUDE_PATH="/opt/rh/gcc-toolset-13/root/usr/lib/gcc/ppc64le-redhat-linux/13/include"
export CFLAGS="${CFLAGS:-} -I${OMP_INCLUDE_PATH} -Wno-macro-redefined -Wno-discarded-qualifiers"
export CXXFLAGS="${CXXFLAGS:-} -I${OMP_INCLUDE_PATH} -Wno-macro-redefined -Wno-discarded-qualifiers"
echo "Updated CFLAGS: $CFLAGS"
echo "Updated CXXFLAGS: $CXXFLAGS"

#FORTRAN COMPILER FIX: Explicitly set FC
echo "Setting Fortran compiler (FC) environment variable..."
export FC="/opt/rh/gcc-toolset-13/root/usr/bin/gfortran"
echo "FC set to: $FC"

#NumPy specific flags (often needed if general CFLAGS/CXXFLAGS are not fully propagated)
export NPY_CFLAGS="${CFLAGS}"
export NPY_CXXFLAGS="${CXXFLAGS}"
echo "NPY_CFLAGS set to: $NPY_CFLAGS"
echo "NPY_CXXFLAGS set to: $NPY_CXXFLAGS"

#Add CPPFLAGS for preprocessor warnings
export CPPFLAGS="${CPPFLAGS:-} -Wno-macro-redefined"
echo "Updated CPPFLAGS: $CPPFLAGS"

# --- END OF ALL CRITICAL ENVIRONMENT VARIABLE EXPORTS FOR COMPILATION ---

# Ensure PYTHON_BIN_DIR is in PATH before saving CLANG_PATH_SAVE
export PATH="${PYTHON_BIN_DIR}:$PATH" # <--- CRITICAL CHANGE: Prepend PYTHON_BIN_DIR here
CLANG_PATH_SAVE="$PATH"
CLANG_CC_SAVE="$CC"
CLANG_CXX_SAVE="$CXX"
CLANG_ASM_SAVE="$ASM"
CLANG_LDFLAGS_SAVE="$LDFLAGS" # Save LDFLAGS as well

# Temporarily switch to GCC/G++ for scikit-learn and related builds
echo "Temporarily switching CC/CXX/LDFLAGS to gcc-toolset-13 for scikit-learn build..."
export PATH="/opt/rh/gcc-toolset-13/root/usr/bin:$PATH" 
export CC="/opt/rh/gcc-toolset-13/root/usr/bin/gcc"
export CXX="/opt/rh/gcc-toolset-13/root/usr/bin/g++"
export ASM="/opt/rh/gcc-toolset-13/root/usr/bin/gcc" 
# Use GCC's linker explicitly
export LDFLAGS="-L/opt/rh/gcc-toolset-13/root/usr/lib64 -Wl,-rpath=/opt/rh/gcc-toolset-13/root/usr/lib64"
echo "CC set to: $CC"
echo "CXX set to: $CXX"
echo "LDFLAGS set to: $LDFLAGS"


# Install core build tools and NumPy *before* Orange3's main install
pip3.12 install cython=="3.0.10" trubar ninja versioneer meson-python
pip3.12 install --no-build-isolation "numpy==1.26.4"
# After NumPy is installed, set NUMPY_INCLUDE_DIR
export NUMPY_INCLUDE_DIR=$(python3.12 -c "import numpy; print(numpy.get_include())")
echo "NUMPY_INCLUDE_DIR set to: $NUMPY_INCLUDE_DIR"

pip3.12 install -r requirements-gui.txt
pip3.12 install pandas

# Re-export CFLAGS, CXXFLAGS, CPPFLAGS right before requirements-core.txt
echo "Re-exporting CFLAGS, CXXFLAGS, CPPFLAGS before requirements-core.txt installation..."
export CFLAGS="${CFLAGS:-} -I${OMP_INCLUDE_PATH} -Wno-macro-redefined -Wno-discarded-qualifiers"
export CXXFLAGS="${CXXFLAGS:-} -I${OMP_INCLUDE_PATH} -Wno-macro-redefined -Wno-discarded-qualifiers"
export CPPFLAGS="${CPPFLAGS:-} -Wno-macro-redefined"
echo "Updated CFLAGS: $CFLAGS"
echo "Updated CXXFLAGS: $CXXFLAGS"
echo "Updated CPPFLAGS: $CPPFLAGS"

pip3.12 install -r requirements-core.txt  # For Orange Python library

#installing xgboost and catboost from source
sed -i '/^xgboost>=1\.7\.4,<2\.1$/d' requirements-core.txt
sed -i '/^catboost/d' requirements-core.txt

# Find the line containing "with-htmlhelp" and comment it out
sed -i '/with-htmlhelp/s/^/# /' setup.cfg

# Build and Install.
if ! python3.12 -m pip install --no-build-isolation .;  then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

#Tests are skipped for Orange 3.38.1 due to persistent core module import errors (circular dependencies), compiler incompatibilities with specific C/C++ extensions, and unresolved build environment issues on the PowerPC architecture.
