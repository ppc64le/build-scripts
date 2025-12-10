###############################################
# Stage 1: Build Prisma Engines (Rust)
###############################################
FROM rust:1.91-slim AS prisma-builder

###Required Labels
LABEL name="litellm" maintainer="purva.naik1@ibm.com" 

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    pkg-config protobuf-compiler \
    libssl-dev \
    clang \
    git && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Clone Prisma Engines and checkout tag
RUN git clone --depth 1 --branch 5.17.0 https://github.com/prisma/prisma-engines.git .
RUN echo '\
[patch.crates-io]\n\
ring = { git = "https://github.com/ibm/ring.git", branch = "ppc-0.16.20" }\n\
' >> Cargo.toml

# Build Prisma engines
ENV CC=clang
RUN cargo build --release
###############################################
# Stage 2: Build Python Environment with litellm[proxy]
###############################################
FROM python:3.12-slim AS python-builder

# Install minimal build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl gcc make libffi-dev libssl-dev python3-dev \
 && rm -rf /var/lib/apt/lists/*

ENV CARGO_HOME=/usr/local/cargo \
    RUSTUP_HOME=/usr/local/rustup \
    PATH=/usr/local/cargo/bin:$PATH

RUN curl https://sh.rustup.rs -sSf | bash -s -- -y

WORKDIR /app

# Create virtualenv and install all dependencies (single layer)
ENV VENV_PATH=/app/venv
ENV PATH="$VENV_PATH/bin:$PATH"
RUN python -m venv $VENV_PATH \
 && $VENV_PATH/bin/pip install --no-cache-dir --upgrade pip setuptools wheel \
 && $VENV_PATH/bin/pip install --no-cache-dir prisma "litellm[proxy]==1.79.3"

###############################################
# Stage 3: Final Minimal Runtime
###############################################
FROM python:3.12-slim AS runtime
RUN apt-get update && apt-get install -y --no-install-recommends \
    libatomic1 curl && rm -rf /var/lib/apt/lists/*
WORKDIR /app

# Copy Python virtualenv from builder
COPY --from=python-builder /app/venv /app/venv
ENV PATH="/app/venv/bin:$PATH"

# Copy Prisma engines from Rust builder
RUN mkdir -p /usr/local/lib/prisma
COPY --from=prisma-builder /app/target/release/*-engine /usr/local/lib/prisma/
RUN chmod +x /usr/local/lib/prisma/query-engine

# Set Prisma environment variables
ENV PRISMA_QUERY_ENGINE_BINARY=/usr/local/lib/prisma/query-engine
ENV PRISMA_CLI_QUERY_ENGINE_TYPE=binary

# Get Prisma schema and generate client
RUN curl -L -o schema.prisma https://raw.githubusercontent.com/BerriAI/litellm/refs/tags/v1.79.3.rc.1/schema.prisma
RUN prisma generate
ENV PRISMA_SCHEMA_ENGINE_BINARY=/usr/local/lib/prisma/schema-engine

# Expose port and run
EXPOSE 4000
ENTRYPOINT ["litellm"]
CMD ["--host", "0.0.0.0", "--port", "4000"]