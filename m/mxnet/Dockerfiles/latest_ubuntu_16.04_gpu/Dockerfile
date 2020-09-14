# Dockerfile to build mxnet on Ubuntu_16.04 (GPU)

FROM nvidia/cuda-ppc64le:9.0-cudnn7-devel-ubuntu16.04

# Building MXNet from source is a 2 step process.
   # 1.Build the MXNet core shared library, libmxnet.so, from the C++ sources.
   # 2.Build the language specific bindings. Example - Python bindings, Scala bindings.

RUN apt-get update -y && \
	# 1. ------------ Build the MXNet core shared library ------------------ 
        # libraries for building mxnet c++ core on ubuntu
        apt-get install -y \
        build-essential git libopenblas-dev liblapack-dev libopencv-dev \
        libcurl4-openssl-dev libgtest-dev cmake wget unzip libatlas-base-dev  python-opencv \
        && \
        cd /usr/src/gtest && \
        cmake CMakeLists.txt && \
        make && \
        cp *.a /usr/lib  \
        && \
	cd / && \
	# Download MXNet sources and build MXNet core shared library
        git clone --recursive https://github.com/apache/incubator-mxnet.git mxnet && \
        cd mxnet && \
	git clone https://github.com/NVlabs/cub && \
        git checkout 1.0.0 && \
        git submodule update --recursive && \
	make -j $(nproc) USE_OPENCV=1 USE_BLAS=openblas USE_CUDA=1 USE_CUDA_PATH=/usr/local/cuda USE_CUDNN=1 USE_PROFILER=1 && \
        rm -r build \
        && \
	# 2. -------------- Build the MXNet Python binding ------------------
        # install libraries for mxnet's python package on ubuntu
        apt-get update && \
        apt-get install -y python-dev python-setuptools python-numpy python-pip && \
	# Install the MXNet Python binding.
        cd python && \
        pip install --upgrade pip && \
        pip install -e . && \
	apt-get purge -y build-essential git libcurl4-openssl-dev libgtest-dev cmake wget unzip libatlas-base-dev  python-opencv && \
	apt-get autoremove -y && \
	apt-get clean

ENV PYTHONPATH=/mxnet/python
CMD  bash


# Install Graphviz. (Optional, needed for graph visualization using mxnet.viz package).
 # apt-get install graphviz -y
 # pip install graphviz

# Running the unit tests (run the following from MXNet root directory)
 # pip install pytest nose numpy==1.12.0
 # apt-get install -y python-scipy
 # python -m pytest -v tests/python/unittest
 # python -m pytest -v tests/python/train

