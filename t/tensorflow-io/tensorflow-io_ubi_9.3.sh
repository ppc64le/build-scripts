#!/bin/bash -ex
# -----------------------------------------------------------------------------
#
# Package          : io
# Version          : v0.35.0
# Source repo      : https://github.com/tensorflow/io.git
# Tested on        : UBI:9.3
# Language         : Python
# Ci-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Stuti Wali <Stuti.Wali@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------------

# Exit immediately if a command exits with a non-zero status
set -e

# Variables
PACKAGE_NAME=io
PACKAGE_VERSION=${1:-v0.35.0}
PACKAGE_URL=https://github.com/tensorflow/io.git
CURRENT_DIR=$(pwd)
PACKAGE_DIR=io


echo "Installing GCC 12..."
yum install -y wget python3.11 python3.11-pip python3.11-devel git make cmake binutils
yum install -y gcc-toolset-12-gcc-c++ gcc-toolset-12 gcc-toolset-12-binutils gcc-toolset-12-binutils-devel
yum install -y xz xz-devel openssl-devel cmake zlib zlib-devel libjpeg-devel libevent libtool pkg-config  brotli-devel bzip2-devel lz4-devel libtiff-devel ninja-build libgomp
yum install -y libffi-devel freetype-devel procps-ng openblas-devel meson gcc-gfortran libomp-devel zip unzip sqlite sqlite-devel libxcrypt libxcrypt-compat rsync

# Set up environment variables for GCC 12
export GCC_HOME=/opt/rh/gcc-toolset-12/root/usr
export CC=$GCC_HOME/bin/gcc
export CXX=$GCC_HOME/bin/g++
export GCC=$CC
export GXX=$CXX

# Add GCC 12 to the PATH (removing previous gcc paths if any)
export PATH=$(echo $PATH | tr ':' '\n' | grep -v -e '/gcc-toolset' -e '/usr/bin/gcc' | tr '\n' ':')
export PATH=$GCC_HOME/bin:$PATH

export LD_LIBRARY_PATH=$(echo $LD_LIBRARY_PATH | tr ':' '\n' | grep -v -e '/gcc-toolset' | tr '\n' ':')
export LD_LIBRARY_PATH=$GCC_HOME/lib64:$LD_LIBRARY_PATH

ln -sf /opt/rh/gcc-toolset-12/root/usr/lib64/libctf.so.0 /usr/lib64/libctf.so.0

# Verify GCC 12 installation
gcc --version

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

python3.11 -m pip install --upgrade pip
python3.11 -m pip install --upgrade --ignore-installed setuptools wheel build ninja

INSTALL_ROOT="/install-deps"
mkdir -p $INSTALL_ROOT

for package in openblas ; do
    mkdir -p ${INSTALL_ROOT}/${package}
    export "${package^^}_PREFIX=${INSTALL_ROOT}/${package}"
    echo "Exported ${package^^}_PREFIX=${INSTALL_ROOT}/${package}"
done


#Install the dependencies
echo "------------------------Installing dependencies-------------------"
yum install -y  autoconf automake libtool curl-devel  atlas-devel patch 


#Build HDF5 from source 
cd $CURRENT_DIR
git clone https://github.com/HDFGroup/hdf5
cd hdf5/
git checkout hdf5-1_12_1
git submodule update --init
./configure --prefix=/usr/local/hdf5 --enable-cxx --enable-fortran  --with-pthread=yes --enable-threadsafe  --enable-build-mode=production --enable-unsupported  --enable-using-memchecker  --enable-clear-file-buffers --with-ssl
make 
make install

export LD_LIBRARY_PATH=/usr/local/hdf5/:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=/usr/local/hdf5/lib/:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=/usr/local/hdf5/include:$LD_LIBRARY_PATH
export HDF5_DIR=/usr/local/hdf5
echo "-----------------------------------------------------Installed HDF5 to /usr/local-----------------------------------------------------"


#Build and install h5py from source 
cd $CURRENT_DIR
git clone https://github.com/h5py/h5py.git
cd h5py/
git checkout 3.13.0
python3.11 -m pip install .  

cd $CURRENT_DIR
python3.11 -c "import h5py; print(h5py.__version__)"
echo "-----------------------------------------------------Installed h5py-----------------------------------------------------"


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

#installing patchelf from source
cd $CURRENT_DIR
git clone https://github.com/NixOS/patchelf.git
cd patchelf
./bootstrap.sh
./configure
make
make install
ln -s /usr/local/bin/patchelf /usr/bin/patchelf
echo "-----------------------------------------------------Installed patchelf-----------------------------------------------------"


#installing patchelf from source
cd $CURRENT_DIR
yum install -y krb5-devel
git clone https://github.com/alisw/libtirpc
cd libtirpc
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

#installing dm-tree
cd $CURRENT_DIR
yum install -y make libtool cmake git wget xz zlib-devel openssl-devel bzip2-devel libffi-devel libevent-devel libjpeg-turbo-devel

export PATH=/opt/rh/gcc-toolset-12/root/usr/bin:$PATH

git clone https://github.com/deepmind/tree
cd tree
git checkout 0.1.8

python3.11 -m pip install --upgrade --ignore-installed pip setuptools wheel

# install scikit-learn dependencies and build dependencies
python3.11 -m pip install pytest absl-py attr numpy wrapt attrs

#Download and apply the patch file
wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/d/dm-tree/update_abseil_version_and_linking_fix.patch
git apply update_abseil_version_and_linking_fix.patch
#Build
python3.11 -m pip install .
echo "-----------------------------------------------------Installed dm-tree-----------------------------------------------------"

# Install six.
echo "------------------------Installing dependencies-------------------"
python3.11 -m pip install --upgrade absl-py
python3.11 -m pip install --upgrade six==1.16.0
python3.11 -m pip install "numpy<2" wheel==0.38.4 werkzeug
python3.11 -m pip install "urllib3<1.27,>=1.21.1" requests
python3.11 -m pip install "protobuf<=4.25.2"
python3.11 -m pip install tensorflow-datasets

# Install numpy, scipy and scikit-learn required by the builds
ln -s /usr/include/locale.h /usr/include/xlocale.h

export LD_LIBRARY_PATH=/usr/lib64/:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-12/root/usr/lib64:$LD_LIBRARY_PATH
export GRPC_PYTHON_BUILD_SYSTEM_OPENSSL=true

#Build tensorflow-io-gcs-filesystem
echo "------------------------Cloning tensorflow-io-------------------"
cd $CURRENT_DIR
git clone $PACKAGE_URL
cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION

echo "------------------------Generating wheel-------------------"
python3.11 -m pip install --upgrade pip wheel
python3.11 setup.py -q bdist_wheel --project tensorflow_io_gcs_filesystem
cd dist
python3.11 -m pip install tensorflow_io_gcs_filesystem-*-linux_ppc64le.whl
cd ..
rm -rf dist

#Build tensorflow
echo "------------------------Cloning tensorflow-------------------"
cd $CURRENT_DIR
git clone https://github.com/tensorflow/tensorflow
cd  tensorflow
git checkout v2.14.1

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
echo "-----------------------Applied patch successfully---------------------------------------"

export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-12/root/usr/lib64:$LD_LIBRARY_PATH
yes n | ./configure

echo "------------------------Bazel query-------------------"
bazel query "//tensorflow/tools/pip_package:*"

echo "Bazel query successful ---------------------------------------------------------------------------------------------"
bazel build -s //tensorflow/tools/pip_package:build_pip_package --config=opt

echo "Bazel build successful ---------------------------------------------------------------------------------------------"

#building the wheel
bazel-bin/tensorflow/tools/pip_package/build_pip_package $CURRENT_DIR

echo "Build wheel ---------------------------------------------------------------------------------------------"

cd $CURRENT_DIR

python3.11 -m pip install tensorflow-2.14.1-*-linux_ppc64le.whl

echo "Wheel installed succesfuly ---------------------------------------------------------------------------------------------"

python3.11 -c "import tensorflow as tf; print(tf.__version__)"
export TF_HEADER_DIR=$(python3.11 -c "import tensorflow as tf; print(tf.sysconfig.get_include())")
export TF_SHARED_LIBRARY_DIR=$(python3.11 -c "import tensorflow as tf; print(tf.sysconfig.get_lib())")
export TF_SHARED_LIBRARY_NAME="libtensorflow_framework.so.2"

export BAZEL_CXXOPTS="-std=c++17"
export BAZEL_CXXFLAGS="-std=c++17"
export CC=/opt/rh/gcc-toolset-12/root/usr/bin/gcc
export CXX=/opt/rh/gcc-toolset-12/root/usr/bin/g++


cd $CURRENT_DIR/io
python3.11 -m pip install grpcio-tools==1.56.2 --no-cache-dir
python3.11 -m pip install .

export PYTHON_BIN_PATH="$PYTHON"
export PYTHON_LIB_PATH="$SP_DIR"
export PYTHON_PATH="$PYTHON"
export TF_PYTHON_VERSION=$(python3.11 --version | awk '{print $2}' | cut -d. -f1,2)
export TF_HEADER_DIR=$(python3.11 -c "import tensorflow as tf; print(tf.sysconfig.get_include())")
export TF_SHARED_LIBRARY_DIR=$(python3.11 -c "import tensorflow as tf; print(tf.sysconfig.get_lib())")
export TF_SHARED_LIBRARY_NAME="libtensorflow_framework.so.2"
export PYTHON_BIN_PATH="$PYTHON"
export PYTHON_LIB_PATH="$SP_DIR"
export PYTHON_PATH="$PYTHON"
export CXXFLAGS="-std=c++17 -fvisibility=hidden -D_GLIBCXX_USE_CXX11_ABI=1 -DEIGEN_MAX_ALIGN_BYTES=64 -Wno-maybe-uninitialized"
export BAZEL_OPTIMIZATION="--config=optimization"
export TF_USE_MODULAR_FILESYSTEM=1

# Define the file path
BAZELRC_FILE="tf_io.bazelrc"

# Create the file and write the content
cat > "$BAZELRC_FILE" <<EOL
# Optimization flags
build:optimization --copt="-mcpu=${cpu_model}"
build:optimization --copt="-mtune=${cpu_model}"
#build:optimization --copt="-march=${cpu_model}"
# General build flags
build --copt="-fvisibility=hidden"
build --copt="-D_GLIBCXX_USE_CXX11_ABI=1"
build --copt="-DEIGEN_MAX_ALIGN_BYTES=64"
build --copt="-Wno-maybe-uninitialized"
build --cxxopt="-std=c++17"
# Ensure C++17 is used globally for all builds and external repositories
build --host_cxxopt="-std=c++17"
build --repo_env=CC="gcc"
build --repo_env=CXX="g++ -std=c++17"
build --action_env=CXXFLAGS="-std=c++17"
build --action_env=CXX="g++ -std=c++17"
# TensorFlow shared library name
build --action_env TF_SHARED_LIBRARY_NAME="libtensorflow_framework.so.2"
# Experimental flags and platform-specific configurations
build --experimental_repo_remote_exec
build --enable_platform_specific_config
# Optimization mode
build:optimization --compilation_mode=opt
# Build verbosity and debugging options
build --noshow_progress
build --noshow_loading_progress
build --verbose_failures
build --test_output=errors
build --experimental_ui_max_stdouterr_bytes=-1
# Enforce consistent C++ version for external dependencies
build --crosstool_top=@bazel_tools//tools/cpp:toolchain
build --extra_toolchains=@bazel_tools//tools/cpp:all
build --incompatible_enable_cc_toolchain_resolution
EOL

echo "tf_io.bazelrc file has been created successfully."

wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/t/tensorflow-io-gcs-filesystem/tf-io-gcs-filesystem.patch
git apply tf-io-gcs-filesystem.patch

echo "---------------------------------Building the package--------------------------------------------"

#Install
if ! (bazel build   --experimental_repo_remote_exec   --cxxopt="-std=c++17"   --cxxopt="-I/usr/local/include/tirpc"   --host_cxxopt="-std=c++17"   --host_cxxopt="-I/usr/local/include/tirpc"   --repo_env=CXX="g++ -std=c++17"   //tensorflow_io/... //tensorflow_io_gcs_filesystem/...) ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

echo "-----------------------Building tf-io wheel ----------------------------"
python3.11 setup.py bdist_wheel --data bazel-bin --dist-dir $CURRENT_DIR

# Commenting out the test part as no test targets were found.
# echo "---------------------------------Running tests----------------------------------------------"

# # Create a temporary log file to capture output
# TEST_LOG=$(mktemp)

# # Run bazel test with live output and log capture
# bazel test --cxxopt='-std=c++17' \
#            --cxxopt='-I/usr/local/include/tirpc' \
#            --host_cxxopt='-std=c++17' \
#            --host_cxxopt='-I/usr/local/include/tirpc' \
#            --experimental_repo_remote_exec //tensorflow_io/... 2>&1 | tee "$TEST_LOG"


# # Capture actual Bazel exit code
# TEST_EXIT_CODE=${PIPESTATUS[0]}

# # Read full test output (if needed)
# TEST_OUTPUT=$(cat "$TEST_LOG")

# # Analyze test results
# if echo "$TEST_OUTPUT" | grep -q "No test targets were found"; then
#     echo "------------------$PACKAGE_NAME:no_test_targets_found---------------------"
#     echo "$PACKAGE_URL $PACKAGE_NAME"
#     echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Pass | No_Test_Targets_Found"
#     exit 0
# elif [ $TEST_EXIT_CODE -ne 0 ]; then
#     echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
#     echo "$PACKAGE_URL $PACKAGE_NAME"
#     echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_Success_But_Test_Fails"
#     exit 2
# else
#     echo "------------------$PACKAGE_NAME:install_&_test_both_success------------------------"
#     echo "$PACKAGE_URL $PACKAGE_NAME"
#     echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Pass | Both_Install_and_Test_Success"
#     exit 0
# fi
