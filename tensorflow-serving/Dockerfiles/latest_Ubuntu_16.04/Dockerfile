#Dockerfile for Tensorflow-Serving on ppc64le

FROM ppc64le/ubuntu:16.04

#Install required dependencies and build TensorFlow-Serving
RUN apt-get update -y && \
	apt-get install -y openjdk-8-jdk wget autoconf libtool curl make unzip zip git g++ && \
	export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-ppc64el && \
	export JRE_HOME=${JAVA_HOME}/jre && \
	export PATH=${JAVA_HOME}/bin:$PATH && \
        wdir=`pwd` && \
        mkdir bazel && cd bazel && \
	wget https://github.com/bazelbuild/bazel/releases/download/0.4.5/bazel-0.4.5-dist.zip  && \
	unzip bazel-0.4.5-dist.zip  && \
	chmod -R +w . && \
	./compile.sh && \
        export PATH=$PATH:$wdir/bazel/output && \
        cd $wdir && \
	apt-get install -y libcurl3-dev libfreetype6-dev libzmq3-dev pkg-config python-dev python-numpy python-pip swig && \
	git clone --recurse-submodules https://github.com/tensorflow/serving && \
        cd serving && \
        git checkout 1.0.0 && \
        git submodule update --recursive && \
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
        export TF_NEED_GDR=0 && \
        ./configure && \
        cd .. && \
        bazel build -c opt --local_resources 4096,4.0,1.0 -j 1 tensorflow_serving/... && \
        bazel test -c opt tensorflow_serving/...  && \
        apt-get purge -y  wget autoconf libtool curl make unzip zip git libcurl3-dev libfreetype6-dev libzmq3-dev pkg-config  && \
        apt-get -y autoremove 

CMD ["/bin/bash"]  

