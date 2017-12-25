# Dockerfile for Tensorflow-1.3.1 for ppc64le with GPU suppport

FROM nvidia/cuda-ppc64le:8.0-cudnn6-devel-ubuntu16.04

LABEL maintainer="Sandip Giri <sgiri@us.ibm.com>" 

ENV JAVA_HOME /usr/lib/jvm/java-1.8.0-openjdk-ppc64el 
ENV JRE_HOME ${JAVA_HOME}/jre 
ENV PATH ${JAVA_HOME}/bin:$PATH

ENV LD_LIBRARY_PATH /usr/local/cuda/extras/CUPTI/lib64:$LD_LIBRARY_PATH

RUN apt-get update -y && apt-get install -y --no-install-recommends \
        openjdk-8-jdk \
	wget \
	curl \
	unzip \
	zip \
  	git \
	rsync \
        python-dev \
	swig \
	python-pip \
	libatlas-dev \
	python-numpy \
	libopenblas-dev \
	libcurl3-dev \
	libfreetype6-dev \
	libzmq3-dev \
	libhdf5-dev \
	&& \
    mkdir bazel && cd bazel && \
        wget https://github.com/bazelbuild/bazel/releases/download/0.5.4/bazel-0.5.4-dist.zip  && \
        unzip bazel-0.5.4-dist.zip  && \
        chmod -R +w . && \
        ./compile.sh && \
	cd / && \
	export PATH=$PATH:/bazel/output  \
        && \
    pip install --upgrade pip &&  pip install -U setuptools && \
	pip --no-cache-dir install \
	six \
	numpy==1.12.0 \
        wheel \
        portpicker \
        pandas \
        scipy \
        jupyter \
        scikit-learn \
        && \
    git clone --recurse-submodules https://github.com/tensorflow/tensorflow && \
        cd tensorflow && \
        git checkout v1.3.1 && \
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
	touch /usr/include/stropts.h && \
	ln -s /usr/local/cuda/lib64/stubs/libcuda.so /usr/local/cuda/lib64/stubs/libcuda.so.1 && \
	LD_LIBRARY_PATH=/usr/local/cuda/lib64/stubs:${LD_LIBRARY_PATH} \
        tensorflow/tools/ci_build/builds/configured GPU \
        bazel build --config=opt --config=cuda //tensorflow/tools/pip_package:build_pip_package --local_resources=32000,8,1.0 && \
        bazel-bin/tensorflow/tools/pip_package/build_pip_package /tmp/tensorflow_pkg && \
        pip install /tmp/tensorflow_pkg/tensorflow-1.3.1* \
        && \
    cd /tensorflow/tensorflow/tools/docker && \
   	mkdir /root/.jupyter/ && \
	cp jupyter_notebook_config.py /root/.jupyter/ && \
	cp -r notebooks /notebooks && \
	cp run_jupyter.sh /  \
        && \
    apt-get purge -y  openjdk-8-jdk libatlas-dev libopenblas-dev wget zip git rsync && \
        apt-get -y autoremove && \
        apt-get clean && \
        rm -rf /tensorflow /bazel /tmp/tensorflow_pkg /root/.cache /var/lib/apt/lists/* 

# TensorBoard
EXPOSE 6006

# IPython
EXPOSE 8888

WORKDIR "/notebooks"

CMD ["/run_jupyter.sh", "--allow-root"]


