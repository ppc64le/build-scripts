#!/bin/bash -ex
# --------------------------------------------------------------------------------
# Package        : neural-search
# Version        : 3.2.0.0
# Source repo    : https://github.com/opensearch-project/neural-search
# Tested on      : UBI 9.6
# Language       : Java
# Travis-Check   : false
# Maintainer     : Prachi Gaonkar <Prachi.Gaonkar@ibm.com>
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
PACKAGE_NAME="neural-search"
PACKAGE_ORG="opensearch-project"
SCRIPT_PACKAGE_VERSION="3.2.0.0"
PACKAGE_VERSION=${1:-${SCRIPT_PACKAGE_VERSION}}
PACKAGE_URL="https://github.com/${PACKAGE_ORG}/${PACKAGE_NAME}.git"
OPENSEARCH_URL=https://github.com/opensearch-project/OpenSearch.git
OPENSEARCH_VERSION=${PACKAGE_VERSION::-2}
OPENSEARCH_PACKAGE=OpenSearch
BUILD_HOME=`pwd`
SCRIPT=$(readlink -f $0)
SCRIPT_PATH=$(dirname $SCRIPT)

DJL_HOME=$HOME/.djl.ai
PYTORCH_VERSION=2.5.1
DJL_VERSION=v0.33.0
PYTHON_VERSION=3.12
export LD_LIBRARY_PATH=/home/testuser/.djl.ai/tokenizers/0.21.0-0.33.0-SNAPSHOT-cpu-linux-ppc64le:/home/testuser/.djl.ai/pytorch/2.5.1-cpu-linux-ppc64le:$LD_LIBRARY_PATH

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
sudo yum install -y git wget sudo unzip make cmake gcc gcc-c++ perl python3.12 python3.12-devel python3.12-pip java-21-openjdk-devel openblas-devel bzip2-devel zlib-devel
export JAVA_HOME=$(compgen -G '/usr/lib/jvm/java-21-openjdk-*')
export JRE_HOME=${JAVA_HOME}/jre
export PATH=${JAVA_HOME}/bin:$PATH

#wget https://github.com/adoptium/temurin24-binaries/releases/download/jdk-24%2B36/OpenJDK24U-jdk_ppc64le_linux_hotspot_24_36.tar.gz
#sudo tar -C /usr/local -zxf OpenJDK24U-jdk_ppc64le_linux_hotspot_24_36.tar.gz
#export JAVA_HOME=/usr/local/jdk-24+36/
#export PATH=/usr/local/jdk-24+36/bin:$PATH
#sudo ln -sf /usr/local/jdk-24+36/bin/java /usr/bin/

curl https://sh.rustup.rs -sSf | sh -s -- -y
source $HOME/.cargo/env

python3.12 -m pip install abseil_cpp==20240116.2   --prefer-binary --extra-index-url https://wheels.developerfirst.ibm.com/ppc64le/linux
python3.12 -m pip install libprotobuf==4.25.3 --prefer-binary --extra-index-url=https://wheels.developerfirst.ibm.com/ppc64le/linux
#python3.12 -m pip install tokenizers==0.21.0  --prefer-binary --extra-index-url https://wheels.developerfirst.ibm.com/ppc64le/linux
#python3.12 -m pip install onnxruntime==1.21.1 --prefer-binary --extra-index-url https://wheels.developerfirst.ibm.com/ppc64le/linux
python3.12 -m pip install torch==2.5.1  --prefer-binary --extra-index-url https://wheels.developerfirst.ibm.com/ppc64le/linux

wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/o/opensearch-project-ml-commons/djl_v0.33.0.patch
sed '/^diff --git a\/gradle\/libs\.versions\.toml/,$d' djl_v0.33.0.patch > djl_v0.33.0-truncated.patch


cd $BUILD_HOME
git clone https://github.com/deepjavalibrary/djl
cd djl/
git checkout $DJL_VERSION
git apply ../djl_$DJL_VERSION-truncated.patch
wget https://download.pytorch.org/libtorch/cpu/libtorch-cxx11-abi-shared-with-deps-${PYTORCH_VERSION}%2Bcpu.zip
unzip libtorch-cxx11-abi-shared-with-deps-${PYTORCH_VERSION}+cpu.zip -d $BUILD_HOME/djl/engines/pytorch/pytorch-native 
rm -rf libtorch-cxx11-abi-shared-with-deps-${PYTORCH_VERSION}+cpu.zip
rm -rf $BUILD_HOME/djl/engines/pytorch/pytorch-native/libtorch/include
\cp -rf /home/testuser/.local/lib/python$PYTHON_VERSION/site-packages/torch/include $BUILD_HOME/djl/engines/pytorch/pytorch-native/libtorch/
\cp -rf /home/testuser/.local/lib/python$PYTHON_VERSION/site-packages/torch/lib/* $BUILD_HOME/djl/engines/pytorch/pytorch-native/libtorch/lib/
mkdir -p $DJL_HOME/pytorch/$PYTORCH_VERSION-cpu-linux-ppc64le/
cp /home/testuser/.local/lib/python$PYTHON_VERSION/site-packages/torch/lib/* $DJL_HOME/pytorch/$PYTORCH_VERSION-cpu-linux-ppc64le/

cp /home/testuser/.local/lib/python3.12/site-packages/libprotobuf/lib64/libprotobuf.so.25.3.0 $DJL_HOME/pytorch/$PYTORCH_VERSION-cpu-linux-ppc64le
cp /usr/lib64/libopenblas.so.0 $DJL_HOME/pytorch/$PYTORCH_VERSION-cpu-linux-ppc64le
cp /usr/lib64/libgfortran.so.5 $DJL_HOME/pytorch/$PYTORCH_VERSION-cpu-linux-ppc64le
cp /usr/lib64/libquadmath.so.0 $DJL_HOME/pytorch/$PYTORCH_VERSION-cpu-linux-ppc64le
\cp -rf /home/testuser/.local/lib/python3.12/site-packages/abseilcpp/lib/*   $BUILD_HOME/djl/engines/pytorch/pytorch-native/libtorch/lib/

\cp -rf /home/testuser/.local/lib/python3.12/site-packages/abseilcpp/lib/* /home/testuser/.djl.ai/pytorch/2.5.1-cpu-linux-ppc64le

cd $DJL_HOME/pytorch/$PYTORCH_VERSION-cpu-linux-ppc64le/
    for f in libabsl_*.so; do     ln -sf $f ${f}.2401.0.0; done
	
cd $BUILD_HOME/djl
./gradlew :engines:pytorch:pytorch-native:compileJNI
./gradlew :engines:pytorch:pytorch-engine:test
./gradlew :extensions:tokenizers:compileJNI
./gradlew :extensions:tokenizers:test
./gradlew -Prelease=true publishToMavenLocal
cd bom
./gradlew build
./gradlew -Prelease=true publishToMavenLocal
