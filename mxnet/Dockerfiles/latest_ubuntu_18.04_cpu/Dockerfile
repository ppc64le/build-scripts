# Dockerfile to build mxnet on Ubuntu_18.04 (CPU)

FROM ubuntu:18.04

# Building MXNet from source is a 2 step process.
   # 1.Build the MXNet core shared library, libmxnet.so, from the C++ sources.
   # 2.Build the language specific bindings. Example - Python bindings, Scala bindings.
ENV DEBIAN_FRONTEND="noninteractive"
RUN apt-get update -y && \
        # 1. ------------ Build the MXNet core shared library ------------------
        # libraries for building mxnet c++ core on ubuntu
        apt-get install -y \
        build-essential git libopenblas-dev liblapack-dev libopencv-dev \
        libcurl4-openssl-dev libgtest-dev cmake wget unzip libatlas-base-dev  python-opencv \
        && \
        cd /usr/src/gtest && \
        cmake . && \
        make && \
        cp *.a /usr/lib  \
        && \
        cd / && \
        # Download MXNet sources and build MXNet core shared library
        git clone --recursive https://github.com/apache/incubator-mxnet.git mxnet && \
        cd mxnet && \
        git checkout 1.1.0 && \
        git submodule update --recursive && \
        make -j $(nproc) USE_OPENCV=1 USE_BLAS=openblas USE_PROFILER=1 && \
        #rm -r build \
        #&& \
        # 2. -------------- Build the MXNet Python binding ------------------
        # install libraries for mxnet's python package on ubuntu
        apt-get update && \
        apt-get install -y python-dev python-setuptools python-numpy python-pip && \
        # Install the MXNet Python binding.
        cd python && \
        #pip install --upgrade pip && \
        pip install -e . && \
        apt-get purge -y build-essential git libcurl4-openssl-dev libgtest-dev cmake wget unzip libatlas-base-dev  python-opencv && \
        apt-get autoremove -y && \
        apt-get clean

ENV PYTHONPATH=/mxnet/python
CMD  ["/bin/bash"]

