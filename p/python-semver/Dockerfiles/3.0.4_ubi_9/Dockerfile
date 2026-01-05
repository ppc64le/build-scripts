FROM registry.access.redhat.com/ubi9/ubi:9.3

LABEL maintainer="Ramnath Nayak <Ramnath.Nayak@ibm.com>"

ARG PACKAGE_VERSION=3.0.4

ENV GCC_TOOLSET_PATH=/opt/rh/gcc-toolset-13/root/usr
ENV PATH="${GCC_TOOLSET_PATH}/bin:$PATH"

RUN yum install -y git make cmake zip tar wget python3 python3-devel python3-pip gcc-toolset-13 gcc-toolset-13-gcc-c++ gcc-toolset-13-gcc zlib-devel libjpeg-devel  && \ 
    git clone https://github.com/python-semver/python-semver && \
    cd python-semver && \
    git checkout $PACKAGE_VERSION && \
	pip install --upgrade pip tox build && \
	pip install -r docs/requirements.txt && \
	pip install .
	
CMD ["/bin/bash"]
