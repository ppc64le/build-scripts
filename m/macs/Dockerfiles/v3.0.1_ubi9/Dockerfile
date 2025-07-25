FROM registry.access.redhat.com/ubi9/ubi:9.3

MAINTAINER Aastha Sharma <aastha.sharma4@ibm.com>

ARG PACKAGE_VERSION=v3.0.1

# Install system dependencies including ninja-build
RUN yum install -y --allowerasing wget python3.11 python3.11-devel python3.11-pip git gcc-toolset-13 cmake make gfortran procps-ng diffutils bc zlib-devel curl tar ninja-build && \
    python3.11 -m pip install -U pip wheel

# Set environment variables for gcc-toolset and OpenBLAS
ENV PATH="/opt/rh/gcc-toolset-13/root/usr/bin:$PATH"
ENV LD_LIBRARY_PATH="/opt/OpenBLAS/lib:/opt/rh/gcc-toolset-13/root/usr/lib64"

# Build and install OpenBLAS
RUN git clone https://github.com/xianyi/OpenBLAS.git && \
    cd OpenBLAS && \
    make DYNAMIC_ARCH=1 && \
    make PREFIX=/opt/OpenBLAS install && \
    echo "/opt/OpenBLAS/lib" > /etc/ld.so.conf.d/openblas.conf && \
    ldconfig && \
    cd .. && rm -rf OpenBLAS

# Clone and build MACS3
RUN git clone https://github.com/macs3-project/MACS.git && \
    cd MACS && \
    git checkout $PACKAGE_VERSION && \
    git submodule update --init --recursive && \
    python3.11 -m pip install cython numpy==2.0.2 scipy==1.15.2 && \
    python3.11 -m pip install meson meson-python && \
    python3.11 -m pip install pybind11 pythran && \
    python3.11 -m pip install --upgrade --progress-bar off pytest && \
    python3.11 -m pip install --upgrade-strategy only-if-needed --no-build-isolation --progress-bar off .

CMD ["/bin/bash"]
