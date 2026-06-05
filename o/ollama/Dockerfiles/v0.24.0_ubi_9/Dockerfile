###############################################################################
# Stage 1: Build Ollama (Power10 optimized)
###############################################################################
FROM registry.access.redhat.com/ubi9/ubi:9.7 AS build

ARG PACKAGE_NAME=ollama
ARG PACKAGE_VERSION=v0.24.0
ARG PACKAGE_URL=https://github.com/ollama/ollama
ENV CMAKE_VERSION=3.31.5
ENV GO_VERSION=1.26.3
ENV PATH="/usr/local/go/bin:${PATH}"

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

# Install CMake (system)
RUN yum install -y cmake

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
       https://github.com/ollama/ollama/commit/93e98dcc345e34cebd18ac7a83cf08a9b646fd52.patch
    
# Apply patches
RUN patch -Np1 < ppc_sync1.patch && \
    patch -Np1 < ppc_sync2.patch && \
    patch -Np1 < build_fix_ppc.patch && \
    patch -Np1 < set_threads_env.patch
    
    
###############################################################################
# Build Ollama (CMake + Go) - Power10 Optimized
###############################################################################
# Power10 specific compiler flags for maximum optimization
# Note: Using -fno-finite-math-only to support GGML's non-finite math requirements
ENV CFLAGS="-mcpu=power10 -mtune=power10 -O3 -fno-finite-math-only -funroll-loops -ftree-vectorize"
ENV CXXFLAGS="-mcpu=power10 -mtune=power10 -O3 -fno-finite-math-only -funroll-loops -ftree-vectorize"

RUN cmake -B build \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_C_FLAGS="${CFLAGS}" \
    -DCMAKE_CXX_FLAGS="${CXXFLAGS}" \
    -DGGML_NATIVE=ON \
    -DGGML_CPU_POWER10=ON && \
    cmake --build build -j$(nproc)

# Link GGML Power10 libs with optimized flags
ENV CGO_LDFLAGS="-L/src/ollama/build/lib/ollama -lggml-cpu-power10"
ENV CGO_CFLAGS="-mcpu=power10 -mtune=power10 -O3"
ENV CGO_CXXFLAGS="-mcpu=power10 -mtune=power10 -O3"

RUN go build --tags ppc64le.power10 -ldflags="-s -w" -o /src/ollama/ollama .

###############################################################################
# Stage 2: Small runtime image (Power10 optimized)
###############################################################################
FROM registry.access.redhat.com/ubi9/ubi:9.7

RUN yum update -y && \
    yum install -y libatomic openblas-devel openblas-threads && \
    yum clean all

COPY --from=build /src/ollama/ollama /usr/bin/ollama
COPY --from=build /src/ollama/build/lib/ollama /usr/lib/ollama

ENV LD_LIBRARY_PATH=/usr/lib/ollama:$LD_LIBRARY_PATH
ENV PATH="/usr/bin:${PATH}"
ENV OLLAMA_HOST=0.0.0.0:11434

EXPOSE 11434
ENTRYPOINT ["/usr/bin/ollama"]
CMD ["serve"]