#!/bin/bash -ex
# --------------------------------------------------------------------------------------------
#
# Package       : ml-commons
# Version       : 2.11.1.0
# Source repo   : https://github.com/opensearch-project/ml-commons
# Tested on     : UBI 8.7 (docker)
# Language      : Java
# Travis-Check  : False
# Script License: Apache License, Version 2 or later
# Maintainer    : Pratik Tonage <pratik.tonage@ibm.com>, Sumit Dubey <Sumit.Dubey2@ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# --------------------------------------------------------------------------------------------

# Install RHEL dependencies
sudo yum install -y git wget unzip make cmake gcc gcc-c++ openssl-devel perl java-17-openjdk-devel bzip2-devel zlib-devel 

# Set variables
WDIR=$(pwd)
PACKAGE_NAME=ml-commons
PACKAGE_URL=https://github.com/opensearch-project/ml-commons
PACKAGE_VERSION=${1:-2.11.1.0}
PYTHON_VERSION=3.9
PYTORCH_VERSION=1.13.1
DJL_VERSION=v0.21.0
ONNX_VERSION=v1.17.1
OPENSEARCH_BUILD_VERSION=2.13.0
CONDA_HOME=$HOME/conda
DJL_HOME=$HOME/.djl.ai
export JAVA_HOME=$(compgen -G '/usr/lib/jvm/java-17-openjdk-*')
export JRE_HOME=${JAVA_HOME}/jre
export PATH=${JAVA_HOME}/bin:$CONDA_HOME/bin:$PATH

#Install rust and cargo
curl https://sh.rustup.rs -sSf | sh -s -- -y
source "$HOME/.cargo/env"
rustup install 1.72.1
rustup default 1.72.1

# Install Miniconda
wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-ppc64le.sh
sh Miniconda3-latest-Linux-ppc64le.sh -u -b -p $CONDA_HOME
rm -rf Miniconda3-latest-Linux-ppc64le.sh
$CONDA_HOME/bin/conda update -y -n base conda
conda init bash
source ~/.bashrc

# Install python and pytorch 
conda install python="$PYTHON_VERSION" pytorch="$PYTORCH_VERSION" -y

#Build opensearch-build tarball for integTest.
cd $WDIR
git clone https://github.com/opensearch-project/opensearch-build
cd opensearch-build
git checkout $OPENSEARCH_BUILD_VERSION
curl -L https://github.com/pyenv/pyenv-installer/raw/master/bin/pyenv-installer | bash
export PYENV_ROOT="$HOME/.pyenv"
python3 -m pip install pipenv
./build.sh legacy-manifests/2.11.1/opensearch-2.11.1.yml -s -c OpenSearch

# Clone DJL repository
cd $WDIR
git clone https://github.com/deepjavalibrary/djl
cd djl/
git checkout $DJL_VERSION
git apply ../djl-$DJL_VERSION.patch

# Copy libtorch directory to trick the build to not download libtorch for ppc64le
cd engines/pytorch/pytorch-native/
mkdir libtorch && cd libtorch/
cp -r $CONDA_HOME/lib/python$PYTHON_VERSION/site-packages/torch/include .
wget https://download.pytorch.org/libtorch/cpu/libtorch-cxx11-abi-shared-with-deps-$PYTORCH_VERSION%2Bcpu.zip
unzip libtorch-cxx11-abi-shared-with-deps-$PYTORCH_VERSION+cpu.zip
cp -r libtorch/share/ .
cp -r $CONDA_HOME/lib/python$PYTHON_VERSION/site-packages/torch/lib .
rm -rf libtorch libtorch-cxx11-abi-shared-with-deps-$PYTORCH_VERSION+cpu.zip

#Copy pytorch and dependent libraries to djl cache
mkdir -p $DJL_HOME/pytorch/$PYTORCH_VERSION-cpu-linux-ppc64le/
cp $CONDA_HOME/lib/python$PYTHON_VERSION/site-packages/torch/lib/* $DJL_HOME/pytorch/$PYTORCH_VERSION-cpu-linux-ppc64le/
cp $CONDA_HOME/lib/{libprotobuf.so.31,libopenblas.so.0,libgfortran.so.5,libquadmath.so.0} $DJL_HOME/pytorch/$PYTORCH_VERSION-cpu-linux-ppc64le/

# Build pytorch-engine and tokenizers libraries
cd $WDIR/djl
./gradlew :engines:pytorch:pytorch-native:compileJNI
./gradlew :engines:pytorch:pytorch-engine:test
./gradlew :extensions:tokenizers:compileJNI
./gradlew :extensions:tokenizers:test
./gradlew -Prelease=true publishToMavenLocal
cd bom
./gradlew build
./gradlew -Prelease=true publishToMavenLocal

# Build onnxruntime libraries for unit tests
cd $WDIR
git clone https://github.com/microsoft/onnxruntime.git
cd onnxruntime
git checkout $ONNX_VERSION
./build.sh --build_java --compile_no_warning_as_error --parallel --config=Release --build_shared_lib --skip_tests
sudo cp ./build/Linux/Release/libonnxruntime.so ./build/Linux/Release/libonnxruntime4j_jni.so /usr/lib64/

# Clone ml-commons repository
cd $WDIR
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
git apply ../$PACKAGE_NAME-$PACKAGE_VERSION.patch

#Build ml-commons
if ! ./gradlew build -x test -x integTest ; then
        echo "------------------$PACKAGE_NAME:Build_fails---------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME"
        echo "$PACKAGE_NAME | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Build_Fails"
        exit 1
fi		

#Unit tests
if ! ./gradlew test -x integTest ; then
            echo "------------------$PACKAGE_NAME:Unit_test_fails---------------------"
            echo "$PACKAGE_VERSION $PACKAGE_NAME"
            echo "$PACKAGE_NAME | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Unit_test_Fails"
            exit 2		
fi

#Integration tests
if ! ./gradlew integTest -PcustomDistributionUrl=$WDIR/opensearch-build/tar/builds/opensearch/dist/opensearch-min-2.11.1-SNAPSHOT-linux-ppc64le.tar.gz -Dtests.heap.size=4096m ; then
            echo "------------------$PACKAGE_NAME: integTest_fails---------------------"
            echo "$PACKAGE_VERSION $PACKAGE_NAME"
            echo "$PACKAGE_NAME | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | integTest_Fails"
            exit 2	
fi      
echo "Build and Test Success"
