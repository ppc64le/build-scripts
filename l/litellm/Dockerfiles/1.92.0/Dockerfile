###############################################
# Stage 1: Build Prisma Engines (Rust)
###############################################
FROM registry.access.redhat.com/ubi9-minimal:latest AS prisma-builder
###Required Labels
LABEL name="litellm" maintainer="prachi.gaonkar@ibm.com"

# Install build dependencies
RUN microdnf update -y && \
    microdnf install -y \
    pkgconf-pkg-config unzip \
    openssl-devel clang git && microdnf clean all \
    && curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y \
    && curl -LO https://github.com/protocolbuffers/protobuf/releases/download/v25.1/protoc-25.1-linux-ppcle_64.zip && \
    unzip protoc-25.1-linux-ppcle_64.zip -d /usr/local && \
    chmod +x /usr/local/bin/protoc && \
    rm protoc-25.1-linux-ppcle_64.zip

ENV PATH="/root/.cargo/bin:${PATH}" CC=clang

WORKDIR /app

# Clone Prisma Engines and checkout tag
RUN git clone --depth 1 --branch 5.17.0 https://github.com/prisma/prisma-engines.git . && \
    printf '\n[patch.crates-io]\nring = { git = "https://github.com/ibm/ring.git", branch = "ppc-0.16.20" }\n' >> Cargo.toml
RUN cargo build --release

###############################################
# Stage 2: Build Python Environment with litellm[proxy]
###############################################
FROM registry.access.redhat.com/ubi9-minimal:latest AS python-builder

ARG VERSION=1.92.0

RUN microdnf update -y && microdnf install -y \
    gcc make wget tar patch \
    libffi-devel openssl-devel zlib-devel \
    python3.12-devel python3.12-pip \
    && microdnf clean all

# Set Rust environment
ENV CARGO_HOME=/usr/local/cargo \
    RUSTUP_HOME=/usr/local/rustup \
    PATH=/usr/local/cargo/bin:$PATH \
    RUSTC_BOOTSTRAP=1 \
    GRPC_PYTHON_BUILD_SYSTEM_OPENSSL=1 \
    GRPC_PYTHON_BUILD_SYSTEM_ZLIB=1

RUN curl https://sh.rustup.rs -sSf | bash -s -- -y

WORKDIR /build

# Copy patch into build context
COPY pyproject-toml.patch ./

# Install uv
RUN pip3.12 install --no-cache-dir uv

# Download litellm source, apply patch, lock and export requirements
RUN wget -q https://github.com/BerriAI/litellm/archive/refs/tags/v${VERSION}.tar.gz && \
    tar -xzf v${VERSION}.tar.gz && \
    cd litellm-${VERSION} && \
    patch -p1 pyproject.toml < ../pyproject-toml.patch && \
    uv lock && \
    uv export --no-hashes --no-dev \
        --extra proxy \
        -o ../requirements.txt && \
    sed -i '/^-e \./d' ../requirements.txt

# Build wheels for workspace members that uv export emits as local paths
RUN cd litellm-${VERSION} && \
    uv build --wheel --package litellm-proxy-extras --out-dir /wheels && \
    uv build --wheel --package litellm --out-dir /wheels

# Compile all remaining dependencies into wheel files
RUN python3.12 -m pip wheel -r requirements.txt prisma \
        -w /wheels \
        --extra-index-url=https://wheels.developerfirst.ibm.com/ppc64le/linux/ \
        --prefer-binary

###############################################
# Stage 3: Final Minimal Runtime
###############################################
FROM registry.access.redhat.com/ubi9-minimal:latest AS runtime

RUN microdnf update -y && \
    microdnf install -y python3.12 python3.12-pip libatomic openssl && \
    microdnf clean all

WORKDIR /app

# Copy pre-built wheels from python-builder and install
COPY --from=python-builder /wheels /wheels

# Install litellm deps from pre-built wheels
RUN python3.12 -m pip install --no-cache-dir --no-index \
        --find-links=/wheels \
        "litellm[proxy]==1.92.0" prisma && \
    python3.12 -m pip cache purge && \
    rm -rf /wheels && \
    microdnf remove -y python3.12-pip && \
    microdnf clean all

# Copy Prisma engine binaries built in Stage 1
COPY --from=prisma-builder /app/target/release/query-engine /usr/local/bin/query-engine
COPY --from=prisma-builder /app/target/release/schema-engine /usr/local/bin/schema-engine

ENV PRISMA_QUERY_ENGINE_BINARY=/usr/local/bin/query-engine \
    PRISMA_SCHEMA_ENGINE_BINARY=/usr/local/bin/schema-engine \
    PRISMA_CLI_QUERY_ENGINE_TYPE=binary \
    PRISMA_CLIENT_ENGINE_TYPE=binary

RUN chmod +x /usr/local/bin/query-engine /usr/local/bin/schema-engine && \
    curl -L -o schema.prisma https://raw.githubusercontent.com/BerriAI/litellm/refs/tags/v1.92.0/schema.prisma && \
    prisma generate --schema=./schema.prisma && rm -rf /root/.cache/prisma-python

EXPOSE 4000
ENTRYPOINT ["litellm"]
CMD ["--host", "0.0.0.0", "--port", "4000"]

