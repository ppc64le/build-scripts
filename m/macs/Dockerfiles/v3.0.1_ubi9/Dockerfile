FROM registry.access.redhat.com/ubi9/ubi:9.3

MAINTAINER Aastha Sharma <aastha.sharma4@ibm.com>

ARG PACKAGE_VERSION=v3.0.1

RUN yum install -y wget python3 python3-devel python3-pip git gcc-toolset-13 openblas cmake procps-ng diffutils bc zlib-devel && \
    python3 -m pip install -U pip 

ENV PATH="/opt/rh/gcc-toolset-13/root/usr/bin:$PATH" \
    LD_LIBRARY_PATH="/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH"

RUN git clone https://github.com/macs3-project/MACS.git && \
    cd MACS && \
    git checkout $PACKAGE_VERSION && \
    git submodule update --init --recursive && \
    python3 -m pip install openblas cython numpy scipy && \
    python3 -m pip install meson-python && \
    python3 -m pip install pybind11 && \
    python3 -m pip install pythran && \
    python3 -m pip install --upgrade --progress-bar off pytest && \
    python3 -m pip install --upgrade-strategy only-if-needed --no-build-isolation --progress-bar off . 

CMD ["/bin/bash"]
