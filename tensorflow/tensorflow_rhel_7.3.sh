# ----------------------------------------------------------------------------
#
# Package	: TensorFlow
# Version	: 1.0.1
# Source repo	: https://github.com/tensorflow/tensorflow
# Tested on	: rhel_7.3
# Script License: Apache License, Version 2 or later
# Maintainer	: Atul Sowani <sowania@us.ibm.com>
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
        sudo yum install -y java-1.8.0-openjdk-devel.ppc64le

#Set Java_HOME , JRE_HOME and PATH
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk
export JRE_HOME=${JAVA_HOME}/jre
export PATH=${JAVA_HOME}/bin:$PATH

wdir=`pwd`

############################## A. Install Protobuf for Bazel ###############################
sudo yum install -y autoconf automake libtool curl make gcc-c++ unzip zip git
git clone https://github.com/ibmsoe/protobuf-1/ protobuf && \
        cd protobuf && \
        git checkout r3.0.0-ppc && \
        ./autogen.sh && \
	./configure --prefix=/opt/DL/protobuf && \
        sed -i "s/^LDFLAGS = -static/LDFLAGS = -all-static/g" src/Makefile && \
        make && sudo make install

export PROTOC=/opt/DL/protobuf/bin/protoc

############################ B. Build grpc-java 1.0.0 for Bazel #################################

########## I.Build protobuf 3.0.0b3 for grpc-java
cd /$wdir
git clone https://github.com/google/protobuf.git protobuf3.0 && \
        cd protobuf3.0 && \
        git checkout v3.0.0-beta-3 && \
        sudo git cherry-pick 1760feb621a913189b90fe8595fffb74bce84598 && \
        ./autogen.sh && \
        ./configure && \
        make && \
	sudo make install

######### II. Build grpc-java*
cd /$wdir
sudo yum install -y libstdc++-static.ppc64le
git clone https://github.com/grpc/grpc-java.git && \
        cd grpc-java && \
        git checkout v1.0.0 && \
        export CXXFLAGS="-I/$wdir/protobuf3.0/src" LDFLAGS="-L/$wdir/protobuf3.0/src/.libs" &&\
        sudo git cherry-pick 862157a84be602c1cabfb46958511489337bfd36 && \
        cd compiler && \
        GRPC_BUILD_CMD="../gradlew java_pluginExecutable" && \
        eval $GRPC_BUILD_CMD

export GRPC_JAVA_PLUGIN=/$wdir/grpc-java/compiler/build/exe/java_plugin/protoc-gen-grpc-java

################################ C. Build Bazel 0.4.4 for Tensorflow #############################################
cd /$wdir
git clone https://github.com/bazelbuild/bazel.git && \
	 cd bazel && git checkout 0.4.4 && \
  	./compile.sh && \
	PATH=/$wdir/bazel/output:$PATH

################################ D. Build Tensorflow from latest branch #############################################
cd /$wdir
sudo yum install -y wget
wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm && \
        sudo rpm -ivh epel-release-latest-7.noarch.rpm && \
        sudo yum update -y 

sudo yum install -y python-pip python-wheel swig python-devel.ppc64le atlas-devel.ppc64le blas-devel.ppc64le \
        numpy.ppc64le openblas-devel.ppc64le python-virtualenv.noarch libcurl-devel.ppc64le patch &&\
        sudo pip install six numpy==1.12.0 wheel  && \
        sudo pip install --upgrade pip && \
        sudo touch /usr/include/stropts.h

sudo pip install portpicker scipy

#To build TF with GPU-enabled, first we need to install cuda and cudnn dependencies, please refer page http://www.nvidia.com/object/gpu-accelerated-applications-tensorflow-installation.html to install the same
git clone --recurse-submodules https://github.com/tensorflow/tensorflow && \
        cd tensorflow && \
        git checkout v1.0.1 && \
	patch -p1 < /$wdir/patches/10-cudnn-dir.patch && \
        patch -p1 < /$wdir/patches/30-llvm-target-triple-to-powerpc64le.patch && \
        patch -p1 < /$wdir/patches/40-jemalloc-support.patch && \
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
	export TF_CUDNN_VERSION=5 && \
        ./configure && \
        bazel build --config=opt --config=cuda //tensorflow/tools/pip_package:build_pip_package --local_resources=32000,8,1.0 && \
        sudo bazel-bin/tensorflow/tools/pip_package/build_pip_package /tmp/tensorflow_pkg && \
        sudo pip install /tmp/tensorflow_pkg/tensorflow-1.0.1* && \
	export LD_LIBRARY_PATH="/usr/local/cuda/lib64:/usr/local/cuda/extras/CUPTI/lib64:$LD_LIBRARY_PATH" && \
        bazel test --config=opt --config=cuda -k --jobs 1 //tensorflow/...
