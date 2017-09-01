#!/bin/bash

sudo zypper update -y && \
         sudo zypper install -y  java-1_8_0-openjdk-devel 

#Set Java_HOME , JRE_HOME and PATH
export JAVA_HOME=/usr/lib64/jvm/java-1.8.0-openjdk && \
export JRE_HOME=${JAVA_HOME}/jre && \
export PATH=${JAVA_HOME}/bin:$PATH

wdir=`pwd`

############################## A. Install Protobuf for Bazel ###############################
sudo zypper install -y autoconf automake libtool curl make unzip zip git-core
git clone https://github.com/ibmsoe/protobuf-1/ protobuf && \
        cd protobuf && \
        git checkout r3.0.0-ppc && \
        ./autogen.sh && \
        LDFLAGS= ./configure --prefix=/opt/DL/protobuf && \
        sed -i "s/^LDFLAGS = -static/LDFLAGS = -all-static/g" src/Makefile && \
        make && sudo make install

export PROTOC=/opt/DL/protobuf/bin/protoc

############################ B. Build grpc-java 1.0.0 for Bazel #################################

########## I.Build protobuf 3.0.0b3 for grpc-java
cd $wdir
git clone https://github.com/google/protobuf.git protobuf3.0 && \
        cd protobuf3.0 && \
        git checkout v3.0.0-beta-3 && \
        git cherry-pick 1760feb621a913189b90fe8595fffb74bce84598  && \
        ./autogen.sh && \
        ./configure && \
        make && \
        sudo make install

######### II. Build grpc-java*
cd $wdir

git clone https://github.com/grpc/grpc-java.git && \
        cd grpc-java && \
        git checkout v1.0.0 && \
        export CXXFLAGS="-I$wdir/protobuf3.0/src" LDFLAGS="-L$wdir/protobuf3.0/src/.libs" &&\
        sudo git cherry-pick 862157a84be602c1cabfb46958511489337bfd36 && \
        cd compiler && \
        GRPC_BUILD_CMD="../gradlew java_pluginExecutable" && \
        eval $GRPC_BUILD_CMD

export GRPC_JAVA_PLUGIN=$wdir/grpc-java/compiler/build/exe/java_plugin/protoc-gen-grpc-java

################################ C. Build Bazel 0.4.5 for Tensorflow #############################################
cd $wdir
git clone https://github.com/bazelbuild/bazel.git && \
        cd bazel && git checkout 0.4.5 && \
        ./compile.sh && \
        PATH=$wdir/bazel/output:$PATH

################################  Build Tensorflow v1.2.1 #############################################
cd $wdir
sudo zypper install -y wget
sudo zypper install -y  python2-pip  python-wheel gcc swig python-devel atlascpp-devel  blas-devel \
        python2-numpy-devel  openblas-devel python2-virtualenv libcurl-devel patch python-curses && \
        sudo pip install six numpy==1.12.0 wheel  && \
        sudo pip install --upgrade pip && \
        sudo touch /usr/include/stropts.h
sudo pip install portpicker scipy py-cpuinfo psutil
git clone --recurse-submodules https://github.com/tensorflow/tensorflow && \
        cd tensorflow && \
        git checkout v1.2.1 && \
		patch -p1 < $wdir/patches/cast_op_test_ppc64le.patch && \
        patch -p1 < $wdir/patches/denormal_test_ppc.patch && \
        patch -p1 < $wdir/patches/larger-tolerence-in-linalg_grad_test.patch && \
        patch -p1 < $wdir/patches/platform_profile_utils_cpu_utils_test_ppc64le.patch && \
        patch -p1 < $wdir/patches/sparse_matmul_op_ppc.patch && \
        patch -p1 < $wdir/patches/update-highwayhash.patch && \
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
	    export TF_NEED_VERBS=0 && \
	    export TF_NEED_MPI=0 && \
        ./configure && \
        cd .. && \
        bazel build -c opt  //tensorflow/tools/pip_package:build_pip_package --local_resources=32000,8,1.0 && \
        sudo bazel-bin/tensorflow/tools/pip_package/build_pip_package /tmp/tensorflow_pkg && \
        sudo pip install /tmp/tensorflow_pkg/tensorflow-1.2.1* && \
        bazel test -c opt //tensorflow/... 2>&1 | tee -a /$wdir/logfile
