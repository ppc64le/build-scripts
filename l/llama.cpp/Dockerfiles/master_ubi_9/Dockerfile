###############################################################################
# Stage 1: Build llama.cpp
###############################################################################
FROM registry.access.redhat.com/ubi9/ubi:9.7 AS build

ARG PACKAGE_NAME=llama.cpp
ARG BRANCH=master
ARG PACKAGE_URL=https://github.com/ggml-org/llama.cpp
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

# Install CMake (system)
RUN yum install -y cmake


###############################################################################
# Clone and Build llama.cpp
###############################################################################
WORKDIR /src

RUN git clone ${PACKAGE_URL} && \
    cd ${PACKAGE_NAME} && \
    git fetch --tags && \
    git checkout ${PACKAGE_VERSION} && \
    echo "Building release ${PACKAGE_VERSION}"

WORKDIR /src/${PACKAGE_NAME}

###############################################################################
# Build llama.cpp (CMake)
###############################################################################
RUN cmake -B build -DCMAKE_BUILD_TYPE=Release && \
    cmake --build build -j$(nproc)

###############################################################################
# Stage 2: Small runtime image
###############################################################################
FROM registry.access.redhat.com/ubi9/ubi:9.7

RUN yum update -y && \
    yum install -y libatomic openblas openblas-threads && \
    yum clean all

COPY --from=build /src/llama.cpp/build/bin/llama-cli /usr/bin/llama-cli
COPY --from=build /src/llama.cpp/build/bin/llama-server /usr/bin/llama-server
COPY --from=build /src/llama.cpp/build/bin/llama-bench /usr/bin/llama-bench
COPY --from=build /src/llama.cpp/build/bin/llama-batched-bench /usr/bin/llama-batched-bench

COPY --from=build /src/llama.cpp/build/bin/libllama-bench-impl.so /usr/lib/llama
COPY --from=build /src/llama.cpp/build/bin/libllama-common.so.0 /usr/lib/llama
COPY --from=build /src/llama.cpp/build/bin/libllama.so.0 /usr/lib/llama
COPY --from=build /src/llama.cpp/build/bin/libggml.so.0 /usr/lib/llama
COPY --from=build /src/llama.cpp/build/bin/libggml-base.so.0 /usr/lib/llama
COPY --from=build /src/llama.cpp/build/bin/libggml-cpu.so.0 /usr/lib/llama


ENV LD_LIBRARY_PATH=/usr/lib/llama:$LD_LIBRARY_PATH
ENV PATH="/usr/bin:${PATH}"

EXPOSE 8080
ENTRYPOINT ["/usr/bin/llama-server"]
CMD ["--help"]
