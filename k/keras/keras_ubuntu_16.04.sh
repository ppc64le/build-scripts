# ----------------------------------------------------------------------------
#
# Package       : keras
# Version       : 2.0.8
# Source repo   : https://github.com/fchollet/keras.git
# Tested on     : ubuntu_16.04
# Script License: Apache License, Version 2 or later
# Maintainer    : Snehlata Mohite <smohite@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#     It may not work as expected with newer versions of the
#     package and/or distribution. In such case, please
#     contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

# Install dependencies.
sudo apt-get update -y
sudo apt-get install -y git python python-setuptools python-dev python-pil \
    python-pydot python-yaml build-essential libhdf5-dev libfreetype6-dev \
    libblas-dev liblapack-dev libopenblas-dev libatlas-base-dev gfortran \
    libxft-dev libopenjpeg-dev tk-dev zlib1g-dev libjpeg-dev libpng3 \
    libcupti-dev openjdk-8-jdk wget autoconf libtool curl make unzip zip \
    g++ libcurl3-dev libzmq3-dev pkg-config swig

WDIR=`pwd`
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-ppc64el
export JRE_HOME=${JAVA_HOME}/jre
export PATH=${JAVA_HOME}/bin:$PATH

sudo easy_install pip
sudo pip install numpy pytest graphviz mock image h5py pytz matplotlib \
    pandas theano six scipy pyparsing pep8 pytest-pep8 pytest-xdist \
    pytest-cov pytest-cache execnet pytest-forked coverage apipkg portpicker

# Build TensorFlow and Bazel (which is required to build TF).
mkdir bazel && cd bazel
wget https://github.com/bazelbuild/bazel/releases/download/0.4.5/bazel-0.4.5-dist.zip
unzip bazel-0.4.5-dist.zip
./compile.sh
export PATH=$PATH:$WDIR/bazel/output

cd $WDIR
sudo touch /usr/include/stropts.h
git clone --recurse-submodules https://github.com/tensorflow/tensorflow
cd tensorflow
git checkout v1.2.1
export CC_OPT_FLAGS="-mcpu=power8 -mtune=power8"
export GCC_HOST_COMPILER_PATH=/usr/bin/gcc
export PYTHON_BIN_PATH=/usr/bin/python
export USE_DEFAULT_PYTHON_LIB_PATH=1
export TF_NEED_GCP=1
export TF_NEED_HDFS=1
export TF_NEED_JEMALLOC=1
export TF_ENABLE_XLA=1
export TF_NEED_OPENCL=0
export TF_NEED_CUDA=0
export TF_NEED_VERBS=0
export TF_NEED_MKL=0
./configure
bazel build --config=opt //tensorflow/tools/pip_package:build_pip_package \
  --local_resources=32000,8,1.0
bazel-bin/tensorflow/tools/pip_package/build_pip_package /tmp/tensorflow_pkg
sudo pip install /tmp/tensorflow_pkg/tensorflow-1.2.1*

# Clone and build source code.
cd $WDIR
git clone --depth=50 https://github.com/fchollet/keras.git
cd keras
python setup.py build
sudo python setup.py install

# Run tests.
# Tensorflow as backend only.
export KERAS_BACKEND=tensorflow
python -c "import keras.backend" && py.test

# Tensorflow as a backend and pep8 as a Test mode.
export TEST_MODE=PEP8
python -c "import keras.backend" && py.test

# Tensorflow as a backend and Test mode.
export TEST_MODE=INTEGRATION_TESTS
python -c "import keras.backend" && py.test

# Theano as backend & THEANO_FLAGS.
export KERAS_BACKEND=theano
export THEANO_FLAGS=optimizer=fast_compile
python -c "import keras.backend" && py.test
