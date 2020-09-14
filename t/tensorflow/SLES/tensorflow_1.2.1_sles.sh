# ----------------------------------------------------------------------------
#
# Package	: TensorFlow
# Version	: 1.2.1
# Source repo	: https://github.com/tensorflow/tensorflow
# Tested on	: SLES 12 SP2
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

######################Tensorflow Build Script ################################
#Install required dependencies
sudo zypper update -y
sudo zypper install -y git 

wdir=`pwd`

# Clone TensorFLow Source
git clone --recurse-submodules https://github.com/tensorflow/tensorflow
cd tensorflow 
git checkout v1.2.1
 
sudo zypper install -y  java-1_8_0-openjdk-devel \
wget autoconf libtool curl make unzip zip gcc-c++
		 
#Set Java_HOME , JRE_HOME and PATH
export JAVA_HOME=/usr/lib64/jvm/java-1.8.0-openjdk && \
export JRE_HOME=${JAVA_HOME}/jre && \
export PATH=${JAVA_HOME}/bin:$PATH


cd /tmp && \
	wget https://storage.googleapis.com/golang/go1.8.1.linux-ppc64le.tar.gz && \
	sudo tar -C /usr/local -xzf go1.8.1.linux-ppc64le.tar.gz && \
export PATH=$PATH:/usr/local/go/bin		 

#################### Build Bazel for Tensorflow #############################
cd $wdir
mkdir bazel && cd bazel && \
wget https://github.com/bazelbuild/bazel/releases/download/0.4.5/bazel-0.4.5-dist.zip  && \
	unzip bazel-0.4.5-dist.zip  && \
	chmod -R +w . && \
	./compile.sh  && \
	export PATH=$PATH:$wdir/bazel/output 
	

##############  Build Tensorflow v1.2.1 ##################################
cd $wdir
 
sudo zypper addrepo  http://download.opensuse.org/ports/ppc/factory/repo/oss/ OpenSuse
sudo zypper --gpg-auto-import-keys refresh
sudo zypper install -y  python2-pip  python-wheel gcc swig python-devel atlascpp-devel  blas-devel \
        python2-numpy python2-numpy-devel gcc-fortran openblas-devel python2-virtualenv libcurl-devel patch python-curses && \
        sudo pip install six wheel  && \
        sudo pip install --upgrade pip && \
        sudo touch /usr/include/stropts.h
	sudo pip install portpicker scipy py-cpuinfo psutil sklearn
sudo zypper rr  http://download.opensuse.org/ports/ppc/factory/repo/oss/

cd tensorflow
patch -p1 < $wdir/patches/cast_op_test_ppc64le.patch && \
        patch -p1 < $wdir/patches/denormal_test_ppc.patch && \
        patch -p1 < $wdir/patches/larger-tolerence-in-linalg_grad_test.patch && \
        patch -p1 < $wdir/patches/platform_profile_utils_cpu_utils_test_ppc64le.patch && \
        patch -p1 < $wdir/patches/sparse_matmul_op_ppc.patch && \
        patch -p1 < $wdir/patches/update-highwayhash.patch && \
	patch -p1 < $wdir/patches/mfcc_test.patch && \
        patch -p1 < $wdir/patches/Fix_for_summary_image_op_test_on_ppc64le.patch && \
        cp $wdir/patches/packetmath_altivec.patch  $wdir/tensorflow/third_party/eigen3/ && \
        patch -p1 < $wdir/patches/need_to_apply_packetmath_altivec.patch && \
        export CC_OPT_FLAGS="-mcpu=power8 -mtune=power8" && \
        export GCC_HOST_COMPILER_PATH=/usr/bin/gcc && \
        export PYTHON_BIN_PATH=/usr/bin/python && \
        export USE_DEFAULT_PYTHON_LIB_PATH=1 && \
        export TF_NEED_GCP=1 && \
        export TF_NEED_HDFS=1 && \
        export TF_NEED_JEMALLOC=1 && \
        export TF_ENABLE_XLA=1 && \
        export TF_NEED_OPENCL=0 && \
        export TF_NEED_CUDA=0 && \
        export TF_NEED_MKL=0 && \
	export TF_NEED_VERBS=0 && \
	export TF_NEED_MPI=0 && \
	export TF_CUDA_CLANG=0 && \
        ./configure && \
	sudo zypper install -y  gcc48-c++  gcc48 && \
	sudo rm /usr/bin/g++ /usr/bin/gcc && \
	sudo ln /usr/bin/g++-4.8  /usr/bin/g++ && \
	sudo ln /usr/bin/gcc-4.8 /usr/bin/gcc && \
        bazel build -c opt  //tensorflow/tools/pip_package:build_pip_package --local_resources=32000,8,1.0 && \
        sudo bazel-bin/tensorflow/tools/pip_package/build_pip_package /tmp/tensorflow_pkg && \
        sudo pip install /tmp/tensorflow_pkg/tensorflow-1.2.1* && \
        bazel test -c opt -k //tensorflow/...  2>&1 | tee -a logfile
