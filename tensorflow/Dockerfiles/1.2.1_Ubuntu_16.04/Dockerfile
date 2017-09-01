#Dockerfile for Tensorflow on ppc64le

FROM ppc64le/ubuntu:16.04

COPY patches patches/ 

#Install required dependencies and build TensorFlow
RUN apt-get update -y && \
        apt-get install -y openjdk-8-jdk wget autoconf libtool curl make unzip zip git g++  && \
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
	apt-get install -y libcurl3-dev libfreetype6-dev libzmq3-dev pkg-config python-dev python-numpy python-pip swig \
	libatlas-dev libopenblas-dev python-virtualenv  && \
	pip install six numpy==1.12.0 portpicker scipy && \
        pip install --upgrade pip && \
        touch /usr/include/stropts.h && \
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
	export TF_NEED_MKL=0 && \
	./configure && \
        bazel build --config=opt //tensorflow/tools/pip_package:build_pip_package --local_resources=32000,8,1.0 && \
        bazel-bin/tensorflow/tools/pip_package/build_pip_package /tmp/tensorflow_pkg && \
        pip install /tmp/tensorflow_pkg/tensorflow-1.2.1*  && \
	apt-get purge -y wget autoconf libtool curl make unzip zip git libcurl3-dev libfreetype6-dev libzmq3-dev pkg-config libatlas-dev libopenblas-dev && \
        apt-get -y autoremove 
							
	# To execute all test cases please run the below command
	# $ bazel test --config=opt  -k --jobs 1 //tensorflow/...  
		
CMD ["/bin/bash"]		
        
