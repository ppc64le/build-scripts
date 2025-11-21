###############################################################################
# Stage 1: Build Ollama (Power10 optimized)
###############################################################################
FROM registry.access.redhat.com/ubi9/ubi:9.6 AS build

ARG PACKAGE_NAME=ollama
ARG PACKAGE_VERSION=v0.12.10
ARG PACKAGE_URL=https://github.com/ollama/ollama

ENV CMAKE_VERSION=3.30.5
ENV GO_VERSION=1.22.6
ENV PATH="/usr/local/go/bin:/usr/local/cmake/bin:${PATH}"

# Install dependencies
RUN yum install -y \
    python3 python3-pip python3-devel \
    gcc-toolset-13 gcc-toolset-13-binutils gcc-toolset-13-gcc-c++ \
    git make cmake binutils wget patch tar gzip \
    && yum clean all

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
    go version

###############################################################################
# Clone and patch Ollama
###############################################################################
WORKDIR /src

RUN git clone ${PACKAGE_URL} && \
    cd ${PACKAGE_NAME} && \
    git checkout ${PACKAGE_VERSION}

WORKDIR /src/${PACKAGE_NAME}

# Download patches
RUN wget -q -O build_power.patch \
      https://github.com/ollama/ollama/commit/67b8d3c817fbdc57fedad9b032d0efc10285220a.patch && \
    wget -q -O set_threads_env.patch \
      https://github.com/ollama/ollama/commit/1364a887a1d7c25522e9c921d55e50a6aea44964.patch && \
    wget -q -O enable_mma.patch \
      https://github.com/ollama/ollama/commit/fe924304809ae8e6bd6957b0ce5759eb2a796d42.patch

# Apply patches
RUN patch -Np1 < build_power.patch && \
    patch -Np1 < set_threads_env.patch && \
    patch -Np1 < enable_mma.patch

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

RUN yum install -y libatomic openblas-devel && yum clean all

WORKDIR /opt/ollama

COPY --from=build /src/ollama/ollama /opt/ollama/
COPY --from=build /src/ollama/build/lib/ollama /opt/ollama/lib

ENV LD_LIBRARY_PATH=/opt/ollama/lib:$LD_LIBRARY_PATH
ENV OLLAMA_HOST=0.0.0.0:11434

EXPOSE 11434

CMD ["/opt/ollama/ollama", "serve"]


