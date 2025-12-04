#!/bin/bash -ex
# --------------------------------------------------------------------------------
# Package        : ml-commons
# Version        : 2.19.2.0
# Source repo    : https://github.com/opensearch-project/ml-commons
# Tested on      : UBI 9.5
# Language       : Java
# Ci-Check   : false
# Maintainer     : Sumit Dubey <sumit.dubey2@ibm.com>
# Script License : Apache License, Version 2.0 or later
#
# Disclaimer     : This script has been tested in non root mode on the specified
#                  platform and package version. Functionality with newer
#                  versions of the package or OS is not guaranteed.
# -------------------------------------------------------------------------------

# ---------------------------
# Check for root user
# ---------------------------
if ! ((${EUID:-0} || "$(id -u)")); then
	set +ex
        echo "FAIL: This script must be run as a non-root user with sudo permissions"
        exit 3
fi

# ---------------------------
# Configuration
# ---------------------------
PACKAGE_NAME="ml-commons"
PACKAGE_ORG="opensearch-project"
PACKAGE_VERSION="2.19.2.0"
PACKAGE_URL="https://github.com/${PACKAGE_ORG}/${PACKAGE_NAME}.git"
ONNX_VERSION=v1.17.1
OPENSEARCH_BUILD_VERSION=2.19.2
PYTORCH_VERSION=1.13.1
DJL_VERSION=v0.33.0
PYTHON_VERSION=3.9
SCRIPT_PATH=$(dirname $(realpath $0))
RUNTESTS=1
DJL_HOME=$HOME/.djl.ai
CONDA_HOME=$HOME/conda
BUILD_HOME="$(pwd)"

# -------------------
# Parse CLI Arguments
# -------------------
for i in "$@"; do
  case $i in
    --skip-tests)
      RUNTESTS=0
      echo "Skipping tests"
      shift
      ;;
    -*|--*)
      echo "Unknown option $i"
      exit 3
      ;;
    *)
      PACKAGE_VERSION=$i
      echo "Building ${PACKAGE_NAME} ${PACKAGE_VERSION}"
      ;;
  esac
done

# ---------------------------
# Dependency Installation
# ---------------------------
sudo yum install -y git wget sudo unzip make cmake gcc gcc-c++ perl python3-devel python3-pip java-17-openjdk-devel openblas-devel bzip2-devel zlib-devel
export JAVA_HOME=$(compgen -G '/usr/lib/jvm/java-17-openjdk-*')
export JRE_HOME=${JAVA_HOME}/jre
export PATH=${JAVA_HOME}/bin:$CONDA_HOME/bin:$PATH

# -------------------------------------------
# Build onnxruntime libraries for unit tests
# -------------------------------------------
cd $BUILD_HOME
git clone https://github.com/microsoft/onnxruntime.git
cd onnxruntime
git checkout $ONNX_VERSION
git apply ${SCRIPT_PATH}/onnxruntime_$ONNX_VERSION.patch
./build.sh --build_java --compile_no_warning_as_error --parallel --config=Release --build_shared_lib --skip_tests --allow_running_as_root
sudo cp $BUILD_HOME/onnxruntime/build/Linux/Release/libonnxruntime.so $BUILD_HOME/onnxruntime/build/Linux/Release/libonnxruntime4j_jni.so /usr/lib64/

# ----------------------------------------------
# Build opensearch tarball for integation tests
# ----------------------------------------------
cd $BUILD_HOME
git clone https://github.com/opensearch-project/opensearch-build
cd opensearch-build
git checkout $OPENSEARCH_BUILD_VERSION
curl -L https://github.com/pyenv/pyenv-installer/raw/master/bin/pyenv-installer | bash
export PYENV_ROOT="$HOME/.pyenv"
python3 -m pip install pipenv
./build.sh manifests/$OPENSEARCH_BUILD_VERSION/opensearch-$OPENSEARCH_BUILD_VERSION.yml -s -c OpenSearch

# --------------
# Install rust
# --------------
curl https://sh.rustup.rs -sSf | sh -s -- -y
source $HOME/.cargo/env
rustup install 1.87
rustup default 1.87

# -----------------
# Install Miniconda
# -----------------
wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-ppc64le.sh
sh Miniconda3-latest-Linux-ppc64le.sh -u -b -p $CONDA_HOME
rm -rf Miniconda3-latest-Linux-ppc64le.sh
$CONDA_HOME/bin/conda update -y -n base conda
conda init bash
source ~/.bashrc

# ---------------------------
# Install python and pytorch 
# ---------------------------
conda install python="$PYTHON_VERSION" pytorch="$PYTORCH_VERSION" -y

# ----------------------
# Build and Install djl
# ----------------------
cd $BUILD_HOME
git clone https://github.com/deepjavalibrary/djl
cd djl/
git checkout $DJL_VERSION
git apply ${SCRIPT_PATH}/djl_$DJL_VERSION.patch
wget https://download.pytorch.org/libtorch/cpu/libtorch-cxx11-abi-shared-with-deps-${PYTORCH_VERSION}%2Bcpu.zip
unzip libtorch-cxx11-abi-shared-with-deps-${PYTORCH_VERSION}+cpu.zip -d $BUILD_HOME/djl/engines/pytorch/pytorch-native 
rm -rf libtorch-cxx11-abi-shared-with-deps-${PYTORCH_VERSION}%2Bcpu.zip
rm -rf $BUILD_HOME/djl/engines/pytorch/pytorch-native/libtorch/include
\cp -rf $CONDA_HOME/lib/python$PYTHON_VERSION/site-packages/torch/include $BUILD_HOME/djl/engines/pytorch/pytorch-native/libtorch/
\cp -rf $CONDA_HOME/lib/python$PYTHON_VERSION/site-packages/torch/lib/* $BUILD_HOME/djl/engines/pytorch/pytorch-native/libtorch/lib/
mkdir -p $DJL_HOME/pytorch/$PYTORCH_VERSION-cpu-linux-ppc64le/
cp $CONDA_HOME/lib/python$PYTHON_VERSION/site-packages/torch/lib/* $DJL_HOME/pytorch/$PYTORCH_VERSION-cpu-linux-ppc64le/
cp $CONDA_HOME/lib/{libprotobuf.so.31,libopenblas.so.0,libgfortran.so.5,libquadmath.so.0} $DJL_HOME/pytorch/$PYTORCH_VERSION-cpu-linux-ppc64le/
./gradlew :engines:pytorch:pytorch-native:compileJNI
./gradlew :engines:pytorch:pytorch-engine:test
./gradlew :extensions:tokenizers:compileJNI
./gradlew :extensions:tokenizers:test
./gradlew -Prelease=true publishToMavenLocal
cd bom
./gradlew build
./gradlew -Prelease=true publishToMavenLocal

# ---------------------------
# Clone and Prepare Repository
# ---------------------------
cd "${BUILD_HOME}"
git clone "${PACKAGE_URL}"
cd "${PACKAGE_NAME}"
git checkout "${PACKAGE_VERSION}"
git apply ${SCRIPT_PATH}/${PACKAGE_NAME}_${PACKAGE_VERSION}.patch

# --------
# Build
# --------
ret=0
./gradlew build -x test -x integTest || ret=$?
if [ $ret -ne 0 ]; then
        set +ex
	echo "------------------ ${PACKAGE_NAME}: Build Failed ------------------"
	exit 1
fi

# --------
# Install
# --------
./gradlew -Prelease=true publishToMavenLocal

# ---------------------------
# Skip Tests?
# ---------------------------
if [ "$RUNTESTS" -eq 0 ]; then
        set +ex
        echo "------------------ Complete: Build and install successful! Tests skipped. ------------------"
        exit 0
fi

# ----------
# Unit Test
# ----------
ret=0
./gradlew test -x integTest --continue || ret=$?
if [ $ret -ne 0 ]; then
        ret=0
        ./gradlew test -x integTest || ret=$?
        if [ $ret -ne 0 ]; then
		set +ex
		echo "------------------ ${PACKAGE_NAME}: Unit Test Failed ------------------"
		exit 2
	fi
fi

# -----------------
# Integration Test
# -----------------
ret=0
./gradlew integTest -PcustomDistributionUrl=${BUILD_HOME}/opensearch-build/tar/builds/opensearch/dist/opensearch-min-${OPENSEARCH_BUILD_VERSION}-SNAPSHOT-linux-ppc64le.tar.gz -Dtests.heap.size=4096m || ret=$?
if [ $ret -ne 0 ]; then
	set +ex
	echo "------------------ ${PACKAGE_NAME}: Integration Test Failed ------------------"
	exit 2
fi

set +ex
echo "------------------ Complete: Build and Tests successful! ------------------"

