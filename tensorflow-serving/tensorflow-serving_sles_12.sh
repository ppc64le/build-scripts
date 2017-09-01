#!/bin/bash

zypper update -y && \
         zypper install -y  java-1_8_0-openjdk-devel 

#Set Java_HOME , JRE_HOME and PATH
export JAVA_HOME=/usr/lib64/jvm/java-1.8.0-openjdk && \
export JRE_HOME=${JAVA_HOME}/jre && \
export PATH=${JAVA_HOME}/bin:$PATH

wdir=`pwd`

############################## A. Install Protobuf for Bazel ###############################
zypper install -y autoconf automake libtool curl make unzip zip git-core
git clone https://github.com/ibmsoe/protobuf-1/ protobuf && \
        cd protobuf && \
        git checkout r3.0.0-ppc && \
        ./autogen.sh && \
        LDFLAGS= ./configure --prefix=/opt/DL/protobuf && \
        sed -i "s/^LDFLAGS = -static/LDFLAGS = -all-static/g" src/Makefile && \
        make && make install

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
        make install

######### II. Build grpc-java*
cd $wdir

git clone https://github.com/grpc/grpc-java.git && \
        cd grpc-java && \
        git checkout v1.0.0 && \
        export CXXFLAGS="-I$wdir/protobuf3.0/src" LDFLAGS="-L$wdir/protobuf3.0/src/.libs" &&\
        git cherry-pick 862157a84be602c1cabfb46958511489337bfd36 && \
        cd compiler && \
        GRPC_BUILD_CMD="../gradlew java_pluginExecutable" && \
        eval $GRPC_BUILD_CMD

export GRPC_JAVA_PLUGIN=$wdir/grpc-java/compiler/build/exe/java_plugin/protoc-gen-grpc-java

################################ C. Build Bazel 0.4.5 for Tensorflow Serving #############################################
cd $wdir
git clone https://github.com/bazelbuild/bazel.git && \
        cd bazel && git checkout 0.4.5 && \
        ./compile.sh && \
        PATH=$wdir/bazel/output:$PATH

#Downgrade gcc
zypper remove -y gcc g++
zypper install -y gcc48 gcc48-c++ && \
        ln /usr/bin/gcc-4.8 /usr/bin/gcc && \
        ln /usr/bin/g++-4.8 /usr/bin/g++ 

################################  Build Tensorflow Serving v1.0.0 #############################################
cd $wdir
zypper install -y swig python-devel python2-numpy-devel python2-pip libcurl-devel libfreetype6 libpng12-devel \
       libzmq3 zlib-devel pkg-config
git clone --recurse-submodules https://github.com/tensorflow/serving && \
        cd serving && \
        git checkout 1.0.0 && \
        cd tensorflow && \
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
        bazel build -c opt --local_resources 4096,4.0,1.0 -j 1 tensorflow_serving/... && \
        bazel-bin/tensorflow_serving/tools/pip_package/build_pip_package /tmp/tensorflow_serving_pkg && \
        pip install /tmp/tensorflow_serving_pkg/tensorflow_serving_* && \
        bazel test -c opt tensorflow_serving/... 2>&1 | tee -a $wdir/logfile

