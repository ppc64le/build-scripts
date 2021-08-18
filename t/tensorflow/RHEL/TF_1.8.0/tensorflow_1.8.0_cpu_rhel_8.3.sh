# ----------------------------------------------------------------------------
#
# Package       : TensorFlow
# Version       : 1.8.0
# Source repo   : https://github.com/tensorflow/tensorflow
# Tested on     : RHEL 8.3, UBI 8.3
# Script License: Apache License, Version 2 or later
# Maintainer    : Priya Seth <sethp@us.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

yum install -y wget

wdir=`pwd`

#Enable EPEL
wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
yum install -y epel-release-latest-8.noarch.rpm
rm -f epel-release-latest-8.noarch.rpm

#Enable Centos 8.2 repositories
yum install -y http://mirror.centos.org/centos/8-stream/BaseOS/ppc64le/os/Packages/centos-stream-repos-8-2.el8.noarch.rpm http://mirror.centos.org/centos/8-stream/BaseOS/ppc64le/os/Packages/centos-gpg-keys-8-2.el8.noarch.rpm

#Install the dependencies
yum install -y autoconf \
automake \
libtool \
gcc-c++ \
gcc-gfortran \
java-1.8.0-openjdk-devel \
curl \
git \
unzip \
zip \
swig \
freetype-devel \
hdf5-devel \
atlas-devel \
python3 \
python3-devel \
python3-setuptools \
python3-virtualenv \
python3-wheel \
patch \
https://rpmfind.net/linux/centos/8.3.2011/PowerTools/ppc64le/os/Packages/blas-devel-3.8.0-8.el8.ppc64le.rpm \
https://rpmfind.net/linux/centos/8.3.2011/PowerTools/ppc64le/os/Packages/lapack-devel-3.8.0-8.el8.ppc64le.rpm

#Set Python3 as default
ln -s /usr/bin/python3 /usr/bin/python

#Set JAVA_HOME
export JAVA_HOME=$(dirname $(dirname $(dirname $(readlink -f $(which java)))))

# Build Bazel dependency
mkdir bazel
cd bazel
wget https://github.com/bazelbuild/bazel/releases/download/0.10.0/bazel-0.10.0-dist.zip
unzip bazel-0.10.0-dist.zip
chmod -R +w .
#Hack to avoid the zip bomb error
#"error: invalid zip file with overlapped components (possible zip bomb)"
sed -i '123s/$/ | echo 0/' ./scripts/bootstrap/compile.sh
./compile.sh
cd $wdir
export PATH=$PATH:$wdir/bazel/output

# Install pip3
wget -q https://bootstrap.pypa.io/get-pip.py
python3 get-pip.py
rm -f get-pip.py

#Install pip packages
pip3 install --upgrade setuptools
pip3 install --upgrade pip
pip3 install --upgrade virtualenv

# Install six.
pip3 install --upgrade absl-py
pip3 install --upgrade six==1.10.0

# Install protobuf.
pip3 install --upgrade protobuf==3.3.0

# Remove obsolete version of six, which can sometimes confuse virtualenv.
rm -rf /usr/lib/python3/dist-packages/six*

# Install numpy, scipy and scikit-learn required by the builds
ln -s /usr/include/locale.h /usr/include/xlocale.h
pip3 install --no-binary=:all: --upgrade numpy==1.12.0
pip3 install scipy==0.18.1
pip3 install scikit-learn==0.19.1

# pandas required by `inflow`
pip3 install pandas==0.19.2

# Install recent-enough version of wheel for Python 3.5 wheel builds
pip3 install wheel==0.29.0
pip3 install portpicker
pip3 install werkzeug
pip3 install grpcio

# Eager-to-graph execution needs astor, gast and termcolor:
pip3 install --upgrade astor
pip3 install --upgrade gast
pip3 install --upgrade termcolor

#Build tensorflow v1.8.0
cd $wdir
git clone https://github.com/tensorflow/tensorflow.git
cd tensorflow
git checkout v1.8.0

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

#apply patch
git apply $wdir/tensorflow_1.8.0_png.patch
bazel build --config opt //tensorflow/java:tensorflow //tensorflow/java:libtensorflow_jni //tensorflow/java:libtensorflow.jar //tensorflow/tools/lib_package:libtensorflow.tar.gz //tensorflow/tools/lib_package:libtensorflow_jni.tar.gz //tensorflow/java:libtensorflow-src.jar //tensorflow/tools/lib_package:libtensorflow_proto.zip
bazel test --config opt //tensorflow/java/...
