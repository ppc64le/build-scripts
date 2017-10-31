# ----------------------------------------------------------------------------
#
# Package	: TensorFlow
# Version	: 1.3.1
# Source repo	: https://github.com/tensorflow/tensorflow
# Tested on	: rhel_7.4
# Script License: Apache License, Version 2 or later
# Maintainer	: Sandip Giri <sgiri@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

#################################Tensorflow Build Script##################################

#Install required dependencies
sudo yum update -y && \
        sudo yum install -y java-1.8.0-openjdk-devel.ppc64le wget autoconf libtool curl make unzip zip git gcc-c++ which 

#Set Java_HOME , JRE_HOME and PATH
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk
export JRE_HOME=${JAVA_HOME}/jre
export PATH=${JAVA_HOME}/bin:$PATH

wdir=`pwd`

cd /tmp && \
	wget https://storage.googleapis.com/golang/go1.8.1.linux-ppc64le.tar.gz && \
	sudo tar -C /usr/local -xzf go1.8.1.linux-ppc64le.tar.gz && \
export PATH=$PATH:/usr/local/go/bin

################################ Build Bazel 0.5.4 for Tensorflow v1.3.1 #############################################
cd $wdir
mkdir bazel && cd bazel && 
wget https://github.com/bazelbuild/bazel/releases/download/0.5.4/bazel-0.5.4-dist.zip  && \
	 unzip bazel-0.5.4-dist.zip  && \
  	 chmod -R +w . && \
	 ./compile.sh && \
	 export PATH=$PATH:$wdir/bazel/output

################################ Build Tensorflow from latest branch #############################################
cd $wdir
wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm && \
        sudo rpm -ivh epel-release-latest-7.noarch.rpm && \
        sudo yum update -y 


sudo yum install -y python-pip python-wheel swig python-devel.ppc64le atlas blas lapack \
        numpy openblas-devel.ppc64le python-virtualenv.noarch libcurl-devel.ppc64le patch hdf5-devel.ppc64le && \
        sudo pip install --upgrade pip && \
        sudo pip install six numpy==1.12.0 wheel portpicker pandas scipy h5py scikit-learn && \
        sudo touch /usr/include/stropts.h


#To build TF with GPU-enabled, first we need to install cuda and cudnn dependencies, please refer page http://www.nvidia.com/object/gpu-accelerated-applications-tensorflow-installation.html to install the same
git clone --recurse-submodules https://github.com/tensorflow/tensorflow && \
        cd tensorflow && \
        git checkout v1.3.1 && \
	patch -p1 < $wdir/patches_rhel74/denormal_test_ppc_TF1.3.1.patch && \
        patch -p1 < $wdir/patches_rhel74/sparse_matmul_op_ppc_TF1.3.1.patch && \
        patch -p1 < $wdir/patches_rhel74/update-highwayhash_TF1.3.1.patch && \
        export CC_OPT_FLAGS="-mcpu=power8 -mtune=power8" && \
        export GCC_HOST_COMPILER_PATH=/usr/bin/gcc && \
        export PYTHON_BIN_PATH=/usr/bin/python && \
        export USE_DEFAULT_PYTHON_LIB_PATH=1 && \
        export TF_NEED_GCP=1 && \
        export TF_NEED_HDFS=1 && \
        export TF_NEED_JEMALLOC=1 && \
        export TF_ENABLE_XLA=1 && \
        export TF_NEED_OPENCL=0 && \
        export TF_NEED_CUDA=1 && \
 	export TF_CUDA_VERSION=8.0 && \
	export CUDA_TOOLKIT_PATH=/usr/local/cuda-8.0 && \
	export TF_CUDA_COMPUTE_CAPABILITIES=3.5,3.7,5.2,6.0 && \
	export CUDNN_INSTALL_PATH=/usr/local/cuda-8.0 && \
	export TF_CUDNN_VERSION=6 && \
	export TF_NEED_MKL=0 && \
	export TF_NEED_VERBS=0 && \
	export TF_NEED_MPI=0 && \
	export TF_CUDA_CLANG=0 && \
        ./configure && \
        bazel build --config=opt --config=cuda //tensorflow/tools/pip_package:build_pip_package --local_resources=32000,8,1.0 && \
        sudo bazel-bin/tensorflow/tools/pip_package/build_pip_package /tmp/tensorflow_pkg && \
        sudo pip install /tmp/tensorflow_pkg/tensorflow-1.3.1* 

# We have disabled the tests, please run below commands to execute all test cases (might take some time to complete)
#	 export LD_LIBRARY_PATH="/usr/local/cuda/lib64:/usr/local/cuda/extras/CUPTI/lib64:$LD_LIBRARY_PATH" && \
#        bazel test --config=opt --config=cuda -k --jobs 1 //tensorflow/...

