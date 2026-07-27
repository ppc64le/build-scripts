###############################################################################
# Stage 1: Build Ollama (Power10 optimized)
###############################################################################
FROM registry.access.redhat.com/ubi10/ubi:10.0 AS build

ARG PACKAGE_NAME=ollama
ARG PACKAGE_VERSION=v0.30.10
ARG PACKAGE_URL=https://github.com/ollama/ollama

# Install dependencies
RUN dnf update -y && \
    dnf install -y \
    python3.12 python3.12-devel \
    gcc gcc-c++ \
    golang \
    git make cmake binutils wget patch tar gzip openssl-devel \
    && dnf clean all

###############################################################################
# Clone and Build Ollama
###############################################################################
WORKDIR /src

# Clone Ollama source and apply patches
RUN git clone ${PACKAGE_URL} && \
    cd ${PACKAGE_NAME} && \
    git checkout ${PACKAGE_VERSION}

WORKDIR /src/${PACKAGE_NAME}

RUN echo "b9692" > LLAMA_CPP_VERSION

###############################################################################
# Build Ollama (CMake)
###############################################################################
RUN cmake -B build -DCMAKE_BUILD_TYPE=Release && \
    cmake --build build -j$(nproc)

###############################################################################
# Stage 2: Small runtime image (Power10 optimized)
###############################################################################
FROM registry.access.redhat.com/ubi10/ubi:10.0

RUN dnf update -y && \
    dnf install -y libatomic openblas openblas-threads && \
    dnf clean all

COPY --from=build /src/ollama/ollama /usr/bin/ollama
COPY --from=build /src/ollama/build/lib/ollama /usr/lib/ollama

ENV LD_LIBRARY_PATH=/usr/lib/ollama:$LD_LIBRARY_PATH
ENV PATH="/usr/bin:${PATH}"
ENV OLLAMA_HOST=0.0.0.0:11434

EXPOSE 11434
ENTRYPOINT ["/usr/bin/ollama"]
CMD ["serve"]
