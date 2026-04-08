###############################################################################
# Stage 1: Build Ollama (Power10 optimized)
###############################################################################
FROM registry.access.redhat.com/ubi9/ubi:9.6 AS build

ARG PACKAGE_NAME=ollama
ARG PACKAGE_VERSION=v0.20.4
ARG PACKAGE_URL=https://github.com/ollama/ollama
ENV CMAKE_VERSION=3.30.5
ENV GO_VERSION=1.26.1
ENV PATH="/usr/local/go/bin:/usr/local/cmake/bin:${PATH}"

# Install dependencies
RUN yum update -y && \
    yum install -y \
    python3 python3-pip python3-devel \
    gcc-toolset-13 gcc-toolset-13-binutils gcc-toolset-13-gcc-c++ \
    git make cmake binutils wget patch tar gzip openssl-devel \
    && yum clean all

# Enable GCC toolset 13
ENV PATH="/opt/rh/gcc-toolset-13/root/usr/bin:${PATH}"
ENV LD_LIBRARY_PATH="/opt/rh/gcc-toolset-13/root/usr/lib64:${LD_LIBRARY_PATH}"
ENV CC=/opt/rh/gcc-toolset-13/root/usr/bin/gcc
ENV CXX=/opt/rh/gcc-toolset-13/root/usr/bin/g++

# Install CMake
WORKDIR /tmp
RUN wget https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}.tar.gz && \
    tar -xzf cmake-${CMAKE_VERSION}.tar.gz && \
    cd cmake-${CMAKE_VERSION} && \
    ./bootstrap --prefix=/usr/local/cmake --parallel=2 -- \
        -DBUILD_TESTING:BOOL=OFF \
        -DCMAKE_BUILD_TYPE:STRING=Release \
        -DCMAKE_USE_OPENSSL:BOOL=ON && \
    make -j$(nproc) && \
    make install && \
    cmake --version

# Install Go
RUN wget https://go.dev/dl/go${GO_VERSION}.linux-ppc64le.tar.gz && \
    rm -rf /usr/local/go && \
    tar -C /usr/local -xzf go${GO_VERSION}.linux-ppc64le.tar.gz && \
    rm -rf go${GO_VERSION}.linux-ppc64le.tar.gz && \
    go version

###############################################################################
# Clone and patch Ollama
###############################################################################
WORKDIR /src

# Clone Ollama source and apply patches    
RUN git clone ${PACKAGE_URL} && \
    cd ${PACKAGE_NAME} && \
    git checkout ${PACKAGE_VERSION} 

WORKDIR /src/${PACKAGE_NAME}
# Download patches
RUN wget -q -O ppc_sync1.patch \
      https://github.com/ollama/ollama/commit/035aee3b98e666b42fbab724aa9aaa176360844f.patch && \
    wget -q -O ppc_sync2.patch \
       https://github.com/ollama/ollama/commit/b765e03d192fe99e96a8008daeb76a0a843e997d.patch && \
    wget -q -O build_fix_ppc.patch \
       https://github.com/ollama/ollama/commit/4115e4f58f8c3fb86cdce2d58aae811c2d26cc52.patch && \
    wget -q -O set_threads_env.patch \
      https://github.com/ollama/ollama/commit/changes/a86b8152e0f37c0c117ba7acd2a940e3ba5f07d9.patch
    
# Apply patches
RUN patch -Np1 < ppc_sync1.patch && \
    patch -Np1 < ppc_sync2.patch && \
    patch -Np1 < ppc_build_fix.patch && \
    patch -Np1 < set_threads_env.patch
    
###############################################################################
# Build Ollama (CMake + Go)
###############################################################################
RUN cmake -B build -DCMAKE_BUILD_TYPE=Release && \
    cmake --build build -j$(nproc)

# Link GGML Power10 libs
ENV CGO_LDFLAGS="-L/src/ollama/build/lib/ollama -lggml-cpu-power10"

RUN go build --tags ppc64le.power10 -o /src/ollama/ollama .

###############################################################################
# Stage 2: Small runtime image
###############################################################################
FROM registry.access.redhat.com/ubi9/ubi:9.6

RUN yum update -y && \
    yum install -y libatomic openblas-devel && \
    yum clean all

COPY --from=build /src/ollama/ollama /usr/bin/ollama
COPY --from=build /src/ollama/build/lib/ollama /usr/lib/ollama

ENV LD_LIBRARY_PATH=/usr/lib/ollama:$LD_LIBRARY_PATH
ENV PATH="/usr/bin:${PATH}"
ENV OLLAMA_HOST=0.0.0.0:11434

EXPOSE 11434
ENTRYPOINT ["/usr/bin/ollama"]
CMD ["serve"]
