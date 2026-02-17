###############################################
# Stage 1: Build Prisma Engines (Rust)
###############################################
FROM registry.access.redhat.com/ubi9-minimal:latest AS prisma-builder
###Required Labels
LABEL name="litellm" maintainer="purva.naik1@ibm.com" 

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
RUN git clone --depth 1 --branch 5.17.0 https://github.com/prisma/prisma-engines.git . && cat <<EOF >> Cargo.toml
[patch.crates-io]
ring = { git = "https://github.com/ibm/ring.git", branch = "ppc-0.16.20" }
EOF
RUN cargo build --release

###############################################
# Stage 2: Build Python Environment with litellm[proxy]
###############################################
FROM registry.access.redhat.com/ubi9-minimal:latest AS python-builder

RUN microdnf update -y && microdnf install -y \
    gcc make libffi-devel openssl-devel python3.12-devel python3.12-pip \
    && microdnf clean all

# Set Rust environment
ENV CARGO_HOME=/usr/local/cargo \
    RUSTUP_HOME=/usr/local/rustup \
    PATH=/usr/local/cargo/bin:$PATH

RUN curl https://sh.rustup.rs -sSf | bash -s -- -y

WORKDIR /app

# Combine ENV vars and setup Virtualenv
ENV VENV_PATH=/app/venv \
    PATH="/app/venv/bin:/usr/local/cargo/bin:$PATH"

RUN python3.12 -m venv $VENV_PATH \
    && pip install --no-cache-dir --upgrade pip setuptools wheel \
    && pip install --no-cache-dir prisma "litellm[proxy]==1.81.11"

###############################################
# Stage 3: Final Minimal Runtime
###############################################
###############################################
# Stage 3: Final Minimal Runtime
###############################################
FROM registry.access.redhat.com/ubi9-minimal:latest AS runtime

RUN microdnf update -y && \
    microdnf install -y python3.12 libatomic openssl && \
    microdnf clean all

WORKDIR /app

COPY --from=python-builder /app/venv /app/venv
COPY --from=prisma-builder /app/target/release/query-engine /usr/local/bin/query-engine
COPY --from=prisma-builder /app/target/release/schema-engine /usr/local/bin/schema-engine

ENV PATH="/app/venv/bin:$PATH" \
    PRISMA_QUERY_ENGINE_BINARY=/usr/local/bin/query-engine \
    PRISMA_SCHEMA_ENGINE_BINARY=/usr/local/bin/schema-engine \
    PRISMA_CLI_QUERY_ENGINE_TYPE=binary \
    PRISMA_CLIENT_ENGINE_TYPE=binary

RUN chmod +x /usr/local/bin/query-engine /usr/local/bin/schema-engine && \
    curl -L -o schema.prisma https://raw.githubusercontent.com/BerriAI/litellm/refs/tags/v1.81.11-nightly/schema.prisma && \
    prisma generate --schema=./schema.prisma

EXPOSE 4000
ENTRYPOINT ["litellm"]
CMD ["--host", "0.0.0.0", "--port", "4000"]
