# ----------------------------------------------------------------------------
#
# Package       : TensorFlow
# Version       : master(1.9.0-rc0)
# Source repo   : https://github.com/tensorflow/tensorflow
# Tested on     : Ubuntu_16.04
# Script License: Apache License, Version 2 or later
# Maintainer    : Sandip Giri <sgiri@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

# Build script for TensorFlow master(1.9.0-rc0) on Ubuntu 16.04 (with CPU only)

export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-ppc64el 
export JRE_HOME=${JAVA_HOME}/jre 
export PATH=${JAVA_HOME}/bin:$PATH

wdir=`pwd`

# Install required dependencies
sudo apt-get update -y 
sudo apt-get install -y --no-install-recommends \
openjdk-8-jdk \
wget \
curl \
unzip \
zip \
git \
rsync \
python-dev \
swig \
libatlas-dev \
python-numpy \
libopenblas-dev \
libcurl3-dev \
libfreetype6-dev \
libzmq3-dev \
libhdf5-dev \
g++ \
curl \
patch \
python-pip

# Build Bazel dependency
mkdir bazel 
cd bazel 
wget https://github.com/bazelbuild/bazel/releases/download/0.11.1/bazel-0.11.1-dist.zip  
unzip bazel-0.11.1-dist.zip  
chmod -R +w . 
./compile.sh 
cd $wdir 
export PATH=$PATH:$wdir/bazel/output  

sudo -H pip install --upgrade pip 
sudo -H pip install -U setuptools mock
sudo -H pip --no-cache-dir install \
six \
numpy==1.12.0 \
wheel \
portpicker \
pandas \
scipy \
jupyter \
scikit-learn \
enum34

sudo touch /usr/include/stropts.h

#  Build Tensorflow 
git clone https://github.com/tensorflow/tensorflow.git
cd tensorflow
export CC_OPT_FLAGS="-mcpu=power8 -mtune=power8" 
export GCC_HOST_COMPILER_PATH=/usr/bin/gcc 
export PYTHON_BIN_PATH=/usr/bin/python 
export USE_DEFAULT_PYTHON_LIB_PATH=1 
export TF_NEED_GCP=1 
export TF_NEED_HDFS=1 
export TF_NEED_JEMALLOC=1 
export TF_ENABLE_XLA=0 
export TF_NEED_OPENCL=0 
export TF_NEED_CUDA=0
export TF_NEED_MKL=0 
export TF_NEED_VERBS=0 
export TF_NEED_MPI=0 
export TF_CUDA_CLANG=0

yes n | ./configure
bazel build -c opt //tensorflow/tools/pip_package:build_pip_package --local_resources=32000,8,1.0 
sudo bazel-bin/tensorflow/tools/pip_package/build_pip_package /tmp/tensorflow_pkg 
sudo -H pip install /tmp/tensorflow_pkg/tensorflow-* 

# We have disabled the tests, please run below command to execute the test cases
#(might take some time to complete)

# bazel test -c opt  -k --jobs 1 test_timeout 300,450,1200,3600 \
# 	--build_tests_only -- //tensorflow/... -//tensorflow/compiler/...  \
#   -//tensorflow/contrib/lite/... 
