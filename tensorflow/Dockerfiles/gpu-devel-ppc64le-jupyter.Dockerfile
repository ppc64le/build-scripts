# Copyright 2018 The TensorFlow Authors. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ============================================================================
#
# THIS IS A GENERATED DOCKERFILE.
#
# This file was assembled from multiple pieces, whose use is documented
# throughout. Please refer to the the TensorFlow dockerfiles documentation
# for more information.

FROM nvidia/cuda-ppc64le:10.1-base-ubuntu18.04

ARG CUDA=10.1
ARG CUDNN=7.6.4.38-1
ARG CUDNN_MAJOR_VERSION=7

# Needed for string substitution
SHELL ["/bin/bash", "-c"]
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        cuda-command-line-tools-${CUDA/./-} \
        # There appears to be a regression in libcublas10=10.2.2.89-1 which
        # prevents cublas from initializing in TF. See
        # https://github.com/tensorflow/tensorflow/issues/9489#issuecomment-562394257
        libcublas10=10.2.1.243-1 \
        libcublas-dev=10.2.1.243-1 \
        cuda-nvrtc-${CUDA/./-} \
        cuda-nvrtc-dev-${CUDA/./-} \
        cuda-cudart-dev-${CUDA/./-} \
        cuda-cufft-dev-${CUDA/./-} \
        cuda-curand-dev-${CUDA/./-} \
        cuda-cusolver-dev-${CUDA/./-} \
        cuda-cusparse-dev-${CUDA/./-} \
        libcudnn7=${CUDNN}+cuda${CUDA} \
        libcudnn7-dev=${CUDNN}+cuda${CUDA} \
        libcurl3-dev \
        libfreetype6-dev \
        libhdf5-serial-dev \
        libzmq3-dev \
        pkg-config \
        rsync \
        software-properties-common \
        unzip \
        zip \
        zlib1g-dev \
        wget \
        git \
        && \
    rm -rf /var/lib/apt/lists/* && \
    find /usr/local/cuda-${CUDA}/lib64/ -type f -name 'lib*_static.a' -not -name 'libcudart_static.a' -delete && \
    rm /usr/lib/powerpc64le-linux-gnu/libcudnn_static_v7.a

# Configure the build for our CUDA configuration.
ENV CI_BUILD_PYTHON python
ENV LD_LIBRARY_PATH /usr/local/cuda/extras/CUPTI/lib64:$LD_LIBRARY_PATH
ENV TF_NEED_CUDA 1
ENV TF_NEED_TENSORRT 0
ENV TF_CUDA_COMPUTE_CAPABILITIES=3.5,5.2,6.0,6.1,7.0
ENV TF_CUDA_VERSION=${CUDA}
ENV TF_CUDNN_VERSION=${CUDNN_MAJOR_VERSION}

ARG USE_PYTHON_3_NOT_2
ARG _PY_SUFFIX=${USE_PYTHON_3_NOT_2:+3}
ARG PYTHON=python${_PY_SUFFIX}
ARG PIP=pip${_PY_SUFFIX}

# See http://bugs.python.org/issue19846
ENV LANG C.UTF-8

RUN apt-get update && apt-get install -y \
    ${PYTHON} \
    ${PYTHON}-pip

RUN ${PIP} --no-cache-dir install --upgrade \
    pip \
    setuptools

# Some TF tools expect a "python" binary
RUN ln -s $(which ${PYTHON}) /usr/local/bin/python

RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    gfortran \
    gfortran-5 \
    git \
    libopenblas-dev \
    liblapack-dev \
    openjdk-8-jdk \
    ${PYTHON}-dev \
    swig

RUN ${PIP} --no-cache-dir install \
    cython \
    pybind11 \
    numpy && \
    ${PIP} --no-cache-dir install \
    Pillow \
    future \
    h5py \
    keras_applications \
    keras_preprocessing \
    matplotlib \
    mock \
    scipy \
    sklearn \
    pandas

 # Build and install bazel
ENV BAZEL_VERSION 1.1.0 
WORKDIR /
RUN mkdir /bazel && \
    cd /bazel && \
    curl -fSsL -O https://github.com/bazelbuild/bazel/releases/download/$BAZEL_VERSION/bazel-$BAZEL_VERSION-dist.zip && \
    unzip bazel-$BAZEL_VERSION-dist.zip && \
    sed -i '/--action_env=PATH \\/a\  --host_javabase=@bazel_tools//tools/jdk:jdk \\' compile.sh && \
    bash ./compile.sh && \
    cp output/bazel /usr/local/bin/ && \
    rm -rf /bazel && \
    cd -

RUN ${PIP} install jupyter matplotlib

RUN mkdir -p /tf/tensorflow-tutorials && chmod -R a+rwx /tf/
RUN mkdir /.local && chmod a+rwx /.local
RUN apt-get update && apt-get install -y --no-install-recommends wget
WORKDIR /tf/tensorflow-tutorials
RUN wget https://raw.githubusercontent.com/tensorflow/docs/master/site/en/tutorials/keras/classification.ipynb
RUN wget https://raw.githubusercontent.com/tensorflow/models/master/samples/core/tutorials/keras/basic_text_classification.ipynb
RUN wget https://raw.githubusercontent.com/tensorflow/docs/master/site/en/tutorials/keras/overfit_and_underfit.ipynb
RUN wget https://raw.githubusercontent.com/tensorflow/docs/master/site/en/tutorials/keras/regression.ipynb
RUN wget https://raw.githubusercontent.com/tensorflow/docs/master/site/en/tutorials/keras/save_and_load.ipynb
RUN wget https://raw.githubusercontent.com/tensorflow/docs/master/site/en/tutorials/keras/text_classification.ipynb
RUN wget https://raw.githubusercontent.com/tensorflow/docs/master/site/en/tutorials/keras/text_classification_with_hub.ipynb
RUN apt-get autoremove -y && apt-get remove -y wget
WORKDIR /tf
EXPOSE 8888

RUN ${PYTHON} -m ipykernel.kernelspec

COPY bashrc /etc/bash.bashrc
RUN chmod a+rwx /etc/bash.bashrc

CMD ["bash", "-c", "source /etc/bash.bashrc && jupyter notebook --notebook-dir=/tf --ip 0.0.0.0 --no-browser --allow-root"]
