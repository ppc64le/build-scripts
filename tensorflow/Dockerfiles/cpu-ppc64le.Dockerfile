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
FROM ubuntu:18.04

RUN apt-get update && apt-get install -y curl

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

RUN apt-get update && apt-get install -y wget libhdf5-dev pkg-config liblapack-dev gfortran

# These get installed from the tensorflow .whl, but are installed earlier to cache the installs
RUN ${PIP} --no-cache-dir install --upgrade \
            astor \
            absl-py \
            gast \
            termcolor \
            protobuf \
            keras-applications \
            grpcio \
            keras-preprocessing \
            mock \
            werkzeug \
            markdown \
            pbr \
            h5py \
            pybind11

# CACHE_STOP is used to rerun future commands, otherwise downloading the .whl will be cached and will not pull the most recent version
ARG CACHE_STOP=1
ARG BASE_URL=https://powerci.osuosl.org/job/TensorFlow_PPC64LE_CPU_Nightly_Artifact/lastSuccessfulBuild/
RUN MAJOR=`${PYTHON} -c 'import sys; print(sys.version_info[0])'`; \
    MINOR=`${PYTHON} -c 'import sys; print(sys.version_info[1])'`; \
    PACKAGE=$(wget --no-verbose -qO- ${BASE_URL}"api/xml?xpath=//fileName&wrapper=artifacts" | grep -o "[^<>]*cp${MAJOR}${MINOR}[^<>]*.whl"); \
    wget --no-verbose ${BASE_URL}"artifact/tensorflow_pkg/"${PACKAGE}; \
    ${PIP} install ${PACKAGE}

COPY bashrc /etc/bash.bashrc
RUN chmod a+rwx /etc/bash.bashrc
