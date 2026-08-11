###############################################################################
# Stage 1: Base — system packages + Go toolchain
###############################################################################
FROM registry.access.redhat.com/ubi10/ubi:10.0 AS base

ARG PACKAGE_NAME=ollama
ARG PACKAGE_VERSION=v0.32.7
ARG PACKAGE_URL=https://github.com/ollama/ollama

# Install system dependencies with GCC toolset 15
RUN dnf update -y && \
    dnf install -y \
        python3 python3-devel \
        gcc-toolset-15 gcc-toolset-15-gcc-c++ gcc-toolset-15-gcc-gfortran gcc-toolset-15-binutils \
        git make cmake wget patch tar gzip openssl-devel perl \
    && dnf clean all

ENV PATH="/opt/rh/gcc-toolset-15/root/usr/bin:${PATH}"
ENV LD_LIBRARY_PATH="/opt/rh/gcc-toolset-15/root/usr/lib64"
ENV PATH="/usr/local/go/bin:${PATH}"

###############################################################################
# Clone Ollama and install Go based on go.mod version
###############################################################################
WORKDIR /src
RUN git clone ${PACKAGE_URL}.git && \
    cd ${PACKAGE_NAME} && \
    git checkout ${PACKAGE_VERSION} && \
    git submodule update --init --recursive

WORKDIR /src/${PACKAGE_NAME}
RUN GO_VERSION=$(awk '/^go/ { print $2 }' go.mod) && \
    wget -q https://go.dev/dl/go${GO_VERSION}.linux-ppc64le.tar.gz && \
    tar -C /usr/local -xzf go${GO_VERSION}.linux-ppc64le.tar.gz && \
    rm go${GO_VERSION}.linux-ppc64le.tar.gz

RUN go mod download

###############################################################################
# Stage 2: OpenBLAS — built from source with POWER10 optimizations
###############################################################################
FROM base AS openblas

ARG OPENBLAS_VERSION=v0.3.34
ARG OPENBLAS_URL=https://github.com/OpenMathLib/OpenBLAS.git

RUN git clone --depth 1 --branch ${OPENBLAS_VERSION} ${OPENBLAS_URL} /tmp/openblas && \
    cd /tmp/openblas && \
    make -j$(nproc) \
        TARGET=POWER10 \
        DYNAMIC_ARCH=0 \
        USE_OPENMP=1 \
        NUM_THREADS=64 \
        FC=/opt/rh/gcc-toolset-15/root/usr/bin/gfortran \
        CC=/opt/rh/gcc-toolset-15/root/usr/bin/gcc \
        COMMON_OPT="-O3 -mcpu=power10 -mtune=power10" \
        FCOMMON_OPT="-O3 -mcpu=power10 -mtune=power10" \
        EXTRALIB="-fopenmp" && \
    make PREFIX=/usr/local install

###############################################################################
# Stage 3: Build — compile llama-server and ollama binary
###############################################################################
FROM base AS build

ARG PACKAGE_NAME=ollama
ARG PACKAGE_VERSION=v0.32.7

# Copy OpenBLAS artifacts
COPY --from=openblas /usr/local/include/ /usr/local/include/
COPY --from=openblas /usr/local/lib/ /usr/local/lib/
RUN ldconfig

WORKDIR /src/${PACKAGE_NAME}

# Set up environment for POWER10-optimized build
ENV CGO_CFLAGS="-O3 -mcpu=power10 -mtune=power10 -maltivec -mvsx"
ENV CGO_CXXFLAGS="-O3 -mcpu=power10 -mtune=power10 -maltivec -mvsx"
ENV CGO_LDFLAGS="-L/usr/local/lib -lopenblas -lgfortran -lgomp -lm"
ENV PKG_CONFIG_PATH="/usr/local/lib/pkgconfig"
ENV LD_LIBRARY_PATH="/opt/rh/gcc-toolset-15/root/usr/lib64:/usr/local/lib"

###############################################################################
# Build llama-server with POWER10 optimizations and OpenBLAS
###############################################################################
RUN cmake -S llama/server -B build/llama-server \
        -DCMAKE_C_COMPILER=/opt/rh/gcc-toolset-15/root/usr/bin/gcc \
        -DCMAKE_CXX_COMPILER=/opt/rh/gcc-toolset-15/root/usr/bin/g++ \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_C_FLAGS="-O3 -mcpu=power10 -mtune=power10 -maltivec -mvsx" \
        -DCMAKE_CXX_FLAGS="-O3 -mcpu=power10 -mtune=power10 -maltivec -mvsx" \
        -DCMAKE_EXE_LINKER_FLAGS="-lgfortran -lgomp" \
        -DGGML_BLAS=ON \
        -DGGML_BLAS_VENDOR=OpenBLAS \
        -DGGML_OPENMP=ON \
        -DBLAS_LIBRARIES="/usr/local/lib/libopenblas.so;-lgfortran;-lgomp" \
        -DBLAS_INCLUDE_DIRS=/usr/local/include \
        -DGGML_NATIVE=OFF \
        -DGGML_CPU_ALL_VARIANTS=OFF \
        -DBUILD_SHARED_LIBS=OFF && \
    cmake --build build/llama-server --config Release --target llama-server -j$(nproc) && \
    mkdir -p /tmp/ollama-install/lib/ollama && \
    cp build/llama-server/bin/llama-server /tmp/ollama-install/lib/ollama/llama-server && \
    chmod +x /tmp/ollama-install/lib/ollama/llama-server

###############################################################################
# Build Ollama binary
###############################################################################
RUN go generate ./... && \
    go build -o bin/ollama \
         -ldflags="-s -w -X github.com/ollama/ollama/version.Version=${PACKAGE_VERSION}" \
        -trimpath \
        .

###############################################################################
# Stage 4: Runtime — minimal image with only runtime dependencies
###############################################################################
FROM registry.access.redhat.com/ubi10/ubi:10.0

# Install runtime libraries including GCC toolset 15
# Installing the full gcc-toolset-15 package to ensure all libraries are available
RUN dnf update -y && \
    dnf install -y libatomic gcc-toolset-15 && \
    dnf clean all

# Copy OpenBLAS shared libraries (all variants)
COPY --from=openblas /usr/local/lib/libopenblas* /usr/local/lib/

# Register library paths
RUN echo "/usr/local/lib" > /etc/ld.so.conf.d/libs.conf && \
    echo "/opt/rh/gcc-toolset-15/root/usr/lib64" >> /etc/ld.so.conf.d/libs.conf && \
    echo "/opt/rh/gcc-toolset-15/root/usr/lib/gcc/ppc64le-redhat-linux/15" >> /etc/ld.so.conf.d/libs.conf && \
    ldconfig

# Copy binaries from build stage
COPY --from=build /src/ollama/bin/ollama /usr/local/bin/ollama
COPY --from=build /tmp/ollama-install/lib/ollama /usr/local/lib/ollama

# Create model directory
RUN mkdir -p /root/.ollama

EXPOSE 11434

ENV OLLAMA_HOST=0.0.0.0
ENV LD_LIBRARY_PATH=/opt/rh/gcc-toolset-15/root/usr/lib/gcc/ppc64le-redhat-linux/15:/opt/rh/gcc-toolset-15/root/usr/lib64:/usr/local/lib
ENV OLLAMA_MODELS=/root/.ollama/models

ENTRYPOINT ["/usr/local/bin/ollama"]
CMD ["serve"]
