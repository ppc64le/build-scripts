FROM registry.access.redhat.com/ubi9/ubi:9.3

LABEL maintainer="Ramnath Nayak <Ramnath.Nayak@ibm.com>"

ARG PACKAGE_VERSION=release-3.1.8

ENV GCC_TOOLSET_PATH=/opt/rh/gcc-toolset-13/root/usr
ENV PATH="${GCC_TOOLSET_PATH}/bin:$PATH"

RUN yum install -y git make cmake zip tar wget python3 python3-devel python3-pip gcc-toolset-13 gcc-toolset-13-gcc-c++ gcc-toolset-13-gcc zlib-devel libjpeg-devel openssl openssl-devel freetype-devel pkgconfig  && \ 
    git clone https://github.com/mcfletch/pyopengl && \
    cd pyopengl && \
    git checkout $PACKAGE_VERSION && \
    pip install --upgrade pip && \
    pip install . && \
    cd accelerate && \
    wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/p/pyopengl-accelerate/pyopengl-accelerate_release-3.1.8_1.patch && \
    git apply pyopengl-accelerate_release-3.1.8_1.patch && \
    pip install .
	
CMD ["/bin/bash"]
