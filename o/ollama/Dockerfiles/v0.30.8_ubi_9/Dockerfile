###############################################################################
# Stage 1: Build Ollama (Power10 optimized)
###############################################################################
FROM registry.access.redhat.com/ubi9/ubi:9.7 AS build

ARG PACKAGE_NAME=ollama
ARG PACKAGE_VERSION=v0.30.8
ARG PACKAGE_URL=https://github.com/ollama/ollama
ENV CMAKE_VERSION=3.31.5


# Install dependencies
RUN yum update -y && \
    yum install -y \
    python3.12 python3.12-devel \
    gcc-toolset-15 gcc-toolset-15-binutils gcc-toolset-15-gcc-c++ \
    git make cmake binutils wget patch tar gzip openssl-devel \
    && yum clean all

# Enable GCC toolset 15
ENV PATH="/opt/rh/gcc-toolset-15/root/usr/bin:${PATH}"
ENV LD_LIBRARY_PATH="/opt/rh/gcc-toolset-15/root/usr/lib64:${LD_LIBRARY_PATH}"
ENV CC=/opt/rh/gcc-toolset-15/root/usr/bin/gcc
ENV CXX=/opt/rh/gcc-toolset-15/root/usr/bin/g++

###############################################################################
# Clone and Build Ollama
###############################################################################
WORKDIR /src

# Clone Ollama source and apply patches    
RUN git clone ${PACKAGE_URL} && \
    cd ${PACKAGE_NAME} && \
    git checkout ${PACKAGE_VERSION} 

WORKDIR /src/${PACKAGE_NAME}
    
###############################################################################
# Build Ollama (CMake)
###############################################################################
RUN cmake -B build -DCMAKE_BUILD_TYPE=Release && \
    cmake --build build -j$(nproc)

###############################################################################
# Stage 2: Small runtime image (Power10 optimized)
###############################################################################
FROM registry.access.redhat.com/ubi9/ubi:9.7

RUN yum update -y && \
    yum install -y libatomic openblas openblas-threads && \
    yum clean all

COPY --from=build /src/ollama/ollama /usr/bin/ollama
COPY --from=build /src/ollama/build/lib/ollama /usr/lib/ollama

ENV LD_LIBRARY_PATH=/usr/lib/ollama:$LD_LIBRARY_PATH
ENV PATH="/usr/bin:${PATH}"
ENV OLLAMA_HOST=0.0.0.0:11434

EXPOSE 11434
ENTRYPOINT ["/usr/bin/ollama"]
CMD ["serve"]
