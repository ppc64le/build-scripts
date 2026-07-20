#!/bin/bash -ex
# --------------------------------------------------------------------------------
# Package        : ml-commons
# Version        : 3.3.0.0
# Source repo    : https://github.com/opensearch-project/ml-commons
# Tested on      : UBI 9.6
# Language       : Java
# Ci-Check       : false
# Maintainer	 : Prachi Gaonkar <Prachi.Gaonkar@ibm.com>
# Script License : Apache License, Version 2.0 or later
#
# Disclaimer     : This script has been tested in non root mode on the specified
#                  platform and package version. Functionality with newer
#                  versions of the package or OS is not guaranteed.
# -------------------------------------------------------------------------------

# ---------------------------
# Check for root user
# ---------------------------
if [[ "$EUID" -eq 0 ]]; then
	set +ex
        echo "FAIL: Run this script as a non-root user with sudo permissions"
        exit 3
fi


# ---------------------------
# Configuration
# ---------------------------
PACKAGE_NAME="ml-commons"
PACKAGE_ORG="opensearch-project"
SCRIPT_PACKAGE_VERSION="3.3.0.0"
PACKAGE_VERSION="${1:-$SCRIPT_PACKAGE_VERSION}"
PACKAGE_URL="https://github.com/${PACKAGE_ORG}/${PACKAGE_NAME}.git"
OPENSEARCH_VERSION="${PACKAGE_VERSION::-2}"
OPENSEARCH_PACKAGE="OpenSearch"
OPENSEARCH_URL=https://github.com/${PACKAGE_ORG}/${OPENSEARCH_PACKAGE}.git
ONNX_VERSION="v1.17.1"
PYTORCH_VERSION="1.13.1"
DJL_VERSION="v0.33.0"
PYTHON_VERSION="3.9"
BUILD_HOME="$(pwd)"
SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DJL_HOME="$HOME/.djl.ai"
RUN_TESTS=1

# ----------------------------------------------------
# Native build flags (used by PyTorch / native libs)
# ----------------------------------------------------
export USE_LAPACK=1
export BLAS=OpenBLAS
export LAPACK=OpenBLAS
export USE_OPENMP=1
export LDFLAGS="-lopenblas"
export CFLAGS="-I/usr/include"
export LIBRARY_PATH="/usr/lib64:${LIBRARY_PATH:-}"
export MAX_JOBS=1

# -------------------
# Parse CLI Arguments
# -------------------
for i in "$@"; do
  case $i in
    --skip-tests)
      RUN_TESTS=0
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
# Installs both JDK 17 and JDK 21 as required by different components
sudo yum install -y \
  java-17-openjdk-devel \
  java-21-openjdk-devel \
  wget git sudo unzip make cmake \
  gcc gcc-c++ gcc-gfortran \
  perl python3.9-devel python3.9-pip \
  zlib-devel openssl-devel libffi-devel \
  openblas-devel
  
  
# ---------------------------
# Use JDK 17 for ONNX Runtime build
# ---------------------------
# NOTE: compgen may return multiple matches if more than one JDK is installed
export JAVA_HOME=$(compgen -G '/usr/lib/jvm/java-17-openjdk-*')
export JRE_HOME=${JAVA_HOME}/jre
export PATH=${JAVA_HOME}/bin:$PATH

# --------------------------------------
# Build ONNX Runtime with Java bindings
# --------------------------------------
cd $BUILD_HOME
wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/o/opensearch-project-ml-commons/onnxruntime_$ONNX_VERSION.patch
git clone https://github.com/microsoft/onnxruntime.git
cd onnxruntime
git checkout $ONNX_VERSION
git apply $BUILD_HOME/onnxruntime_$ONNX_VERSION.patch
./build.sh --build_java --compile_no_warning_as_error --parallel --config=Release --build_shared_lib --skip_tests --allow_running_as_root
sudo cp $BUILD_HOME/onnxruntime/build/Linux/Release/libonnxruntime.so $BUILD_HOME/onnxruntime/build/Linux/Release/libonnxruntime4j_jni.so /usr/lib64/

# --------------------------------------
#Use jdk21 for ml-commons and djl
# --------------------------------------
export JAVA_HOME=$(compgen -G '/usr/lib/jvm/java-21-openjdk-*')
export JRE_HOME=${JAVA_HOME}/jre
export PATH=${JAVA_HOME}/bin:$PATH

#Build pytorch from source
cd $BUILD_HOME
export PATH=/usr/local/bin:/usr/bin:$PATH
sudo ln -sf $(which python3.9) /usr/bin/python3
sudo ln -sf $(which pip3.9) /usr/bin/pip3
pip3 install packaging "numpy<2.0" wheel setuptools
git clone https://github.com/pytorch/pytorch
cd pytorch
git checkout v${PYTORCH_VERSION}
pip3 install -r requirements.txt
git submodule sync
git submodule update --init --recursive
# Patch required for ppc64le build
sed -i "196d" third_party/gloo/gloo/common/linux.cc
sed -i "197i \ \ \ \ struct ethtool_link_settings req;" third_party/gloo/gloo/common/linux.cc
export PYTORCH_BUILD_VERSION=${PYTORCH_VERSION}
export PYTORCH_BUILD_NUMBER=1
python3 setup.py bdist_wheel
cd dist
pip3 install ./torch-$PYTORCH_VERSION-cp39-cp39-linux_ppc64le.whl

# ------------------------------------
# Rust setup (required by tokenizers)
# ------------------------------------
curl https://sh.rustup.rs -sSf | sh -s -- -y
source $HOME/.cargo/env
rustup install 1.87
rustup default 1.87

# ---------------------------
# Python native dependencies for DJL
# ---------------------------
python3.9 -m pip install abseil_cpp==20240116.2 \
  --prefer-binary \
  --extra-index-url https://wheels.developerfirst.ibm.com/ppc64le/linux

python3.9 -m pip install libprotobuf==4.25.3 \
  --prefer-binary \
  --extra-index-url=https://wheels.developerfirst.ibm.com/ppc64le/linux

# -------------------------------
# Build DJL with PyTorch engine
# -------------------------------
cd $BUILD_HOME
wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/o/opensearch-project-ml-commons/djl_$DJL_VERSION.patch
git clone https://github.com/deepjavalibrary/djl
cd djl/
git checkout $DJL_VERSION
git apply $BUILD_HOME/djl_$DJL_VERSION.patch
wget https://download.pytorch.org/libtorch/cpu/libtorch-cxx11-abi-shared-with-deps-${PYTORCH_VERSION}%2Bcpu.zip
unzip libtorch-cxx11-abi-shared-with-deps-${PYTORCH_VERSION}+cpu.zip -d $BUILD_HOME/djl/engines/pytorch/pytorch-native 
rm -rf libtorch-cxx11-abi-shared-with-deps-${PYTORCH_VERSION}+cpu.zip
rm -rf $BUILD_HOME/djl/engines/pytorch/pytorch-native/libtorch/include
\cp -rf $HOME/.local/lib/python$PYTHON_VERSION/site-packages/torch/include $BUILD_HOME/djl/engines/pytorch/pytorch-native/libtorch/
\cp -rf $HOME/.local/lib/python$PYTHON_VERSION/site-packages/torch/lib/* $BUILD_HOME/djl/engines/pytorch/pytorch-native/libtorch/lib/
mkdir -p $DJL_HOME/pytorch/$PYTORCH_VERSION-cpu-linux-ppc64le/
cp $HOME/.local/lib/python$PYTHON_VERSION/site-packages/torch/lib/* $DJL_HOME/pytorch/$PYTORCH_VERSION-cpu-linux-ppc64le/
cp $HOME/.local/lib/python3.9/site-packages/libprotobuf/lib64/libprotobuf.so.25.3.0 $DJL_HOME/pytorch/$PYTORCH_VERSION-cpu-linux-ppc64le
cp /usr/lib64/libopenblas.so.0 $DJL_HOME/pytorch/$PYTORCH_VERSION-cpu-linux-ppc64le
cp /usr/lib64/libgfortran.so.5 $DJL_HOME/pytorch/$PYTORCH_VERSION-cpu-linux-ppc64le
cp /usr/lib64/libquadmath.so.0 $DJL_HOME/pytorch/$PYTORCH_VERSION-cpu-linux-ppc64le
\cp -rf $HOME/.local/lib/python3.9/site-packages/abseilcpp/lib/*   $BUILD_HOME/djl/engines/pytorch/pytorch-native/libtorch/lib/
\cp -rf $HOME/.local/lib/python3.9/site-packages/abseilcpp/lib/* $HOME/.djl.ai/pytorch/$PYTORCH_VERSION-cpu-linux-ppc64le

# Create versioned symlinks for abseil libraries
cd $DJL_HOME/pytorch/$PYTORCH_VERSION-cpu-linux-ppc64le/
    for f in libabsl_*.so; do     ln -sf $f ${f}.2401.0.0; done


# ---------------------------
# Build DJL components
# ---------------------------	
cd $BUILD_HOME/djl
export LD_LIBRARY_PATH=$DJL_HOME/pytorch/$PYTORCH_VERSION-cpu-linux-ppc64le:$LD_LIBRARY_PATH
./gradlew :engines:pytorch:pytorch-native:compileJNI
 ./gradlew --no-daemon :engines:pytorch:pytorch-engine:test   -Dengine.pytorch.disable_native_extraction=true   -Djava.library.path=$DJL_HOME/pytorch/$PYTORCH_VERSION-cpu-linux-ppc64le
./gradlew :extensions:tokenizers:compileJNI
./gradlew --no-daemon :extensions:tokenizers:test   -Dengine.pytorch.disable_native_extraction=true   -Djava.library.path=$DJL_HOME/pytorch/$PYTORCH_VERSION-cpu-linux-ppc64le   -Dai.djl.debug=true
./gradlew -Prelease=true publishToMavenLocal
cd bom
./gradlew build
./gradlew -Prelease=true publishToMavenLocal


# ------------------------------
# Build OpenSearch distribution
# ------------------------------
cd $BUILD_HOME
git clone https://github.com/opensearch-project/OpenSearch
cd OpenSearch
git checkout $OPENSEARCH_VERSION
./gradlew -p distribution/archives/linux-ppc64le-tar assemble
./gradlew -Prelease=true publishToMavenLocal
./gradlew :build-tools:publishToMavenLocal

# ---------------------------
# Build Job Scheduler
# ---------------------------
cd $BUILD_HOME
git clone https://github.com/opensearch-project/job-scheduler
cd job-scheduler
git checkout $PACKAGE_VERSION
./gradlew assemble
./gradlew -Prelease=true publishToMavenLocal

# ---------------------------
# Build Remote Metadata SDK
# ---------------------------
cd $BUILD_HOME
git clone https://github.com/opensearch-project/opensearch-remote-metadata-sdk
cd opensearch-remote-metadata-sdk
git checkout $PACKAGE_VERSION
export GRADLE_OPTS="-Dorg.gradle.console=plain"
./gradlew build
./gradlew -Prelease=true publishToMavenLocal


# ---------------------------
# Clone and Prepare Repository
# ---------------------------
cd $BUILD_HOME
git clone https://github.com/opensearch-project/ml-commons
cd ml-commons
git checkout $PACKAGE_VERSION
git apply ${SCRIPT_PATH}/ml-commons_$SCRIPT_PACKAGE_VERSION.patch


# --------
# Build
# --------
ret=0
./gradlew build -x test -x integTest -Dbuild.snapshot=false|| ret=$?
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
if [ "$RUN_TESTS" -eq 0 ]; then
        set +ex
        echo "------------------ Complete: Build and install successful! Tests skipped. ------------------"
        exit 0
fi

# ----------
# Unit Test
# ----------
ret=0
./gradlew test -x integTest --continue -Dorg.opensearch.djl.pytorch.path=$DJL_HOME/pytorch/$PYTORCH_VERSION-cpu-linux-ppc64le || ret=$?
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
./gradlew integTest -PcustomDistributionUrl=$BUILD_HOME/OpenSearch/distribution/archives/linux-ppc64le-tar/build/distributions/opensearch-min-$OPENSEARCH_VERSION-SNAPSHOT-linux-ppc64le.tar.gz   -Dbuild.snapshot=false -Dorg.opensearch.djl.pytorch.path=$DJL_HOME/pytorch/$PYTORCH_VERSION-cpu-linux-ppc64le || ret=$?
if [ $ret -ne 0 ]; then
	set +ex
	echo "------------------ ${PACKAGE_NAME}: Integration Test Failed ------------------"
	exit 2
fi

set +ex
echo "------------------ Complete: Build and Tests successful! ------------------"
echo "CI checks are disabled for this script due to the build time exceeding the maximum execution limit (6 hours) on GitHub Actions."